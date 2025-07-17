#!/bin/bash
set -e

export VELODB_ENDPOINT=${VELODB_ENDPOINT:-"http://localhost:8030"}
export VELODB_USER=${VELODB_USER:-"root"}
export VELODB_PASSWORD=${VELODB_PASSWORD:-""}
export VELODB_PORT=${VELODB_USER:-"9030"}

# Load data
echo "start loading, estimated to take about 9 minutes ..."
date
START=$(date +%s)

mysql -vvv -h${VELODB_ENDPOINT} -P${VELODB_PORT} -u${VELODB_USER} hits -e "
    INSERT INTO hits SELECT CounterID, select from_days(719528 + EventDate), UserID, from_unixtime(EventTime), WatchID, JavaEnable, Title, GoodEvent, ClientIP, RegionID, CounterClass,
                            OS, UserAgent, URL, Referer, IsRefresh, RefererCategoryID, RefererRegionID, URLCategoryID, URLRegionID,
                            ResolutionWidth, ResolutionHeight, ResolutionDepth, FlashMajor, FlashMinor, FlashMinor2, NetMajor, NetMinor,
                            UserAgentMajor, UserAgentMinor, CookieEnable, JavascriptEnable, IsMobile, MobilePhone, MobilePhoneModel,
                            Params, IPNetworkID, TraficSourceID, SearchEngineID, SearchPhrase, AdvEngineID, IsArtifical, WindowClientWidth,
                            WindowClientHeight, ClientTimeZone, ClientEventTime, SilverlightVersion1, SilverlightVersion2, SilverlightVersion3,
                            SilverlightVersion4, PageCharset, CodeVersion, IsLink, IsDownload, IsNotBounce, FUniqID, OriginalURL, HID,
                            IsOldCounter, IsEvent, IsParameter, DontCountHits, WithHash, HitColor, from_unixtime(LocalEventTime), Age, Sex, Income, Interests,
                            Robotness, RemoteIP, WindowName, OpenerName, HistoryLength, BrowserLanguage, BrowserCountry, SocialNetwork, SocialAction,
                            HTTPError, SendTiming, DNSTiming, ConnectTiming, ResponseStartTiming, ResponseEndTiming, FetchTiming, SocialSourceNetworkID,
                            SocialSourcePage, ParamPrice, ParamOrderID, ParamCurrency, ParamCurrencyID, OpenstatServiceName, OpenstatCampaignID,
                            OpenstatAdID, OpenstatSourceID, UTMSource, UTMMedium, UTMCampaign, UTMContent, UTMTerm, FromTag, HasGCLID, RefererHash, URLHash,
                            CLID
    FROM s3('uri' = 's3://doris-regression/regression/hits_compatible/athena_partitioned/hits_*.parquet',
            's3.access_key'= 'AKIASPAWQE3IWHSQ5XFU',
            's3.secret_key' = 'sk',
            's3.endpoint' = 's3.us-east-1.amazonaws.com',
            's3.region' = 'us-east-1',
            'format' = 'parquet');
"

for index in `seq 0 25`; do
    mysql -vvv -h${VELODB_ENDPOINT} -P${VELODB_PORT} -u${VELODB_USER} hits -e "
        INSERT INTO hits SELECT CounterID, select from_days(719528 + EventDate), UserID, from_unixtime(EventTime), WatchID, JavaEnable, Title, GoodEvent, ClientIP, RegionID, CounterClass,
                                OS, UserAgent, URL, Referer, IsRefresh, RefererCategoryID, RefererRegionID, URLCategoryID, URLRegionID,
                                ResolutionWidth, ResolutionHeight, ResolutionDepth, FlashMajor, FlashMinor, FlashMinor2, NetMajor, NetMinor,
                                UserAgentMajor, UserAgentMinor, CookieEnable, JavascriptEnable, IsMobile, MobilePhone, MobilePhoneModel,
                                Params, IPNetworkID, TraficSourceID, SearchEngineID, SearchPhrase, AdvEngineID, IsArtifical, WindowClientWidth,
                                WindowClientHeight, ClientTimeZone, ClientEventTime, SilverlightVersion1, SilverlightVersion2, SilverlightVersion3,
                                SilverlightVersion4, PageCharset, CodeVersion, IsLink, IsDownload, IsNotBounce, FUniqID, OriginalURL, HID,
                                IsOldCounter, IsEvent, IsParameter, DontCountHits, WithHash, HitColor, from_unixtime(LocalEventTime), Age, Sex, Income, Interests,
                                Robotness, RemoteIP, WindowName, OpenerName, HistoryLength, BrowserLanguage, BrowserCountry, SocialNetwork, SocialAction,
                                HTTPError, SendTiming, DNSTiming, ConnectTiming, ResponseStartTiming, ResponseEndTiming, FetchTiming, SocialSourceNetworkID,
                                SocialSourcePage, ParamPrice, ParamOrderID, ParamCurrency, ParamCurrencyID, OpenstatServiceName, OpenstatCampaignID,
                                OpenstatAdID, OpenstatSourceID, UTMSource, UTMMedium, UTMCampaign, UTMContent, UTMTerm, FromTag, HasGCLID, RefererHash, URLHash,
                                CLID
        FROM s3('uri' = 's3://doris-regression/regression/hits_compatible/athena_partitioned/hits_${index}.parquet',
                's3.access_key'= 'AKIASPAWQE3IWHSQ5XFU',
                's3.secret_key' = 'sk',
                's3.endpoint' = 's3.us-east-1.amazonaws.com',
                's3.region' = 'us-east-1',
                'format' = 'parquet');
    "
done

END=$(date +%s)
LOADTIME=$(echo "$END - $START" | bc)
echo "Load time: $LOADTIME"
echo "$LOADTIME" > loadtime

# Dataset contains 99997497 rows, storage size is about 17319588503 bytes
mysql -vvv -h${VELODB_ENDPOINT} -P${VELODB_PORT} -u${VELODB_USER} hits -e "SELECT count(*) FROM hits"
du -bs "$DORIS_HOME"/be/storage/ | cut -f1 | tee storage_size

echo "Data size: $(cat storage_size)"

./run.sh 2>&1 | tee -a log.txt

cat log.txt |
  grep -P 'rows? in set|Empty set|^ERROR' |
  sed -r -e 's/^ERROR.*$/null/; s/^.*?\((([0-9.]+) min )?([0-9.]+) sec\).*?$/\2 \3/' |
  awk '{ if ($2 != "") { print $1 * 60 + $2 } else { print $1 } }' |
  awk '{ if (i % 3 == 0) { printf "[" }; printf $1; if (i % 3 != 2) { printf "," } else { print "]," }; ++i; }'

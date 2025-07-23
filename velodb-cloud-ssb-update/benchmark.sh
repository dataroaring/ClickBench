#!/bin/bash
set -e

export VELODB_ENDPOINT=${VELODB_ENDPOINT:-"http://localhost:8030"}
export VELODB_USER=${VELODB_USER:-"root"}
export VELODB_PASSWORD=${VELODB_PASSWORD:-""}
export VELODB_PORT=${VELODB_PORT:-"9030"}
export S3_AK=${S3_AK:-}
export S3_SK=${S3_SK:-}
export PERCENTAGE=${PERCENTAGE:-25}

ROOT=$(pwd)

export MYSQL_CMD="mysql -vvv -h${VELODB_ENDPOINT} -p${VELODB_PASSWORD} -P${VELODB_PORT} -u${VELODB_USER}"

${MYSQL_CMD} -e 'create database if not exists ssb'
${MYSQL_CMD} ssb <"$ROOT"/create.sql

${MYSQL_CMD} ssb 'drop table if exists customer force'
${MYSQL_CMD} ssb 'drop table if exists part force'
${MYSQL_CMD} ssb 'drop table if exists suppiler force'
${MYSQL_CMD} ssb 'drop table if exists dates force'
${MYSQL_CMD} ssb 'drop table if exists lineorder force'

# Load data
echo "start loading, estimated to take about 9 minutes ..."

date
START=$(date +%s)

${MYSQL_CMD} ssb -e "
    INSERT INTO customer SELECT c1, c2, c3, c4, c5, c6, c7, c8 FROM s3('uri' = 's3://yyq-test/regression/ssb/sf100/customer.tbl.gz',
            's3.access_key'= '${S3_AK}',
            's3.secret_key' = '${S3_SK}',
            's3.endpoint' = 's3.us-west-2.amazonaws.com',
            's3.region' = 'us-west-2',
            'format' = 'csv',
            'column_separator' = '|');
"

${MYSQL_CMD} ssb -e "
    INSERT INTO dates SELECT c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16, c17 FROM s3('uri' = 's3://yyq-test/regression/ssb/sf100/date.tbl.gz',
            's3.access_key'= '${S3_AK}',
            's3.secret_key' = '${S3_SK}',
            's3.endpoint' = 's3.us-west-2.amazonaws.com',
            's3.region' = 'us-west-2',
            'format' = 'csv',
            'column_separator' = '|');
"

${MYSQL_CMD} ssb -e "
    INSERT INTO supplier SELECT c1, c2, c3, c4, c5, c6, c7 FROM s3('uri' = 's3://yyq-test/regression/ssb/sf100/supplier.tbl.gz',
            's3.access_key'= '${S3_AK}',
            's3.secret_key' = '${S3_SK}',
            's3.endpoint' = 's3.us-west-2.amazonaws.com',
            's3.region' = 'us-west-2',
            'format' = 'csv',
            'column_separator' = '|');
"

${MYSQL_CMD} ssb -e "
    INSERT INTO part SELECT c1, c2, c3, c4, c5, c6, c7, c8, c9 FROM s3('uri' = 's3://yyq-test/regression/ssb/sf100/part.tbl.gz',
            's3.access_key'= '${S3_AK}',
            's3.secret_key' = '${S3_SK}',
            's3.endpoint' = 's3.us-west-2.amazonaws.com',
            's3.region' = 'us-west-2',
            'format' = 'csv',
            'column_separator' = '|');
"

${MYSQL_CMD} ssb -e "
    INSERT INTO lineorder SELECT c1, c6, c2, c3, c4, c5, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16, c17 FROM s3('uri' = 's3://yyq-test/regression/ssb/sf100/lineorder.tbl.*',
            's3.access_key'= '${S3_AK}',
            's3.secret_key' = '${S3_SK}',
            's3.endpoint' = 's3.us-west-2.amazonaws.com',
            's3.region' = 'us-west-2',
            'format' = 'csv',
            'column_separator' = '|');
"

END=$(date +%s)
LOADTIME=$(echo "$END - $START" | bc)
echo "Load time: $LOADTIME"
echo "$LOADTIME" > loadtime

for index in `seq 1 $((${PERCENTAGE} / 10))`; do
    ${MYSQL_CMD} ssb -e "
        INSERT INTO lineorder SELECT c1, c6, c2, c3, c4, c5, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16, c17 FROM s3('uri' = 's3://yyq-test/regression/ssb/sf100/lineorder.tbl.${index}.gz',
                's3.access_key'= '${S3_AK}',
                's3.secret_key' = '${S3_SK}',
                's3.endpoint' = 's3.us-west-2.amazonaws.com',
                's3.region' = 'us-west-2',
                'format' = 'csv',
                'column_separator' = '|');
    "
done

# Dataset contains 99997497 rows, storage size is about 17319588503 bytes
mysql -vvv -h${VELODB_ENDPOINT} -p${VELODB_PASSWORD} -P${VELODB_PORT} -u${VELODB_USER} ssb -e "SELECT count(*) FROM lineorder" | tee -a log.txt
du -bs "$DORIS_HOME"/be/storage/ | cut -f1 | tee storage_size

echo "Data size: $(cat storage_size)"

./run.sh 2>&1 | tee -a log.txt

cat log.txt |
  grep -P 'rows? in set|Empty set|^ERROR' |
  sed -r -e 's/^ERROR.*$/null/; s/^.*?\((([0-9.]+) min )?([0-9.]+) sec\).*?$/\2 \3/' |
  awk '{ if ($2 != "") { print $1 * 60 + $2 } else { print $1 } }' |
  awk '{ if (i % 3 == 0) { printf "[" }; printf $1; if (i % 3 != 2) { printf "," } else { print "]," }; ++i; }'

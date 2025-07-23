#!/bin/bash -e

# Go to https://clickhouse.cloud/ and create a service.
# To get results for various scale, go to "Actions / Advanced Scaling" and turn the slider of the minimum scale to the right.
# The number of threads is "SELECT value FROM system.settings WHERE name = 'max_threads'".

# Load the data

export FQDN=${FQDN:-"your-clickhouse-cloud-fqdn"}
export PASSWORD=${PASSWORD:-"your-clickhouse-cloud-password"}
export PERCENTAGE=${PERCENTAGE:-25}

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure < create.sql

START=$(date +%s)

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --format_custom_escaping_rule='CSV' --format_csv_delimiter='|' --query "
  INSERT INTO customer SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/customer.tbl.gz', CSV)
"

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --format_custom_escaping_rule='CSV' --format_csv_delimiter='|' --query "
  INSERT INTO dates SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/date.tbl.gz', CSV)
"

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --format_custom_escaping_rule='CSV' --format_csv_delimiter='|' --query "
  INSERT INTO part SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/part.tbl.gz', CSV)
"

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --format_custom_escaping_rule='CSV' --format_csv_delimiter='|' --query "
  INSERT INTO supplier SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/supplier.tbl.gz', CSV)
"

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --format_custom_escaping_rule='CSV' --format_csv_delimiter='|' --query "
  INSERT INTO lineorder SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/lineorder.tbl.{1..10}.gz}', CSV)
"
END=$(date +%s)
LOADTIME=$(echo "$END - $START" | bc)
echo "Load time: $LOADTIME"
echo "$LOADTIME" > loadtime

START=$(date +%s)

for index in `seq 1 $((${PERCENTAGE} / 10))`; do
    clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --format_custom_escaping_rule='CSV' --format_csv_delimiter='|' --query "
    INSERT INTO lineorder SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/lineorder.tbl.${index}.gz', CSV)
  "
done

END=$(date +%s)
LOADTIME=$(echo "$END - $START" | bc)
echo "Load time: $LOADTIME"
echo "$LOADTIME" > updatetime
# Run the queries

./run.sh

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --final=1  --query "SELECT total_bytes FROM system.tables WHERE name = 'lineorder' AND database = 'default'"

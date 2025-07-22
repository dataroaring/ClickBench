#!/bin/bash -e

# Go to https://clickhouse.cloud/ and create a service.
# To get results for various scale, go to "Actions / Advanced Scaling" and turn the slider of the minimum scale to the right.
# The number of threads is "SELECT value FROM system.settings WHERE name = 'max_threads'".

# Load the data

# export FQDN=...
# export PASSWORD=...
# export PERCENTAGE=25

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure < create.sql

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --query "
  INSERT INTO customer SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/customer.tbl.gz')
"

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --query "
  INSERT INTO date SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/date.tbl.gz')
"

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --query "
  INSERT INTO part SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/part.tbl.gz')
"

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --query "
  INSERT INTO supplier SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/supplier.tbl.gz')
"

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --query "
  INSERT INTO lineorder SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/lineorder.tbl.*')
"

for index in `seq 0 $((${PERCENTAGE} / 10))`; do
  clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --query "
    INSERT INTO lineorder SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/lineorder.tbl.${index}.gz')
  "
done

# Run the queries

./run.sh

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --final=1  --query "SELECT total_bytes FROM system.tables WHERE name = 'lineorder' AND database = 'default'"

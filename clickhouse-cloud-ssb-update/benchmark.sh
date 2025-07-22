#!/bin/bash -e

# Go to https://clickhouse.cloud/ and create a service.
# To get results for various scale, go to "Actions / Advanced Scaling" and turn the slider of the minimum scale to the right.
# The number of threads is "SELECT value FROM system.settings WHERE name = 'max_threads'".

# Load the data

# export FQDN=...
# export PASSWORD=...
# export PERCENTAGE=25

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure < create.sql

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --format_custom_field_delimiter='|' --format_custom_escaping_rule='CSV' --query "
  INSERT INTO customer SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/customer.tbl.gz', CustomSeparated)
"

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --format_custom_field_delimiter='|' --format_custom_escaping_rule='CSV' --query "
  INSERT INTO date SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/date.tbl.gz', CustomSeparated)
"

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --format_custom_field_delimiter='|' --format_custom_escaping_rule='CSV' --query "
  INSERT INTO part SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/part.tbl.gz', CustomSeparated)
"

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --format_custom_field_delimiter='|' --format_custom_escaping_rule='CSV' --query "
  INSERT INTO supplier SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/supplier.tbl.gz', CustomSeparated)
"

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --format_custom_field_delimiter='|' --format_custom_escaping_rule='CSV' --query "
  INSERT INTO lineorder SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/lineorder.tbl.*', CustomSeparated)
"

for index in `seq 0 $((${PERCENTAGE} / 10))`; do
    clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --format_custom_field_delimiter='|' --format_custom_escaping_rule='CSV' --query "
    INSERT INTO lineorder SELECT * FROM url('https://yyq-test.s3.us-west-2.amazonaws.com/regression/ssb/sf100/lineorder.tbl.${index}.gz', CustomSeparated)
  "
done

# Run the queries

./run.sh

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --final=1  --query "SELECT total_bytes FROM system.tables WHERE name = 'lineorder' AND database = 'default'"

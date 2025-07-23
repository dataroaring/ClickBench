#!/bin/bash -e

# Go to https://clickhouse.cloud/ and create a service.
# To get results for various scale, go to "Actions / Advanced Scaling" and turn the slider of the minimum scale to the right.
# The number of threads is "SELECT value FROM system.settings WHERE name = 'max_threads'".

# Load the data

export FQDN=${FQDN:-"your-clickhouse-cloud-fqdn"}
export PASSWORD=${PASSWORD:-"your-clickhouse-cloud-password"}
export PERCENTAGE=${PERCENTAGE:-25}

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure < create.sql

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --query "
  INSERT INTO hits SELECT * FROM url('https://datasets.clickhouse.com/hits_compatible/athena_partitioned/hits_{0..99}.parquet')
"

for index in `seq 0 ${PERCENTAGE}`; do
  clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --time --query "
    INSERT INTO hits SELECT * FROM url('https://datasets.clickhouse.com/hits_compatible/athena_partitioned/hits_${index}.parquet')
  "
done

# 343.455

# Run the queries

./run.sh

clickhouse-client --host "$FQDN" --password "$PASSWORD" --secure --query "SELECT total_bytes FROM system.tables WHERE name = 'hits' AND database = 'default'"

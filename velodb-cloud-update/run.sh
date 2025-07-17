#!/bin/bash

TRIES=3

while read -r query; do
    curl http://127.0.0.1:8040/api/clear_cache/all
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null

    for i in $(seq 1 $TRIES); do
        mysql -vvv -h${VELODB_ENDPOINT} -P${VELODB_PORT} -u${VELODB_USER} hits -e "${query}"
    done
done <queries.sql

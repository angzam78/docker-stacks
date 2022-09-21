#!/bin/bash

read -s -p "Database Admin Password: " password

# initialize cockroachdb
docker stack deploy -c cockroachdb.yml cockroachdb
docker run --rm -it --volume $(pwd)/certs:/certs cockroachdb/cockroach init --certs-dir=/certs --host=172.17.0.1:26257
docker run --rm -it --volume $(pwd)/certs:/certs cockroachdb/cockroach sql --certs-dir=/certs --host=172.17.0.1:26257 --execute="CREATE USER dbadmin WITH PASSWORD '$password';grant admin to dbadmin;"

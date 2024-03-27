#!/bin/sh

mkdir -p certs

docker run --rm -it --volume $(pwd):/certs cockroachdb/cockroach cert create-ca --certs-dir=/certs/certs --ca-key=/certs/ca.key

docker run --rm -it --volume $(pwd):/certs cockroachdb/cockroach cert create-node localhost 172.17.0.1 roach1 roach2 roach3 --certs-dir=/certs/certs --ca-key=/certs/ca.key

docker run --rm -it --volume $(pwd):/certs cockroachdb/cockroach cert create-client root --certs-dir=/certs/certs --ca-key=/certs/ca.key


#!/bin/sh

set -e

# Build docker image
docker build -t mtv-db-node ./docker/node/
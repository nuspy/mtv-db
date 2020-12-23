#!/bin/sh

set -e

# Bad arguments error code
E_BADARGS=85

# Arguments check
if [ -z "$1" ]
then
    # Print usage
    echo "Usage: run-node.sh COMMAND [ARGS...]"
    exit $E_BADARGS
fi

# Get all arguments
ARGS="$*"

# Execute arguments in container
docker container exec mtv-db-node "$ARGS"
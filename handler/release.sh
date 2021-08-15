#!/bin/sh

if [ $# -eq 0 ]; then
    echo "No version provided"
    exit 1
fi

docker build -t mdmparis/defense-finder .
docker tag mdmparis/defense-finder:latest 187971905951.dkr.ecr.eu-west-3.amazonaws.com/mdmparis/defense-finder:$1
docker push 187971905951.dkr.ecr.eu-west-3.amazonaws.com/mdmparis/defense-finder:$1

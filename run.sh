#!/bin/bash
#
# Set this to be the location you want the data stored
EXPORT_DIR=$(pwd)

# Run the docker container to dump the data
docker run --rm -v $EXPORT_DIR:/data stephenhouser/hobo-scrape

#!/bin/bash
#
# Set this to be the location you want the data stored
#EXPORT_DIR=$(pwd)
#docker run --rm -v $EXPORT_DIR:/data stephenhouser/hobo-scrape

# Run the docker container to dump the data
docker run --rm --env UPLOAD_URL="http://e-axiom.bowdoin.edu/node-red/hobolonk/upload" stephenhouser/hobo-scrape

#!/bin/bash

docker run --rm -v $(pwd):/data stephenhouser/hobo-scrape

#docker run --rm stephenhouser/hobo-scrape casperjs --version -v .:/home/casperjs-tests npm start
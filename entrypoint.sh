#!/bin/bash
casperjs hobo-scrape.js tower \
	&& cp -r ./tower /data \
	&& casperjs hobo-scrape.js stream \
	&& cp -r ./stream /data

#!/bin/bash

scrape() {
	casperjs hobo-scrape.js	$1 && \
}

upload() {
	for f in $1/*.csv
	do
		curl --form file=@$1 ${UPLOAD_URL}	
	done
}

scrape tower && scrape stream

if [ -z ${UPLOAD_URL+x} ];
	upload tower
	upload stream
else
	cp -r ./tower /data
	cp -r ./stream /data
fi

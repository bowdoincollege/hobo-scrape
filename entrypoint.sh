#!/bin/bash

STATION_ID=${1:?Station ID \$1 Must be set}
OUTPUT_DIR=${2:-./data}

# set to --silent to quiesce all messages from cURL
#CURL_SILENT=--silent

# Scrape the website and download the data (in container directory)
echo "Scraping [$STATION_ID] to [$OUTPUT_DIR]..."
casperjs hobo-scrape.js	$STATION_ID $OUTPUT_DIR
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi	

# Send the data to it's final destination
if [ ! -z ${POST_URL+x} ] ; then
	# If POST_URL was specified, upload all the .csv files there
	for f in $OUTPUT_DIR/*.csv; do
		echo "Posting [$f] to [$POST_URL]..."
		curl ${CURL_SILENT} --connect-timeout 2 --form file=@$f ${POST_URL} > /dev/null
		#rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi	
	done
else
	# Otherwise, move .csv files to the /data (mounted) directory
	echo "Copying results to [$OUTPUT_DIR]..."
	cp $OUTPUT_DIR/*.csv /data
	#rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi	
fi

# Clean up intermediate .csv files
echo "Cleaning up..."
rm -f $OUTPUT_DIR/*.csv

echo "done."

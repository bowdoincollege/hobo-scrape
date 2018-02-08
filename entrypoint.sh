#!/bin/bash
#
# Calls hobo-scrape.js to download data for each of the passed stations
#
# Syntax:
#	entrypoint.sh <output directory or URL> <station id> ...
#

# set to --silent to quiesce all messages from cURL
#CURL_SILENT=--silent

# Parse output directory or URL to post to with cURL
if [[ $1 == http* ]]; then
	post_url=$1
	data_dir=./data
else
	data_dir=$1
fi
shift

# Scrape the website and download the data.
# Do this for each station id given as parameters
for station_id in $*; do
	echo "Launch virtual browser to fetch [${station_id}] to [${data_dir}]..."
	casperjs hobo-scrape.js "${data_dir}" "${station_id}"
	rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi	
done

# Send the data to it's final destination
if [[ ! -z ${post_url+x} ]] ; then
	# If POST_URL was specified, upload all the .csv files there
	for f in ${data_dir}/*.csv; do
		echo "Post [$f] to [${post_url}]..."
		curl ${CURL_SILENT} --connect-timeout 2 --form file=@$f ${post_url} > /dev/null
		#rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi	
	done
fi

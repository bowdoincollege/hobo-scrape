#!/bin/bash
#
# Calls hobo-scrape.js to download data for each of the passed stations
#
# Syntax:
#	entrypoint.sh <output directory or URL> <station id> ...
#

# Seconds to sleep between scrapes when in daemon mode
FETCH_DELAY=${FETCH_DELAY:-300}

# set to --silent to quiesce all messages from cURL
CURL_SILENT=${CURL_SILENT:-}
CURL_TIMEOUT=${CURLTIMEOUT:-2}

# Defaults
daemon_mode=false
data_dir=./data

usage() {
	echo "entrypoint.sh [-d] [-p <url>] [-o <directory>] <station id>..."
	exit 1
}

scrape() {
	local data_dir=$1
	shift

	# Scrape the website and download the data.
	# Do this for each station id given as parameters
	for station_id in $*; do
		echo "Launch virtual browser to fetch [${station_id}] to [${data_dir}]..."
		casperjs hobo-scrape.js "${data_dir}" "${station_id}"
		#rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi	
	done
}

post() {
	local data_dir=$1
	local post_url=$2

	# If POST_URL was specified, upload all the .csv files there
	for f in ${data_dir}/*.csv; do
		if [ -f $f ]; then
			echo "Post [$f] to [${post_url}]..."
			curl ${CURL_SILENT} --connect-timeout ${CURL_TIMEOUT} --form file=@$f ${post_url} > /dev/null
			#rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi	
		fi
	done
}

# Parse command line options
while getopts ":hdp:o:" arg; do
  case $arg in
    h) 	usage 
    	;;
	d) 	daemon_mode=true
		;;
	p) 	post_url=${OPTARG}
		;;
	o) 	data_dir=${OPTARG}
		;;
	*) 	break
		;;
  esac
done
shift $((OPTIND-1))

# Verify station ids were passed on command line. 
# Otherwise there's nothing to do.
if [ $# -le 0 ]; then
	echo "No sensor stations specified."
	usage
fi

while true; do
	scrape "${data_dir}" $*

	# Send the data to it's final destination
	if [ ! -z ${post_url+x} ] ; then
		post "${data_dir}" "${post_url}"
	fi

	if [ ${daemon_mode} == "false" ]; then
		break;
	fi

	echo "Waiting for ${FETCH_DELAY} seconds before fetching again..."
	sleep ${FETCH_DELAY}
done
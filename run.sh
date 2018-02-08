#!/bin/bash

scrape() {
	# Run the docker container to save the data to OUTPUT_DIR
	if [ ! -z ${OUTPUT_DIR+x} ] ; then
		docker run --rm \
			-v "${OUTPUT_DIR}":/data \
			stephenhouser/hobo-scrape $1 $2
	fi

	# Run the docker container to POST the data to POST_URL
	if [ ! -z ${POST_URL+x} ] ; then
		docker run --rm \
			--env POST_URL="${POST_URL}" \
			stephenhouser/hobo-scrape $1 $2
	fi
}

while getopts 'vo:p:' arg; do
  case $arg in
    o) OUTPUT_DIR="$OPTARG";;
    p) POST_URL="$OPTARG";;
   	*) echo invalid option: $OPTARG;;
  esac
done

# If neither output nor post url are specified... do this by default
if [[ -z ${OUTPUT_DIR+x} ]] ; then
	if [[ -z ${POST_URL+x} ]] ; then
		POST_URL="http://e-axiom.bowdoin.edu/node-red/hobolonk/upload"
	fi
fi

scrape '2665cb0a357c93fc10bb84162133c89d' 'tower'
scrape 'af109c8068362219390a99cec629f0f6' 'stream'




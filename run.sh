#!/bin/bash

# Stations to scrape data from
stations="2665cb0a357c93fc10bb84162133c89d af109c8068362219390a99cec629f0f6"

if [[ $1 == "local" ]]; then
	# Run the docker container and save to ./data
	docker run --rm -v "$(pwd)/data":/data \
		stephenhouser/hobo-scrape -o /data ${stations}
else
	# Run the docker container and post to e-axiom dashboard (url above)
	post_url=http://e-axiom.bowdoin.edu/node-red/hobolink/upload

	docker run --rm	\
		stephenhouser/hobo-scrape -p ${post_url} ${stations}
fi
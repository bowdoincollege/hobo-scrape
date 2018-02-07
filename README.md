
# HoboLink Data Scraper

Script to download recent data from OnSet HoboLink for remote sensor stations at Bowdoin College. 

There is no API for getting real-time data from HoboLink. The provided data export methods are scheduled email or [S]FTP delivery. Neither provides adequate frequency for a near real-time dashboard display.

This script uses [CasperJS](http://casperjs.org) to emulate a web browser and pull down the data directly from the public facing charts provided by OnSet through HoboLink. Currently it is designed to be run at least daily to gather data for the past 24 hours.

There are two ways to run the script

* Standalone with a local install of CasperJS, PhantomJS, and NodeJS.
* In a Docker container that contains the dependencies.

## Standalone Install and Execution

* Run `npm install --production` to prepare the script and install dependencies.
* Run `npm start` to download data for the past 24 hours run (repeat as needed).

## Dockerized Install and Execution

* Run `build.sh`: build Docker image with script and dependencies.
* Edit `run.sh` to set the export location `EXPORT_DIR`
* Run `run.sh` to download data for the past 24 hours run (repeat as needed).

## Where's the data?

The script creates several `.csv` files, one for each chart/sensor attached to a station in a directory with the station's name. We (Bowdoin) have two stations; `tower` and `stream`. `tower` is the only active one at the time of this writing. Each file is named for the sensor id assigned by HoboLink.

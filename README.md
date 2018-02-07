
# HoboLink Data Scraper

Script to download recent data from OnSet HoboLink for remote sensor stations at Bowdoin College. 

There is no API for getting real-time data from HoboLink. The provided data export methods are scheduled email or [S]FTP delivery. Neither provides adequate frequency for a near real-time dashboard display.

This script uses [CasperJS](http://casperjs.org) to emulate a web browser and pull down the data directly from the public facing charts provided by OnSet through HoboLink. Currently it is designed to be run at least daily to gather data for the past 24 hours.

## Setup 

To prepare the script and install dependencies in the local `node_modules` directory:

```
npm install --production
```


## Running

To download data for the past 24 hours:

```
npm start
```

This will create a series of `.csv` files with the daily data. The file names reflect the sensor id values from the HoboLink web site.


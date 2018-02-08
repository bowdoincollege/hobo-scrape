# HoboLink Import to InfluxDB (for dashboard view)

This directory contains scripts to import data from OnSet's HoboLink system into an InfluxDB time series database. 

OnSet provides the weather reporting system we use at Brunswick Landing. The capture stations report via cell phone to HoboLink where the data is stored. There is a weekly process that sends the past week's data (via email) in a .zip format. These scripts use that .zip'ed CSV file as input.

The intent is to parse those and insert the measurements into an InfluxDB database that can then be queried via analysis tools, like Grafana. There is another project - 'docker dashboard' that is a combination of Influx and Grafana that I generally use.

## Where's the data go?

Currently, I have a 'dashboard' setup on `e-axiom.bowdoin.edu` that has Influx, Grafana, and Node-Red installed. To import the latest .zip data using these scripts.

```
# connect to remote docker via `rdocker`
rdocker houser@e-axiom

# import latest data in `latest.zip`
./hobolink_zip_import ../All_Data_for_Last_Month_2017_12_12_15_50_26_UTC.zip
```

Then you can view the data in [Grafana on e-axiom](http://e-axiom.bowdoin.edu/grafana/)


## Process single .zip file from HoboLink

```
unzip -p ../All_Data_for_Last_Month_2017_12_12_15_50_26_UTC.zip All*.csv | python hobolinkcsv2line.py | gzip > import.influx.gz
```

or, more cleanly,

```
./hobolink_zip_import ../All_Data_for_Last_Month_2017_12_12_15_50_26_UTC.zip
```

## Process a bunch of files from HoboLink

NOTE: Influx may not do well with importing more than 5,000 points at a time[1](https://docs.influxdata.com/influxdb/v1.4/tools/shell/).

```
for f in ../*.zip
do
	./hobolink_zip_import $f
	# let influx catch up...
	sleep 10
done
```

## Importing these data

Need to specify the precision and compressed files when importing to InfluxDB.

```
influx -import -compressed  -precision=s -path=<<import.gz>>
```

## Drop all measurements from Brusnwick landing station

```
drop measurement battery
drop measurement dew_point
drop measurement gust_speed
drop measurement humidity
drop measurement par_ue
drop measurement rain
drop measurement solar_radiation
drop measurement temperature
drop measurement undefined
drop measurement wind_direction
drop measurement wind_speed
show measurements
```


## UNIT CHANGE

On February 5th, 2018, I changed the default units for temperature to the SI system. Old exports are in U.S. (farenheit) new ones are in celcius. The python export checks what units are in use and converts everything to C.


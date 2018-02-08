#!/usr/bin/env python

import sys
import csv
import string
import re
import gzip
import argparse
import logging
from datetime import datetime

ENCODING = 'mac_roman'
CSV_DIALECT = 'excel'
LOG_FORMAT = '%(message)s'

# column_map = {
#     "Line#"                                 : ( "ignore" ),
#     "Date"                                  : ( "timestamp" ),
#     "Battery, V, Stream Station"            : ( "battery", "stream" ),
#     "Temperature, *F, Stream Station"       : ("temperature", "stream"),
#     "RH, %, Stream Station"                 : ("humidity", "stream"),
#     "Dew Point, *F, Stream Station"         : ("dew_point", "stream"),
#     "Battery, V, Tower Station"             : ("battery", "tower"),
#     "Temperature, *F, Tower Station"        : ("temperature", "tower"),
#     "RH, %, Tower Station"                  : ("humidity", "tower"),
#     "Dew Point, *F, Tower Station"          : ("dew_point", "tower"),
#     "Rain, in, Tower Station"               : ("rain", "tower"),
#     "Wind Direction, *, Tower Station"      : ("wind_direction", "tower"),
#     "Solar Radiation, W/m^2, Tower Station" : ("solar_radiation", "tower"),
#     "Wind Speed, mph, Tower Station"        : ("wind_speed", "tower"),
#     "Gust Speed, mph, Tower Station"        : ("gust_speed", "tower"),
#     "PAR, uE, Tower Station"                : ("par_ue", "tower"),
# }


def column_name(name):
    """Return cleaned up names for columns of CSV file."""
    # Only needs exceptions to standard token cleanup
    column_map = {
        "line#" : "ignore",
        "date"  : "timestamp",
        "rh"    : "humidity",
        "par"   : "par_ue"
    }

    if name in column_map:
        return column_map[name]
    
    return name

def clean_token(token):
    """Clean up tokens
        - remove leading and trailing spaces
        - replace internal spaces with underscores
        - lowercase everything
        """
    return token.strip().lower().replace(' ', '_')

def column_info(colum_header):
    """Return a tuple of column name and any associated tags
        parsed from the column header as sent in by HoboLink.
        """
    commas = colum_header.count(',')
    if commas == 0:
        return (column_name(clean_token(colum_header)))

    (key, units, location) = colum_header.split(',')
    key = column_name(clean_token(key))
    units = clean_token(units)
    location = clean_token(location)
    return (key, units, location)

def valid_int(int_str):
    try:
        int(int_str)
        return True
    except ValueError:
        return False

def setup_logging(loglevel):
    # If `-l` is specified then use INFO as default
    #LOG_FORMAT = '%(levelname)s:%(message)s'
    log_level = 0 # Not set

    if loglevel:
        if valid_int(loglevel):
            log_level = int(loglevel)
        else:
            log_level = getattr(logging, loglevel.upper(), None)
            if not isinstance(log_level, int):
                raise ValueError("Invalid log level: {}".format(loglevel))
    else:
        log_level = 20 # INFO level

    logging.basicConfig(format=LOG_FORMAT, level=log_level)
    
def write_influxdb_header(output):
    output.write("""# DDL
CREATE DATABASE dashboard

# DML
# CONTEXT-DATABASE: dashboard

""")

def main():
    aparser = argparse.ArgumentParser()
    aparser.add_argument("-l", "--log", nargs='?', 
        dest='loglevel',
        default='WARNING',
        help="show diagnostic messages (DEBUG, INFO, WARNING, ERROR, CRITICAL)")
    aparser.add_argument("input", nargs='?',
        type=argparse.FileType('r', encoding=ENCODING), 
        default=sys.stdin,
        help="CSV input file(s)")
    aparser.add_argument("output", nargs='?', 
        type=argparse.FileType('w', encoding=ENCODING), 
        default=sys.stdout, 
        help="InfluxDB output file")
    args = aparser.parse_args()

    setup_logging(args.loglevel)

    # Read in and count all input files...
    logging.info("Reading {}...".format(args.input.name))

    # Do it...
    csreader = csv.reader(args.input, dialect=CSV_DIALECT)
    headers = next(csreader)

    write_influxdb_header(args.output)
    for row in csreader:
        timestamp = None
        for header, value in zip(headers, row):
            #if h != None and h != "":
            measurement = column_info(header)
            #value = v.strip()
            if measurement == "ignore":
                pass
            elif measurement == "timestamp":
                timestamp = datetime.strptime(value, '%m/%d/%y %H:%M:%S')
            elif timestamp != None and value != "":
                tstamp = int(timestamp.timestamp())
                clean_value = value
                try:
                    clean_value = float(value.replace(',',''))
                except ValueError:
                    pass

                (key, units, location) = measurement

                if units == "*f":
                    clean_value = (clean_value - 32.0) * 5.0 / 9.0
                    units = "*c"
                    #print("convert {}F to {}C".format(value, clean_value))

                if units == "*c" and clean_value < -273.15:
                    continue

                #print('{},location={} value={} {}'.format(key, tags, clean_value, tstamp))
                args.output.write('{},location={} value={:.4f} {}\n'.format(key, location, clean_value, tstamp))

if __name__ == "__main__":
    main()

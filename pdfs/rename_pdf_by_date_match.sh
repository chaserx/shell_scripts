#! /usr/bin/env bash

# Usage: ./rename_pdf_by_date_match.sh <pdf-file> <date>
#
# The script should rename the pdf file to the date in the ISO8601 format
#
# Example:
# ./rename_pdf_by_date_match.sh example.pdf 
#
# the output file should be:
# 2024-02-20_example.pdf

SCRIPT_LOG=script_out.log
touch $SCRIPT_LOG

todayISO=$(gdate -I)
todayUnix=$(date +%s)

function DEBUG(){
  local msg="$1"
  local timeAndDate=`date`
  echo "[$timeAndDate] [DEBUG]  $msg" >> $SCRIPT_LOG
}


# Check if pdfgrep is installed
if ! command -v pdfgrep &> /dev/null; then
    echo "pdfgrep could not be found"
    exit 1
fi

# Check if a file is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <pdf-file>"
    exit 1
fi

# Check if the file exists
if [ ! -f "$1" ]; then
    echo "File $1 does not exist"
    exit 1
fi

# check if the file is a pdf
if ! pdfinfo "$1" > /dev/null 2>&1; then
    echo "File $1 is not a pdf"
    exit 1
fi

# Get the directory of the original file
dir=$(dirname "$1")

# Get just the filename without path and extension
filename=$(basename "$1" .pdf)

# Extract the date from the pdf file into a variable globally across multiple lines
# Return just the first result
#
# Match date formats: APR 13 2022 or APR 13, 2022 or April 13, 2022 or 4/13/2022 or 04/14/2022
# https://regex101.com/r/9fPYPA/1
# derived from https://stackoverflow.com/a/56081857
#
match_result=$(pdfgrep -i -m1 -o -P -e "(((1[0-2]|0?[1-9])\/(3[01]|[12][0-9]|0?[1-9])\/(?:[0-9]{2})?[0-9]{2})|((Jan(uary)?|Feb(ruary)?|Mar(ch)?|Apr(il)?|May|Jun(e)?|Jul(y)?|Aug(ust)?|Sep(tember)?|Oct(ober)?|Nov(ember)?|Dec(ember)?)\s+\d{1,2},?\s+\d{4}))" "$1")

if [ -z "$match_result" ]; then
    echo "No matching dates found in $1"

    mv "$1" "${dir}/${todayISO}_x_${filename}_${todayUnix}.pdf"
    DEBUG "Couldn't find a date. Renamed $1 to ${todayISO}_x_${filename}_${todayUnix}.pdf"
    exit 0
fi

# Reformat the dates to the ISO8601 format using Ruby because we don't know the date format
date=$(echo "$match_result" | tail -n 1 | ruby -ne 'require "date"; puts Date.parse($_.strip).iso8601')

# Prepend the ISO8601 format to the filename and rename the file, keeping it in the same directory
mv "$1" "${dir}/${date}_${filename}_${todayUnix}.pdf"

DEBUG "Renamed $1 to ${date}_${filename}_${todayUnix}.pdf"

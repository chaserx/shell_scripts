#! /opt/homebrew/bin/bash

# Usage: ./rename_pdf_by_date_match.sh <pdf-file> <date>
#
# The script should rename the pdf file to the date in the ISO8601 format
#
# Example:
# ./rename_pdf_by_date_match.sh example.pdf 
#
# the output file should be:
# 2024-02-20_example.pdf


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

# Extract the date from the pdf file into a variable globally across multiple lines

# date format 02/20/2024
slash_dates=$(pdfgrep -o -P -e "\d{2}/\d{2}/\d{4}" "$1")

# date format February 20, 2024
comma_dates=$(pdfgrep -o -P -e "\w+\s\d{2},\s\d{4}" "$1")

# date format 2024-02-20
iso_dates=$(pdfgrep -o -P -e "\d{4}-\d{2}-\d{2}" "$1")

# date format 02-20-2024
dash_dates=$(pdfgrep -o -P -e "\d{2}-\d{2}-\d{4}" "$1")

if [ -z "$slash_dates" ] && [ -z "$comma_dates" ] && [ -z "$iso_dates" ] && [ -z "$dash_dates" ]; then
    echo "No dates found in $1"
    exit 1
fi

# Combine all the dates into a single variable
dates="$slash_dates $comma_dates $iso_dates $dash_dates"

# Reformat the dates to the ISO8601 format using Ruby
dates=$(echo "$dates" | tail -n 1 | ruby -ne 'require "date"; puts Date.parse($_.strip).iso8601')

# Get just the filename without path and extension
filename=$(basename "$1" .pdf)

# Get the directory of the original file
dir=$(dirname "$1")

# Prepend the ISO8601 format to the filename and rename the file, keeping it in the same directory
mv "$1" "${dir}/$(echo "$dates")_${filename}.pdf"

# write the rename to a log file
echo "Renamed $1 to $(echo "$dates")_${filename}.pdf" >> rename_pdf_by_date_match.log

#!/bin/bash
# sum up used used volume per month and print result to data_monthly.csv in Mb.
for i in *.CSV ;do
 echo -e "`echo "$i" | cut -d "-" -f 1,2` | " | tr -d " \n"
 expr `cut $i -d "|" -f25 | tr -d " KB" |awk '{s+=$1} END {print s}' -` / 1024
done > data_monthly.csv

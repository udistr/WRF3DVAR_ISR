#!/bin/bash

#DD1=20200901
#HH1=00
#DD2=20200901
#HH2=06

DD1=$1
HH1=$2
DD2=$3
HH2=$4

#echo $DD1

echo "Downloading ERA5 data"
bash Download_WRF_snap.sh ${DD1} ${HH1} ${DD2} ${HH2} &> downlad.log
if [ $? -ne 0 ]; then echo "Command failed with exit code $?. Exiting.";  exit 1; fi



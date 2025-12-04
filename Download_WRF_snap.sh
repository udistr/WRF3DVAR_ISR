#!/bin/bash -l

CODEDIR=`pwd` #/lus/grand/projects/MEDDIAC/WRF-4.1.3_INTEL/DATA_1M
DATADIR=`pwd` #/lus/grand/projects/MEDDIAC/WRF-4.1.3_INTEL/DATA_1M
mkdir -p ../WRFDATA

#conda init bash
cd $CODEDIR

# YYYYMMDD
DATE1=$1
HOUR1=$2
DATE2=$3
HOUR2=$4

Nort=55
West=-15
Sout=15
East=55

mv ../WRFDATA/*grib ../WRFDATA/old_data/

d=`date -u -d "${DATE1}T${HOUR1} +7 hour"  +'%Y%m%dT%H'`
enddate=`date -u -d "${DATE2}T${HOUR2} +7 hour + 1 hour"  +'%Y%m%dT%H'`
echo $d
echo $enddate

echo "entering loop"

while [[ "$d" < "$enddate" ]]; do

  DATE1=${d:0:8}
  HOUR1=${d:9:2}

  echo "get data for $DATE1 $HOUR1"

  FILE="../WRFDATA/old_data/ERA5-${DATE1}${HOUR1}-sl.grib"

  if [ ! -e "$FILE" ]; then
    echo "File does not exist. Downloading file"
    sed -e "s/DATE1/${DATE1}/g;s/HOUR1/${HOUR1}/g;s/Nort/${Nort}/g;s/West/${West}/g;s/Sout/${Sout}/g;s/East/${East}/g;" GetERA5-sl_snap.py > GetERA5-${DATE1}${HOUR1}-sl.py
    python GetERA5-${DATE1}${HOUR1}-sl.py
    rm GetERA5-${DATE1}${HOUR1}-sl.py
  else
    echo "File exists. Copy file"
    cp ${FILE} .
  fi
  
  FILE="../WRFDATA/old_data/ERA5-${DATE1}${HOUR1}-pl.grib"

  if [ ! -e "$FILE" ]; then
    echo "File does not exist. Downloading file"
    sed -e "s/DATE1/${DATE1}/g;s/HOUR1/${HOUR1}/g;s/Nort/${Nort}/g;s/West/${West}/g;s/Sout/${Sout}/g;s/East/${East}/g;" GetERA5-pl_snap.py > GetERA5-${DATE1}${HOUR1}-pl.py
    python GetERA5-${DATE1}${HOUR1}-pl.py
    rm GetERA5-${DATE1}${HOUR1}-pl.py
  else
    echo "File exists. Copy file"
    cp ${FILE} .
  fi

  mv ERA5-${DATE1}${HOUR1}-sl.grib ERA5-${DATE1}${HOUR1}-pl.grib ../WRFDATA/

  d=`date -u -d "${d} +7 hour + 1 hour"  +'%Y%m%dT%H'`

done  
exit 0

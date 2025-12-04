#!/bin/bash

echo "WPS"

DATE1=20200106
HH1=00
DATE2=20200106
HH2=06

DATE1=$1
HH1=$2
DATE2=$3
HH2=$4

#WPSDIR=/shared/WRF4.4/WPS
#WRFDIR=/shared/WRF4.4/WRF/run
#WRFDATA=/shared/WRF4.4/WRFDATA
#DADIR=/shared/WRFDA/RUN_ana/Jan2020_3d_rBE_sound_udi2
#OBSDIR=/shared/WRFDA/OBS
#OBSPROC=/shared/WRFDA/preproc_obs_udi
#DA_DATA=/shared/WRF4.4/WRF/DA_DATA

mkdir -p ${DA_DATA}

cd ${WPSDIR}

YY1=`echo $DATE1 | cut -c1-4`
MM1=`echo $DATE1 | cut -c5-6`
DD1=`echo $DATE1 | cut -c7-8`
YY2=`echo $DATE2 | cut -c1-4`
MM2=`echo $DATE2 | cut -c5-6`
DD2=`echo $DATE2 | cut -c7-8`

D1=${YY1}-${MM1}-${DD1}_${HH1}
D2=${YY2}-${MM2}-${DD2}_${HH2}

sed -i "s/start_date =.*/start_date = '${D1}:00:00','${D1}:00:00','${D1}:00:00'/g" namelist.wps
sed -i "s/end_date.*/end_date =   '${D2}:00:00','${D2}:00:00','${D2}:00:00'/g" namelist.wps

. ~/Build_WRF/LIBRARIES/env.sh

./link_grib.csh ${WRFDATA}/ERA5-*

echo "Run ungrib"

ln -sf ungrib/Variable_Tables/Vtable.ERA-interim.pl Vtable
#sed -i "s/prefix.*/prefix = \'FILE\',/g" namelist.wps
rm -f FILE:*
./ungrib.exe > ung_plev.txt 2>&1
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

echo "Run metgrid"
rm -f met_em.d0*
./metgrid.exe &> metgrid.log
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

cp namelist.wps ${DA_DATA}

cd ${WRFDIR}
rm -f met_em.d0*
ln -sf ${WPSDIR}/met_em.d0* ./

sed -i "s/start_year.*/start_year = ${YY1}, ${YY1}, ${YY1},/g" namelist.input
sed -i "s/start_month.*/start_month = ${MM1},   ${MM1},   ${MM1},/g" namelist.input
sed -i "s/start_day.*/start_day = ${DD1},   ${DD1},   ${DD1},/g" namelist.input
sed -i "s/start_hour.*/start_hour = ${HH1},   ${HH1},   ${HH1},/g" namelist.input

sed -i "s/end_year.*/end_year = ${YY1}, ${YY1}, ${YY1},/g" namelist.input
sed -i "s/end_month.*/end_month = ${MM2},   ${MM2},   ${MM2},/g" namelist.input
sed -i "s/end_day.*/end_day = ${DD2},   ${DD2},   ${DD2},/g" namelist.input
sed -i "s/end_hour.*/end_hour = ${HH2},   ${HH2},   ${HH2},/g" namelist.input

echo "Run real"
sbatch --wait run_sbatch_real.sh
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

mkdir -p ${DA_DATA}/${D1}
echo "copy real files to ${DA_DATA}/${D1}"
cp wrfinput* ${DA_DATA}/${D1}/
cp wrfbdy* ${DA_DATA}/${D1}/
cp wrflowinp* ${DA_DATA}/${D1}/




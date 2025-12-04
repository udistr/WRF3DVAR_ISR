#!/bin/bash

echo "WRF"

DATE1=20200901
HH1=00
DATE2=20200901
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

YY1=`echo $DATE1 | cut -c1-4`
MM1=`echo $DATE1 | cut -c5-6`
DD1=`echo $DATE1 | cut -c7-8`

D1=${YY1}-${MM1}-${DD1}_${HH1}

#echo "update boundary conditions"
#cd /shared/WRFDA/RUN_ana/update_bc
#cp ${WRFDIR}/wrfbdy_d01 .
#cp ${DADIR}/wrfvar_output .
#./da_update_bc.exe
#cp wrfbdy_d01 ${DA_DATA}/${D1}/wrfbdy_d01_update
#cp wrfbdy_d01 ${WRFDIR}

cd ${WRFDIR}

cp namelist.input ${DA_DATA}
rm wrfout*
echo "Submiting job to queue: wrf"
sbatch --wait run_sbatch.sh
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

echo "copy wrf files to ${DA_DATA}/${D1}"

cp wrflowinp*  ${DA_DATA}/${D1}/
cp wrfout*  ${DA_DATA}/${D1}/

echo

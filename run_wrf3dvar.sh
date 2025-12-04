#!/bin/bash

DATE1=20200109
HH1=00
loop=1

#WPSDIR=/shared/WRF4.4/WPS
#WRFDIR=/shared/WRF4.4/WRF/run
#WRFDATA=/shared/WRF4.4/WRFDATA
#DADIR=/shared/WRFDA/RUN_ana/Jan2020_3d_rBE_sound_udi2
#OBSDIR=/shared/WRFDA/OBS
#OBSPROC=/shared/WRFDA/preproc_obs_udi
#DA_DATA=/shared/WRF4.4/WRF/DA_DATA_V2

DATE1=$1
HH1=$2
loop=$3
assim=$4

YY1=`echo $DATE1 | cut -c1-4`
MM1=`echo $DATE1 | cut -c5-6`
DD1=`echo $DATE1 | cut -c7-8`

D1=${YY1}-${MM1}-${DD1}_${HH1}
D0=$(date -d "${DATE1} ${HH1} - 6 hours" "+%Y-%m-%d_%H")

if [ $loop -gt 0 ]; then
  echo "update initial conditions"
  cd /shared/WRFDA/RUN_ana/update_ic
  sed -i "s/wrf_input.*/wrf_input = 'wrfinput_d01',/g" parame.in
  sed -i "s/domain_id.*/domain_id = 1,/g" parame.in
  cp ${DA_DATA}/${D0}/wrfout_d01_${YY1}-${MM1}-${DD1}_${HH1}:00:00 ./fg
  cp ${DA_DATA}/${D1}/wrfinput_d01 .
  ./da_update_bc.exe &> update.log
  cp fg ${DADIR}/fg_d01
  sed -i "s/wrf_input.*/wrf_input = 'wrfinput_d02',/g" parame.in
  sed -i "s/domain_id.*/domain_id = 2,/g" parame.in
  cp ${DA_DATA}/${D0}/wrfout_d02_${YY1}-${MM1}-${DD1}_${HH1}:00:00 ./fg
  cp ${DA_DATA}/${D1}/wrfinput_d02 .
  ./da_update_bc.exe &> update.log
  cp fg ${DADIR}/fg_d02  
  cd ${DADIR}
else
  cd ${DADIR}
  cp ${WRFDIR}/wrfinput_d01 ./fg_d01
  cp ${WRFDIR}/wrfinput_d02 ./fg_d02
  cp /shared/WRFDA/gen_be/gen_be5_cv7_d01/working/be.dat ${DADIR}/be.dat_d01
  cp /shared/WRFDA/gen_be/gen_be5_cv7_d02/working/be.dat ${DADIR}/be.dat_d02
fi

cp fg_d01 ${DA_DATA}/${D1}/fg_d01
cp fg_d02 ${DA_DATA}/${D1}/fg_d02

if [ $assim -ne 0 ]; then

cp fg_d01 ${OBSPROC}/
cp fg_d02 ${OBSPROC}/

MADIS=${OBSDIR}/MADIS

#define madis output folder
export MADIS_DATA=${MADIS}

if [ ${HH1} = "00" ]; then
  FILE=${MADIS}/point/acars/netcdf/${DATE1}_0000
  if [ ! -e "$FILE" ]; then
    echo "get MADIS observations once per day"
    cd ${MADIS}
    #DATE1_plus_3=$(date -d "${DATE1} ${HH1} + 3 hours" "+%Y%m%d %H")
    #DATE1_minus_3=$(date -d "${DATE1} ${HH1} - 3 hours" "+%Y%m%d %H")
    DATE1_plus_1day=$(date -d "${DATE1} ${HH1} + 23 hours" "+%Y%m%d %H")
    #change date
    sed -i  "/Start/s/[0-9]\{8\} [0-9]\{2\}/${DATE1} ${HH1}/; /End/s/[0-9]\{8\} [0-9]\{2\}/${DATE1_plus_1day}/" ftp.par1.txt
    sed -i  "/Start/s/[0-9]\{8\} [0-9]\{2\}/${DATE1} ${HH1}/; /End/s/[0-9]\{8\} [0-9]\{2\}/${DATE1_plus_1day}/" api.par1.txt
    #get data
    ./get_MADIS_Data_unix.pl \n \n  &> get_madis_${D1}.txt
    RC=$?
    if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi
  fi
fi

cd ${OBSDIR}/MADIS2LITTLER

DATE1_plus_3b=$(date -d "${DATE1} ${HH1} + 3 hours" "+%Y%m%d%H")
DATE1_minus_3b=$(date -d "${DATE1} ${HH1} - 3 hours" "+%Y%m%d%H")
DATE1_plus_2b=$(date -d "${DATE1} ${HH1} + 2 hours" "+%Y%m%d%H")
DATE1_minus_2b=$(date -d "${DATE1} ${HH1} - 2 hours" "+%Y%m%d%H")
DATE1_plus_1b=$(date -d "${DATE1} ${HH1} + 1 hours" "+%Y%m%d%H")
DATE1_minus_1b=$(date -d "${DATE1} ${HH1} - 1 hours" "+%Y%m%d%H")

# set the time for converting observations, one timestamp
sed -i "s/SDATE=.*/SDATE=${DATE1_minus_3b}/g" da_run_madis_to_little_r.ksh
sed -i "s/EDATE=.*/EDATE=${DATE1_plus_3b}/g" da_run_madis_to_little_r.ksh

export LD_LIBRARY_PATH=/home/ec2-user/Build_WRF/LIBRARIES/netcdf32/lib

echo "convert madis data to little-r"

./da_run_madis_to_little_r.ksh &> madis2little-r_${D1}.txt
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

cd ${OBSPROC}

MADIS2LITTLER=$MADIS/little_r_obs

output_file=/shared/WRFDA/preproc_obs_udi/test_madis.txt

rm ${output_file}

input_folders=(
	"${MADIS2LITTLER}/${DATE1_minus_3b}"
        "${MADIS2LITTLER}/${DATE1_minus_2b}"
        "${MADIS2LITTLER}/${DATE1_minus_1b}"
	"${MADIS2LITTLER}/${DATE1}${HH1}"
        "${MADIS2LITTLER}/${DATE1_plus_1b}"
        "${MADIS2LITTLER}/${DATE1_plus_2b}"
	"${MADIS2LITTLER}/${DATE1_plus_3b}"
        # Add more folders as needed
    )

for folder in "${input_folders[@]}"; do
  #echo "Processing folder: $folder"
  find "$folder" -type f -exec cat {} + >> "$output_file"
done

#python environment
source activate base
conda activate xmitgcm

echo "get IMS data"
cd ${OBSDIR}/IMS
ipython get_ims.py ${YY1} ${MM1} ${DD1} ${HH1} > get_ims_${D1}.txt
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi
cp data/ims_${YY1}${MM1}${DD1}${HH1}.txt ${OBSPROC}/test_ims.txt 

echo "get sounding data"
cd ${OBSDIR}/WYO
ipython get_wyo.py ${YY1} ${MM1} ${DD1} ${HH1} > get_wyo_${D1}.txt
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi
cp data_littler/wyo_${YY1}${MM1}${DD1}${HH1}.txt ${OBSPROC}/test_sound.txt

cd ${OBSPROC}

cat test_ims.txt test_sound.txt test_madis.txt > test.txt

cp test_ims.txt ${DA_DATA}/${D1}/littler_ims.txt
cp test_sound.txt ${DA_DATA}/${D1}/littler_sound.txt
cp test_madis.txt ${DA_DATA}/${D1}/littler_madis.txt

YY1=`echo $DATE1 | cut -c1-4`
MM1=`echo $DATE1 | cut -c5-6`
DD1=`echo $DATE1 | cut -c7-8`

YY2=`echo $DATE1_minus_3b | cut -c1-4`
MM2=`echo $DATE1_minus_3b | cut -c5-6`
DD2=`echo $DATE1_minus_3b | cut -c7-8`
HH2=`echo $DATE1_minus_3b | cut -c9-10`

YY3=`echo $DATE1_plus_3b | cut -c1-4`
MM3=`echo $DATE1_plus_3b | cut -c5-6`
DD3=`echo $DATE1_plus_3b | cut -c7-8`
HH3=`echo $DATE1_plus_3b | cut -c9-10`

sed -i "s/time_window_min.*/time_window_min = '${YY2}-${MM2}-${DD2}_${HH2}:00:00',/g" namelist.obsproc
sed -i "s/time_analysis.*/time_analysis = '${YY1}-${MM1}-${DD1}_${HH1}:00:00',/g" namelist.obsproc
sed -i "s/time_window_max.*/time_window_max = '${YY3}-${MM3}-${DD3}_${HH3}:00:00',/g" namelist.obsproc

echo "run obsproc"
./obsproc.exe  &> obsproc_${D1}.txt
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

cp namelist.obsproc ${DA_DATA}

cp obs_gts_${YY1}-${MM1}-${DD1}_${HH1}:00:00.3DVAR ${DA_DATA}/${D1}/

cd ${DADIR}

ln -sf ${OBSPROC}/obs_gts_${YY1}-${MM1}-${DD1}_${HH1}:00:00.3DVAR ob.ascii

echo "run wrfda d01" 

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/shared/miniconda3/lib/

cp fg_d01 fg
cp be.dat_d01 be.dat
cp namelist.input_d01 namelist.input
sed -i "s/time_window_min.*/time_window_min = '${YY2}-${MM2}-${DD2}_${HH2}:00:00',/g" namelist.input
sed -i "s/analysis_date.*/analysis_date = '${YY1}-${MM1}-${DD1}_${HH1}:00:00',/g" namelist.input
sed -i "s/time_window_max.*/time_window_max = '${YY3}-${MM3}-${DD3}_${HH3}:00:00',/g" namelist.input
sbatch --wait run_sbatch.sh
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

cp wrfvar_output ${DA_DATA}/${D1}/wrfvar_output_${D1}_d01
cp wrfvar_output ${WRFDIR}/wrfinput_d01
cp namelist.input ${DA_DATA}/namelist.input_wrfda
cp cost_fn ${DA_DATA}/${D1}/cost_fn_${D1}_d01
cp grad_fn ${DA_DATA}/${D1}/grad_fn_${D1}_d01
cp gts_omb_oma_01 ${DA_DATA}/${D1}/gts_omb_oma_01_${D1}_d01
cp namelist.output.da ${DA_DATA}/${D1}/namelist.output.da_${D1}_d01
cp statistics ${DA_DATA}/${D1}/statistics_${D1}_d01
cp rsl.out.0000 ${DA_DATA}/${D1}/rsl.out.0000_${D1}_d01
cdo -w sub wrfvar_output fg ${DA_DATA}/${D1}/increments_${D1}_d01 > cdo.txt

# update boundary conditions
cd /shared/WRFDA/RUN_ana/update_bc
cp ${WRFDIR}/wrfbdy_d01 .
cp ${DADIR}/wrfvar_output .
./da_update_bc.exe &> update.log
cp wrfbdy_d01 ${DA_DATA}/${D1}/wrfbdy_d01_update
cp wrfbdy_d01 ${WRFDIR}

echo "run wrfda d02" 

cd ${DADIR}
cp fg_d02 fg
cp be.dat_d02 be.dat
cp namelist.input_d02 namelist.input
sed -i "s/time_window_min.*/time_window_min = '${YY2}-${MM2}-${DD2}_${HH2}:00:00',/g" namelist.input
sed -i "s/analysis_date.*/analysis_date = '${YY1}-${MM1}-${DD1}_${HH1}:00:00',/g" namelist.input
sed -i "s/time_window_max.*/time_window_max = '${YY3}-${MM3}-${DD3}_${HH3}:00:00',/g" namelist.input
sbatch --wait run_sbatch.sh
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

cp wrfvar_output ${DA_DATA}/${D1}/wrfvar_output_${D1}_d02
cp wrfvar_output ${WRFDIR}/wrfinput_d02
cp cost_fn ${DA_DATA}/${D1}/cost_fn_${D1}_d02
cp grad_fn ${DA_DATA}/${D1}/grad_fn_${D1}_d02
cp gts_omb_oma_01 ${DA_DATA}/${D1}/gts_omb_oma_01_${D1}_d02
cp namelist.output.da ${DA_DATA}/${D1}/namelist.output.da_${D1}_d02
cp statistics ${DA_DATA}/${D1}/statistics_${D1}_d02
cp rsl.out.0000 ${DA_DATA}/${D1}/rsl.out.0000_${D1}_d02
cdo -w sub wrfvar_output fg ${DA_DATA}/${D1}/increments_${D1}_d02


else

# update boundary conditions
cd /shared/WRFDA/RUN_ana/update_bc
cp ${WRFDIR}/wrfbdy_d01 .
cp ${DADIR}/fg_d01 .
./da_update_bc.exe &> update.log
cp wrfbdy_d01 ${DA_DATA}/${D1}/wrfbdy_d01_update
cp wrfbdy_d01 ${WRFDIR}
cp ${DA_DATA}/${D1}/fg_d01 ${WRFDIR}/wrfinput_d01
cp ${DA_DATA}/${D1}/fg_d02 ${WRFDIR}/wrfinput_d02


fi


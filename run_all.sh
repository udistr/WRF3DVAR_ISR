!/bin/bash
##set -e
## ps aux | grep bash

export WPSDIR=/shared/WRF4.4/WPS
export WRFDIR=/shared/WRF4.4/WRF/run_d
export WRFDATA=/shared/WRF4.4/WRFDATA
export DADIR=/shared/WRFDA/RUN_ana/Jan2020_d
export OBSDIR=/shared/WRFDA/OBS
export OBSPROC=/shared/WRFDA/preproc_obs_udi
export DA_DATA=/shared/WRF4.4/WRF/DA_DATA_d_V4

cd /shared/WRF4.4/run_6H

sdate=20200106
stime=00
edate=20200111
etime=00
loop=0
assim=1

#sdate=$1
#stime=$2
#edate=$3
#etime=$4
#loop=$5

d=`date -u -d "${sdate}T${stime} +7 hour"  +'%Y%m%dT%H'`
enddate=`date -u -d "${edate}T${etime} +7 hour"  +'%Y%m%dT%H'`

echo 
echo "Start date: $d"
echo "End   date: $enddate"

echo "entering loop"
echo 

while [[ "$d" < "$enddate" ]]; do

  start_time=$(date +%s.%N)
  d=`date -u -d "${d} +7 hour"  +'%Y%m%dT%H'`
  d1=`date -u -d "${d} +7 hour + 6 hour"  +'%Y%m%dT%H'`

  echo "-------------------------------"
  echo "Process time step: $d"
  echo "-------------------------------"
  echo 

  DD1=${d:0:8}
  HH1=${d:9:2}
  DD2=${d1:0:8}
  HH2=${d1:9:2}
  
  #echo ${DD1}T${HH1}-${DD2}T${HH2}

  bash get_data.sh $DD1 $HH1 $DD2 $HH2
  RC=$?
  if [ ${RC} -eq 0 ]; then
    bash run_real.sh $DD1 $HH1 $DD2 $HH2
    RC=$?
    if [ ${RC} -eq 0 ]; then
      bash run_wrf3dvar.sh ${DD1} ${HH1} $loop $assim
      RC=$?
      if [ ${RC} -eq 0 ]; then
        bash run_wrf.sh $DD1 $HH1 $DD2 $HH2
        RC=$?
        if [ ${RC} -eq 0 ]; then
          loop=$[${loop} + 1]
          d=${d1}
	else
	  echo "run_wrf.sh failed"
        fi
      else
        echo "bash run_wrf3dvar.sh faild"
      fi
    else
      echo "run_real.sh faild"
    fi
  else
    echo "get_data.sh faild"
  fi
  # Calculate and print the execution time
  end_time=$(date +%s.%N)
  execution_time=$(echo "$end_time - $start_time" | bc)
  printf "Execution time for iteration $i: %.6f seconds\n" $execution_time
  echo
done


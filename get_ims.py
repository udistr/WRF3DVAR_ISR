import json
import requests
import csv
import pandas as pd
from datetime import datetime
import xarray as xr
import numpy as np
from record import Record
import os
from datetime import datetime, timedelta
import sys
import time
# IMS token
headers = {
  'Authorization': 'ApiToken f058958a-d8bd-47cc-95d7-7ecf98610e47'
}

# get stations metadata
url = "https://api.ims.gov.il/v1/Envista/stations"
response = requests.request("GET", url, headers=headers)
mdata= json.loads(response.text.encode('utf8'))

# Write metadata to csv
keys = mdata[0].keys()
with open('stations.csv', 'w', newline='')  as output_file:
    dict_writer = csv.DictWriter(output_file, keys)
    dict_writer.writeheader()
    dict_writer.writerows(mdata)

# convert metadata to dataframe and chose only IMS maintained and active stations
mdataframe=pd.DataFrame.from_dict(mdata)
mdataframe_ims=mdataframe[(mdataframe['owner']=="ims")&(mdataframe['active']==True)].rename_axis('index').reset_index(drop=True)

ds=pd.read_excel("meta data archive ims 1_2.xlsx")
# convert metadata to dataframe and chose only IMS maintained and active stations
mdataframe_hgt=pd.DataFrame.from_dict(ds)

UNDEFINED_VALUE = -888888

def ims2littler(year,month,day,hour,dirout="./"):

  if not os.path.exists(dirout):
    os.makedirs(dirout)
  output_file_path = dirout+'/ims_'+str(year)+str(month).zfill(2)+str(day).zfill(2)+str(hour).zfill(2)+'.txt'
  
  H=str(hour).zfill(2)+"00"
  
  if H == "0000":
    tmp=datetime(year,month,day,hour) - timedelta(days=1)
    year=tmp.year
    month=tmp.month
    day=tmp.day
    hour=tmp.hour
  
  STR=str(year)+"/"+str(month).zfill(2)+"/"+str(day).zfill(2)
  a=[]
  for station in range(0,len(mdataframe_ims)):#len(mdataframe_ims)
  
   stationId=mdataframe_ims['stationId'][station]
   stationNM=mdataframe_ims['name'][station]
   stationLAT=mdataframe_ims['location'][station]['latitude']
   stationLON=mdataframe_ims['location'][station]['longitude']
   stationHGT=mdataframe_hgt[mdataframe_hgt.reset_index()["index"].isin([stationId])].iloc[0,8]
   print(str(station)+'  '+str(stationId)+'  '+stationNM)
   if stationNM[-3:]!="_1m": 
    # needed to get the right channel wich is different from station to station
    monitors = pd.DataFrame.from_dict(mdataframe_ims['monitors'][station])

    url="https://api.ims.gov.il/v1/envista/stations/"+str(stationId)+"/data/daily/"+STR
    #try:
    #  data = json.loads(response.text.encode('utf8'))
    #  print("yes")
    #except:
    #  print("no")
    #  data=[]

    max_attempts = 12
    attempt = 0
    response = None

    while attempt < max_attempts:
        response = requests.request("GET", url, headers=headers)
        try:
          data = json.loads(response.text.encode('utf8'))
          print("Successful response received.")
          break
        except:
          data=[]
        attempt += 1
        time.sleep(2)  # Wait for 2 seconds before retrying
        print(str(attempt))
 
    if data:
      L=len(data['data'])
      st=[dict() for x in range(L)]
      for i in range(L):
        DATE=datetime.strptime(data['data'][i]['datetime'][0:-6], "%Y-%m-%dT%H:%M:%S")
        Time=str(DATE.hour).zfill(2)+str(DATE.minute).zfill(2)
        if Time == H:
          rtime=str(DATE.hour).zfill(2)+str(DATE.minute).zfill(2)
          st=pd.DataFrame.from_dict(data['data'][i]['channels'])
          temp=UNDEFINED_VALUE
          sknt=UNDEFINED_VALUE
          drct=UNDEFINED_VALUE
          relh=UNDEFINED_VALUE
          if np.any(st["name"].isin(["TD"])):
            temp=st[st["name"].isin(["TD"])]["value"].values[0] + 273.15
          if np.any(st["name"].isin(["WS"])):
            sknt=st[st["name"].isin(["WS"])]["value"].values[0]
          if np.any(st["name"].isin(["WD"])): 
            drct=st[st["name"].isin(["WD"])]["value"].values[0]
          if np.any(st["name"].isin(["RH"])):
            relh=st[st["name"].isin(["RH"])]["value"].values[0]
          
          print(str(temp)+" "+str(sknt)+" "+str(drct)+" "+str(relh))
          
          x=Record(stationNM,stationLAT,stationLON,stationHGT,datetime.strptime(data['data'][i]['datetime'][0:-6], "%Y-%m-%dT%H:%M:%S"))
          x.__setitem__('temperature',temp)
          x.__setitem__('dewpoint',UNDEFINED_VALUE)
          x.__setitem__('wind_speed',sknt)
          x.__setitem__('wind_direction',drct)
          x.__setitem__('wind_u',UNDEFINED_VALUE)
          x.__setitem__('wind_v',UNDEFINED_VALUE)
          x.__setitem__('humidity',relh)
          x.__setitem__('thickness',UNDEFINED_VALUE)

          a.append(x.message_header('FM-12 SYNOP'))
          a.append(x.data_record())
          a.append(x.data_closing_line())
          a.append(x.end_of_message_line())

  with open(output_file_path, 'w') as output_file:
      for line in a:
        output_file.write(f"{line}\n")
          
year=2020
month=1
day=9
hour=0

year = int(sys.argv[1])
month = int(sys.argv[2])
day = int(sys.argv[3])
hour = int(sys.argv[4])

print(str(year))
print(str(month))
print(str(day))
print(str(hour))

ims2littler(year,month,day,hour,"data")


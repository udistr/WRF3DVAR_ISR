import requests
from bs4 import BeautifulSoup
import datetime

def download_sounding_data(region, year, month, day, hour, station):
    url = f"http://weather.uwyo.edu/cgi-bin/sounding?region={region}&TYPE=TEXT%3ALIST&YEAR={year}&MONTH={month}&FROM={day}{hour}&TO={day}{hour}&STNM={station}"
    response = requests.get(url)
    
    if response.status_code == 200:
        return response.text
    else:
        raise Exception(f"Failed to download data: {response.status_code}")

def parse_sounding_data(html_content):
    soup = BeautifulSoup(html_content, 'html.parser')
    title_tag = soup.find('h2')
    data_tag = soup.find_all('pre')[0]
    att_tag = soup.find_all('pre')[1]
    if data_tag:
        return title_tag.get_text(), data_tag.get_text(), att_tag.get_text()
    else:
        raise Exception("Sounding data not found in the HTML content")

def is_numeric(line):
    try:
        float(line.split()[0])
        return True
    except ValueError:
        return False

def convert_to_little_r(data, att):
    lines = data.strip().split('\n')
    lines_att = att.strip().split('\n')

    for line in lines_att:
        if "Station latitude" in line:
            # Extract the value after the colon and strip any extra whitespace
            station_latitude = float(line.split(":")[1].strip())
            print(f"Station latitude: {station_latitude}")

        if "Station longitude" in line:
            # Extract the value after the colon and strip any extra whitespace
            station_longitude = float(line.split(":")[1].strip())
            print(f"Station longitude: {station_longitude}")

        if "Observation time" in line:
            # Extract the value after the colon and strip any extra whitespace
            observation_time_str = line.split(":")[1].strip()
            print(f"Observation time: {observation_time_str}")

        if "Station number" in line:
            # Extract the value after the colon and strip any extra whitespace
            sname = line.split(":")[1].strip()
            print(f"Station number: {sname}")

        if "Station elevation" in line:
            # Extract the value after the colon and strip any extra whitespace
            level = float(line.split(":")[1].strip())
            print(f"Station height: {level}")


    # Find the first numeric line to start data parsing
    data_lines = [line for line in lines if is_numeric(line)]

    observation_time = datetime.datetime.strptime(observation_time_str, '%y%m%d/%H%M')

    little_r_data = []
    i=0
    for line in data_lines:
        fields = line.split()
        if len(fields) < 11:
            continue
        UNDEFINED_VALUE = -888888

        pres = float(fields[0])
        hght = float(fields[1])
        temp = float(fields[2]) + 273.15  # Convert to Kelvin
        dwpt = float(fields[3]) + 273.15  # Convert to Kelvin
        relh = float(fields[4])
        mixr = float(fields[5])
        drct = float(fields[6])
        sknt = float(fields[7])
        thta = float(fields[8])
        thte = float(fields[9])
        thtv = float(fields[10])

        x=Record(sname,station_latitude,station_longitude,hght,observation_time)

        if i==0:
          a=[x.message_header()]

        x.__setitem__('temperature',temp)
        x.__setitem__('dewpoint',dwpt)
        x.__setitem__('wind_speed',sknt)
        x.__setitem__('wind_direction',drct)
        x.__setitem__('wind_u',UNDEFINED_VALUE)
        x.__setitem__('wind_v',UNDEFINED_VALUE)
        x.__setitem__('humidity',relh)
        x.__setitem__('thickness',UNDEFINED_VALUE)
        
        a.append(x.data_record())
        i=i+1
       
    a.append(x.data_closing_line())
    a.append(x.end_of_message_line())
      
    out='\n'.join(a)

    little_r_data.append(out)

    return little_r_data

def main():
    region = "africa"
    year = "2020"
    month = "01"
    day = "09"
    hour = "00"
    station = "40179"

    html_content = download_sounding_data(region, year, month, day, hour, station)
    header,sounding_data,att = parse_sounding_data(html_content)
    little_r_format = convert_to_little_r(sounding_data,att)
    
    output_file_path = 'sounding_'+station+'_'+year+month+day+hour+'.txt'
    with open(output_file_path, 'w') as output_file:
        for line in little_r_format:
          output_file.write(f"{line}\n")
        #output_file.write(little_r_format)


    region = "africa"
    year = "2020"
    month = "01"
    day = "09"
    hour = "00"
    station = "17351"

    html_content = download_sounding_data(region, year, month, day, hour, station)
    header,sounding_data,att = parse_sounding_data(html_content)
    little_r_format = convert_to_little_r(sounding_data,att)

    with open(output_file_path, 'a') as output_file:
        for line in little_r_format:
          output_file.write(f"{line}\n")
    
    print(f"Conversion completed. The output is saved as {output_file_path}.")

if __name__ == "__main__":
    main()


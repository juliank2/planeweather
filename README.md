# planeweather
## objective
see https://gist.githubusercontent.com/mandarjog/2bba8a7e2540fbd77bb4/raw/7376ec04653cb912caf207e6e167e83d9bc9e2f9/gistfile1.txt

## example calls
* http://planeweather.herokuapp.com/resolve/rdu
* http://planeweather.herokuapp.com/forecast/rdu/yyv/2015-03-22T8:27:00/900/2

## installation + setup
to install dependencies
```
bundle install
```
or
```
bundle install --path vendor/bundle
```

to initialise the database for first time use run the custom rake task
```
rake setup
```

## to run the tests
```
rake test
```

## airport location data
airport location data is imported from a csv file.
the current implementation uses data from http://openflights.org/data.html.

relevant files
* other/airport-data.csv
* app/model/airport_data.rb
relevant rake task: importAirportData

### to update the data
1. download a new airport.dat from http://openflights.org/data.html.
2. modify it with a spreadsheet application or csv command-line utility like csvkit so that only the columns "IATA/FAA", "Latitude" and "Longitude" remain
3. save it to "other/airport-data.csv"
4. execute "rake importAirportData"

### technical notes about the import
* depending on the requirements, imports might only be necessary infrequently.
* the data size is small enough that an import should not take more than 20 seconds.
considering that, and that updating with handling deleted items is not trivial, and that dropping and recreating tables seems to not be easily possible without duplicating the table schema somewhere, the table is emptied before import.
the table does not have an auto_increment :id column that would continue to grow to its limit afterwards.

# additional libraries used
* forecast-api for access to forecast.io weather data
* geo-distance for the vincenty distance calculation

## choice of deployment target
i decided to use heroku for deployment because of the possible time savings. ec2 could be nicer but there is more complexity involved because i do not have an account or a running instance yet.
heroku requires a postgresql database and the front-end code has to be put into the "/public" directory.

## tips for deployment on heroku
if the [heroku toolbelt](https://toolbelt.heroku.com/) is installed then the "heroku" command can be used from inside the project directory.

### to update the files on heroku
requires a [heroku remote](https://devcenter.heroku.com/articles/git#creating-a-heroku-remote) in the local git configuration.
```
git push heroku master
```

### to run rake tasks
```
heroku run rake {task name}
```

# rest-api documentation
all responses have the content-type application/json

## get /resolve/{iata-faa-code}
### description
translate a given iata/faa airport code to its corresponding latitude and longitude coordinates.
### parameters
iata-faa-code: a lowercase string
### example
#### request
```
/resolve/rdu
```
#### response
```
{
  "location":  [33.942536, -118.408075]
}
```

## get /airport-coordinates/{longitude},{latitude}
### description
tries to parse the given coordinates
### parameters
coordinates: a longitude number followed by a comma and a latitude number
### example
#### request
```
/airport-coordinates/2.45 ,   -1.23
```
#### response
```
{
  "location":  [2.45, -1.23]
}
```

## get /forecast/{source}/{destination}/{departureTime}/{speed}/{interval}
### description
retrieve forecast data for a flight
### parameters
* source: [number, number] | [latitude, longitude] | iata-faa-code
* destination: same as source
* departureTime: ISO8601 local time at departure eg. 2015-03-01T12:00:00
* speed: flight speed in miles per hour
* interval: flight time duration between weather reports in hours
### response
```
{
  "forecast": [dataForOneForecast, ...]
}
```
#### dataForOneForecast
```
{
  humidity: humidity at time/location (between 0 and 1)
  incomplete: flag indicating whether all data could be found
  location: The location of the forecast (lat/lng pair)
  location_rnd: The location rounded to avoid excess api calls
  temperature: temperature at time/location in degrees Farenheit
  time: Time (unix UTC timestamp) forecasted
  time_rnd: The time rounded to avoid excess api calls
  wind_speed: Wind speed at time/location in miles per hour
}
```
### example
#### request
```
get /forecast/lax/lhr/2015-03-22T8:27:00/500/2
```
or
```
get /forecast/33.942536,-118.408075/lhr/2015-03-22T8:27:00/500/2
```
#### response
```
{
  "forecast": [
    {
       "humidity": 0.64,
       "incomplete": false,
       "location": [33.942536, -118.408075],
       "location_rnd": [33.94, -118.41],
       "temperature": 60.65,
       "time": 1425182400,
       "time_offset": -8,
       "time_rnd": 1425182400,
       "wind_speed": 7.14
    },
    {
       "humidity": 0.86,
       "incomplete": false,
       "location": [61.34491415956866, -64.96399860822545],
       "location_rnd": [61.34, -64.96],
       "temperature": -8.52,
       "time": 1425214800,
       "time_offset": -5,
       "time_rnd": 1425214800,
       "wind_speed": 7.19
    }
  ]
}
```

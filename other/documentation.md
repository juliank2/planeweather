# routes
all responses have the content-type application/json

## get /airport-coordinates/{iata-code}
### description
translate a given iata airport code to its corresponding latitude and longitude coordinates
### parameters
iata-code: a lowercase string
### response
example:
    {
      "location":  [33.942536, -118.408075]
    }

## get /forecast/{source}/{destination}/{departureTime}/{speed}/{interval}
### description
retrieve forecast data for a flight
### parameters
* source: [number, number] | [latitude, longitude]
* destination: same as source
* departureTime: number | posix-time
* speed: flight speed in miles per hour
* interval: flight time duration between weather reports in hours
### response
{
  "forecast": dataForOneForecast
}
#### dataForOneForecast
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
### example
#### request
get /forecast/lax/lhr/1425207600/500/2
#### response
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
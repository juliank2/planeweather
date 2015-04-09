# planeweather
## objective
see https://gist.githubusercontent.com/mandarjog/2bba8a7e2540fbd77bb4/raw/7376ec04653cb912caf207e6e167e83d9bc9e2f9/gistfile1.txt


## airport data
* relevant files
  * other/airport-data.csv
  * app/model/airport_data.rb
* relevant rake task: updateAirportData

### to update the data
the current implementation uses airport coordinates from http://openflights.org/data.html.
- download a new airport.dat
- modify it with a spreadsheet applicationcommand-line utility like csvkit so only the columns "IATA/FAA", "Latitude" and "Longitude"
- execute "rake updateAirportData"

- update the file "other/airport-data.csv"
heroku run rake updateAirportData

## example calls
* http://planeweather.herokuapp.com/resolve/rdu
* http://planeweather.herokuapp.com/forecast/rdu/yyv/2015-03-22T8:27:00/900/2

## installation + setup
to initialising the database for a rails environment use other/setup.sh.
for example
    ./other/setup.sh development

## to run the tests
rake test

# howto ... on heroku
if the (heroku-toolbelt) is installed the heroku command can be used from inside the project directory.

## update the project source
    heroku push

## run rake tasks
    heroku run rake {task name}

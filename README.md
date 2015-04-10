# planeweather
## objective
see https://gist.githubusercontent.com/mandarjog/2bba8a7e2540fbd77bb4/raw/7376ec04653cb912caf207e6e167e83d9bc9e2f9/gistfile1.txt

## example calls
* http://planeweather.herokuapp.com/resolve/rdu
* http://planeweather.herokuapp.com/forecast/rdu/yyv/2015-03-22T8:27:00/900/2

## installation + setup
to initialise the database for first time use run the custom rake task
    bundle exec rake setup

## to run the tests
rake test

## airport location data
airport location data is imported from a csv file.
the current implementation uses data from http://openflights.org/data.html.

relevant files
  * other/airport-data.csv
  * app/model/airport_data.rb
relevant rake task: importAirportData

### to update the data
- download a new airport.dat
- modify it with a spreadsheet application or csv command-line utility like csvkit so that only the columns "IATA/FAA", "Latitude" and "Longitude" remain
- save it to "other/airport-data.csv"
- execute "rake importAirportData"

### technical details about the import
* depending on the requirements, imports might only be necessary infrequently.
* the data size is small enough that an import should not take more than 20 seconds.
considering that, and that updating with handling deleted items is not trivial, and that dropping and recreating tables seems to not be easily possible unless manually duplicating the table schema somewhere, the table is emptied before import.
the table does not have an auto_increment :id column that would continue to grow to its limit afterwards.

# additional libraries used
* forecast-api for access to forecast.io weather data
* geokit-rails for non-eucledian geometry calculations

## choice of deployment target
i decided to use heroku for deployment because of the possible time savings. ec2 could be nicer, but there is more complexity involved given the fact that i do not have an account or a running instance yet.
heroku requires a postgresql database and the front-end code has to be put into the "/public" directory.

## tips for deployment on heroku
if the [heroku toolbelt](https://toolbelt.heroku.com/) is installed then the "heroku" command can be used from inside the project directory.

### to update the files on heroku
    heroku push

### to run rake tasks
    heroku run rake {task name}

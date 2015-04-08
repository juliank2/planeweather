# objective
see https://gist.githubusercontent.com/mandarjog/2bba8a7e2540fbd77bb4/raw/7376ec04653cb912caf207e6e167e83d9bc9e2f9/gistfile1.txt

# notes
* i will use the google maps api key from the example front-end
* i decided to use heroku for deployment because of the time savings. ec2 would be nicer, but there is more complexity involved given the fact that i do not have an account and running instance.
* downsides of heroku are that it requires a postgresql database and that i have to put the example front-end into the rails "/public" directory, which makes the project structure less obvious or requires copying the frontend code

# tasks
* create a forecast.io account
* get a list of iata/faa airport codes and their coordinates
* create a new rails project
* initialise a postgresql database. needed for deployment on heroku
* prepare some documentation
* create routes in rails
* open the rails project controller file and test a basic response
* make a test deployment to heroku

# resources
* forecast.io api key: 7f346b42fc56221786b7a43c97b7e124
* google maps api key:
* source of airport data: http://openflights.org/data.html

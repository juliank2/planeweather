#!/bin/sh
# tasks that are necessary to be executed for each environment to setup the database the first time

if [ $# -eq 0 ]
then
    echo usage ./setup.sh rails-environment-name
    exit
fi

export RAILS_ENV=$1
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake updateAirportData

class MainController < ApplicationController
  require 'forecast_io'
  protect_from_forgery with: :exception
  #http_basic_authenticate_with name: "planeweather", password: "plotwatt"

  def airportCoordinates code=params[:airportCode]
    if code =~ /[a-z]{3,3}/i
      locationData = AirportLocation.find_by code: code.downcase
      if locationData
        render json: {location: [locationData.latitude, locationData.longitude]}
      else
        render json: {location: nil}
      end
    else
      # this branch is to support comma separated latitude longitude coordinates passthrough/json-conversion
      code = code.split ','
      # ruby returns 0.0 for values that could not be parsed.
      # the alternative would be checking with regexp for integers and floats.
      location = code.length == 2 ? code.map {|e| e.to_f } : nil
      render json: {location: location}
    end
  end

  def forecast
    source = params[:source]
    destination = params[:destination]
    speed = params[:speed]
    interval = params[:interval]
    forecast = ForecastIO.forecast(37.8267, -122.423, time: Time.new(2013, 3, 11).to_i)
    render json: forecast
  end

  private

  ForecastIO.api_key = '7f346b42fc56221786b7a43c97b7e124'

  # number number -> number
  def latLongToDistance lat, long
  end
end

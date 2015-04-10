class MainController < ApplicationController
  require 'forecast_io'
  require 'geokit'
  protect_from_forgery with: :exception
  #http_basic_authenticate_with name: "planeweather", password: "plotwatt"

  # string -> [number, number]
  def iataFaaCodeToCoordinates code
    result = AirportLocation.find_by iata_faa_code: code.downcase
    if result then [result.latitude, result.longitude] else false end
  end

  # string -> boolean
  def iataFaaCode? a
    a =~ /[a-z]{3,3}/i
  end

  def latLongString? a
    a =~ /\d+(\.\d+)?.*,.*\d+(\.\d+)?/
  end

  def parseLatLongString a
    # .to_f returns 0.0 for values that could not be parsed.
    a.split(',').map {|e| e.to_f}
  end

  # string -> false:notFound/nil:argumentError
  def getCoordinates codeOrCoordinates
    if iataFaaCode? codeOrCoordinates
      iataFaaCodeToCoordinates codeOrCoordinates
    elsif latLongString? codeOrCoordinates
      parseLatLongString codeOrCoordinates
    end
  end

  def resolve codeOrCoordinates=params[:codeOrCoordinates]
    coordinates = getCoordinates codeOrCoordinates
    if coordinates.nil?
      unprocessable_entity
    else
      render json: coordinates ? {location: coordinates} : {}
    end
  end

  def forecast
    # prepare params
    source = getCoordinates params[:source]
    destination = getCoordinates params[:destination]
    departureTime = DateTime.parse params[:departureTime]
    speed = params[:speed].to_f
    hourInterval = params[:interval].to_f
    unless source and destination and speed and hourInterval
      unprocessable_entity
      return
    end
    # prepare variables
    secondsPerHour = 3600
    # mph-rate / hour-interval
    intervalDistance = speed / hourInterval
    # (miles / mph-rate) * seconds-per-hour
    intervalTravelTimeSeconds = (intervalDistance / speed) * secondsPerHour
    source = Geokit::LatLng.new source[0], source[1]
    destination = Geokit::LatLng.new destination[0], destination[1]
    fullDistance = source.distance_to destination
    travelTimeSeconds = (fullDistance / speed) * secondsPerHour
    intervalCount = (fullDistance / intervalDistance).floor
    waypoint = source
    heading = source.heading_to(destination)
    # collect waypoints
    waypoints = (0..intervalCount).map {
      waypoint = waypoint.endpoint(heading, intervalDistance, units: :miles)
      # the bearing changes while travelling
      heading = waypoint.heading_to(destination)
      waypoint
    }
    waypoints = [source] + waypoints + [destination]
=begin
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
=end

    forecasts = []
    # retrieve and transform weather data
    #forecasts = waypoints.map {|e|
    #  ForecastIO.forecast(37.8267, -122.423, time: Time.new(2013, 3, 11).to_i)
    #}
    render json: {waypoints: waypoints, forecasts: forecasts, source: source, destination: destination, travelTimeHours: travelTimeSeconds / 60 / 60}
  rescue ArgumentError
    # the exception likely happens because of a date that could not be parsed
    unprocessable_entity
  end

  private

  ForecastIO.api_key = '7f346b42fc56221786b7a43c97b7e124'

  def unprocessable_entity
    render nothing: true, status: :unprocessable_entity
  end

  # number number -> number
  def latLongToDistance lat, long
  end
end

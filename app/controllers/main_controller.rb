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

  # Geokit::LatLng Geokit::LatLng integer number -> [[number, number] ...]
  def getWaypoints source, destination, intervalCount, intervalDistance
    waypoint = source
    heading = source.heading_to(destination)
    waypoints = (0..intervalCount).map {
      waypoint = waypoint.endpoint(heading, intervalDistance, units: :miles)
      # the bearing/heading changes while travelling
      heading = waypoint.heading_to(destination)
      waypoint.to_a
    }
    [source.to_a] + waypoints + [destination.to_a]
  end

  # hash -> [source, destination, speed, hourInterval]/false
  # parse and validate params. false on failure
  def forecastPrepareInput params
    source = getCoordinates params[:source]
    destination = getCoordinates params[:destination]
    departureTime = DateTime.parse params[:departureTime]
    speed = params[:speed].to_f
    hourInterval = params[:interval].to_f
    if source and destination and speed and hourInterval
      [source, destination, departureTime, speed, hourInterval]
    else false end
  rescue ArgumentError
    # the exception likely happens because of a date that could not be parsed
    false
  end

  # Hash Array -> Hash
  # Assumes that the location data in the result data should be a location exactly on the path of travel.
  def transformForecastIoResult a, waypointLocation
    currently = a["currently"]
    {
      humidity: currently["humidity"],
      incomplete: false,
      location: [waypointLocation[0], waypointLocation[1]],
      location_rnd: [waypointLocation[0].round, waypointLocation[1].round],
      temperature: currently["temperature"],
      time: currently && currently["time"],
      time_offset: a["offset"],
      # TODO: what does time_rnd stand for?
      time_rnd: 1425182400,
      wind_speed: currently && currently["windspeed"]
    }
  end

  # [latitude, longitude], integer -> Hash
  def getForecastIoResult coordinates, unixTime
    # time must be an integer not a float or else otherwise the api call returns nil
    forecastIoResult = ForecastIO.forecast coordinates[0], coordinates[1], time: unixTime.to_i,
                                           params: {exclude: 'hourly,daily,flags'}
    return forecastIoResult unless forecastIoResult
    transformForecastIoResult forecastIoResult, coordinates
  end

  # [[number, number], ...] DateTime number number -> [Hash, ...]
  def getWaypointWeatherForecasts waypoints, departureTime, travelTimeSeconds, intervalTravelTimeSeconds
    time = departureTime.to_i
    arrivalTimeSeconds = time + travelTimeSeconds
    # the intervals between waypoints are counted from zero.
    # the time interval between the second last and last waypoint may be shorter.
    destinationWaypoint = waypoints.pop
    result = waypoints.map {|e|
      time = time + intervalTravelTimeSeconds
      getForecastIoResult(e, time)
    }
    result << getForecastIoResult(destinationWaypoint, arrivalTimeSeconds)
  end

  def forecast
    preparedParams = forecastPrepareInput params
    if preparedParams
      source, destination, departureTime, speed, hourInterval = preparedParams
    else
      unprocessable_entity
      return
    end
    # prepare variables
    secondsPerHour = 3600
    ## mph-rate / hour-interval
    intervalDistance = speed / hourInterval
    ## (miles / mph-rate) * seconds-per-hour
    intervalTravelTimeSeconds = (intervalDistance / speed) * secondsPerHour
    source = Geokit::LatLng.new source[0], source[1]
    destination = Geokit::LatLng.new destination[0], destination[1]
    fullDistance = source.distance_to destination
    travelTimeSeconds = (fullDistance / speed) * secondsPerHour
    intervalCount = (fullDistance / intervalDistance).floor
    # get all points on the way including start and end
    waypoints = getWaypoints source, destination, intervalCount, intervalDistance
    forecastData = getWaypointWeatherForecasts waypoints, departureTime, travelTimeSeconds, intervalTravelTimeSeconds
    render json: { forecast: forecastData }
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

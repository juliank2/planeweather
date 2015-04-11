class MainController < ApplicationController
  require 'forecast_io'
  require 'geo-distance'
  protect_from_forgery with: :exception
  #http_basic_authenticate_with name: 'planeweather', password: 'pw'

  def resolve codeOrCoordinates=params[:codeOrCoordinates]
    coordinates = getCoordinates codeOrCoordinates
    if coordinates.nil?
      unprocessable_entity
    else
      render json: coordinates ? {location: coordinates} : {}
    end
  end

  def forecast
    preparedParams = forecastPrepareInput params
    if preparedParams
      origin, destination, departureTime, speed, hourInterval = preparedParams
    else
      unprocessable_entity
      return
    end
    # prepare variables
    secondsPerHour = 3600
    intervalDistance = speed * hourInterval
    ## (miles / mph-rate) * seconds-per-hour
    intervalTravelTimeSeconds = (intervalDistance / speed) * secondsPerHour
    fullDistance = GeoDistance::Vincenty.geo_distance origin[0], origin[1], destination[0], destination[1]
    fullDistance = fullDistance.to_miles.miles
    travelTimeSeconds = (fullDistance / speed) * secondsPerHour
    # get all points on the way including start and end
    waypoints = getWaypoints origin, destination, intervalDistance, fullDistance
    forecastData = getWaypointWeatherForecasts waypoints, departureTime, travelTimeSeconds, intervalTravelTimeSeconds
    render json: { forecast: forecastData }
  end

  # the private methods should probably be moved into a module so they can be tested separately
  private

  ForecastIO.api_key = '7f346b42fc56221786b7a43c97b7e124'

  # respond with a 422 http error
  def unprocessable_entity
    render nothing: true, status: :unprocessable_entity
  end

  # string -> [number, number]
  def iataFaaCodeToCoordinates code
    result = AirportLocation.find_by iata_faa_code: code.downcase
    if result then [result.latitude, result.longitude] else false end
  end

  # string -> boolean
  def iataFaaCode? a
    a =~ /[a-z]{3,3}/i
  end

  # string -> boolean
  def latLongString? a
    a =~ /-{0,1}\d+(\.\d+)?[^,]*,[^,]*\d+(\.\d+)?/
  end

  # string -> [number, number]
  def parseLatLongString a
    # to_f returns 0.0 for values that could not be parsed.
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

  # number -> number
  def degreesToRadians(a)
    a * Math::PI / 180
  end

  # number -> number
  def radiansToDegrees(a)
    a * 180 / Math::PI
  end

  # number number number number float -> [number:latitude, number:longitude]
  # all latitude/longitude values in degrees.
  def intermediatePoint(lat1, lng1, lat2, lng2, f)
    lat1 = degreesToRadians(lat1)
    lng1 = degreesToRadians(lng1)
    lat2 = degreesToRadians(lat2)
    lng2 = degreesToRadians(lng2)
    d = 2 * Math.asin(
          Math.sqrt((Math.sin((lat1 - lat2) / 2))**2 +
                    Math.cos(lat1) * Math.cos(lat2) *
                    Math.sin((lng1-lng2) / 2)**2))
    a = Math.sin((1 - f) * d) / Math.sin(d)
    b = Math.sin(f * d) / Math.sin(d)
    x = a * Math.cos(lat1) * Math.cos(lng1) + b * Math.cos(lat2) * Math.cos(lng2)
    y = a * Math.cos(lat1) * Math.sin(lng1) + b * Math.cos(lat2) * Math.sin(lng2)
    z = a * Math.sin(lat1) + b * Math.sin(lat2)
    lat = Math.atan2(z, Math.sqrt(x**2 + y**2))
    lng = Math.atan2(y, x)
    [radiansToDegrees(lat), radiansToDegrees(lng)]
  end

  # Array Array integer number -> [[number, number] ...]
  # creates an array of [latitude, longitude] coordinates including
  # origin and destination.
  def getWaypoints origin, destination, intervalDistance, fullDistance
    o1 = origin[0]
    o2 = origin[1]
    d1 = destination[0]
    d2 = destination[1]
    fullDistanceFactor = 1 / fullDistance
    waypoints = (0...fullDistance).step(intervalDistance).map {|coveredDistance|
      fraction = fullDistanceFactor * coveredDistance
      intermediatePoint(o1, o2, d1, d2, fraction)
    }
    [origin] + waypoints + [destination]
  end

  # hash -> [origin, destination, speed, hourInterval]/false
  # parse and validate params. false on failure.
  def forecastPrepareInput params
    origin = getCoordinates params[:origin]
    destination = getCoordinates params[:destination]
    departureTime = DateTime.parse params[:departureTime]
    speed = params[:speed].to_f
    hourInterval = params[:interval].to_f
    return false if hourInterval <= 0
    return false if speed <= 0
    if origin and destination and speed and hourInterval
      [origin, destination, departureTime, speed, hourInterval]
    else false end
  rescue ArgumentError
    # the exception usually happens because of a date that could not be parsed
    false
  end

  # Hash Array -> Hash
  # assumes that the location data in the result should be a location exactly on the path of travel.
  # fields with missing values are excluded.
  def transformForecastIoResult a, waypointLocation
    result = {
      location: [waypointLocation[0], waypointLocation[1]],
      location_rnd: [waypointLocation[0].round(2), waypointLocation[1].round(2)],
      incomplete: false
    }
    currently = a['currently']
    if currently
      time = currently['time']
      keys = [:humidity, :temperature, :time, :time_offset, :time_rnd, :wind_speed]
      values =
        [ currently['humidity'], currently['temperature'], time,
          a['offset'], time && time.round, currently['windSpeed']
        ]
      keys.each_with_index {|key, index|
        value = values[index]
        if value then result[key] = value else result[:incomplete] = true end
      }
    else
      result[:incomplete] = true
    end
    result
  end

  # [latitude, longitude], integer -> Hash
  def getForecastIoResult coordinates, unixTime
    # time must be an integer not a float or else otherwise the api call returns nil
    unixTime = unixTime.to_i
    forecastIoResult = Rails.cache.fetch("#{coordinates.to_s}/#{unixTime.to_s}", expires_in: 1.hours) {
      ForecastIO.forecast coordinates[0], coordinates[1], time: unixTime,
                          params: {exclude: 'hourly,daily,flags'}
    }
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
end

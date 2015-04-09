require 'test_helper'
require 'rake'

class MainControllerTest < ActionController::TestCase

  test "resolve iata airport codes" do
    get :airportCoordinates, {'airportCode' => 'aaa'}
    assert_response :success
    response = ActiveSupport::JSON.decode @response.body
    assert_instance_of Array, response["location"]
    assert_equal [0, 1], response["location"]
    get :airportCoordinates, {'airportCode' => '---'}
    assert_response :success
    response = ActiveSupport::JSON.decode @response.body
    assert response["location"].nil?
  end

  test "resolve coordinates" do
    get :airportCoordinates, {'airportCode' => '1, 1'}
    assert_response :success
    response = ActiveSupport::JSON.decode @response.body
    assert_instance_of Array, response["location"]
    assert_equal [1, 1], response["location"]
  end

  test "route to /resolve" do
    assert_routing(
      { method: 'get', path: '/resolve/rdu' },
      { controller: "main", action: "airportCoordinates", airportCode: "rdu" })
  end

  test "route to /forecast" do
    assert_routing(
      { method: 'get', path: '/forecast/rdu/yyv/2015-03-22T8:27:00/900/2' },
      { controller: "main", action: "forecast", source: "rdu", destination: "yyv",
        departureTime: "2015-03-22T8:27:00", speed: "900", interval: "2" })
  end
end

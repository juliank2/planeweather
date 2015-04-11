require 'test_helper'
require 'rake'

class MainControllerTest < ActionController::TestCase
  test "resolve iata airport codes" do
    get :resolve, {'codeOrCoordinates' => 'aaa'}
    assert_response :success
    response = ActiveSupport::JSON.decode @response.body
    assert_instance_of Hash, response
    assert_instance_of Array, response['location']
    assert_equal [0, 1], response['location']
    get :resolve, {'codeOrCoordinates' => 'ccc'}
    assert_response :success
    response = ActiveSupport::JSON.decode @response.body
    assert response["location"].nil?
  end

  test "resolve coordinates" do
    get :resolve, {'codeOrCoordinates' => ' 1.12312  , -1.123123  '}
    assert_response :success
    response = ActiveSupport::JSON.decode @response.body
    assert_instance_of Hash, response
    assert_instance_of Array, response['location']
    assert_equal [1.12312, -1.123123], response['location']
    get :resolve, {'codeOrCoordinates' => '1,,23'}
    assert_response :unprocessable_entity
    get :resolve, {'codeOrCoordinates' => '1.23'}
    assert_response :unprocessable_entity
  end

  test "forecast" do
    get :forecast, { origin: "rdu", destination: "pvg",
                    departureTime: "2015-03-22T8:27:00", speed: "300", interval: "2" }
    assert_response :success
    response = ActiveSupport::JSON.decode @response.body
  end

  test "route to resolve" do
    assert_routing(
      { method: 'get', path: '/resolve/rdu' },
      { controller: "main", action: "resolve", codeOrCoordinates: "rdu" })
  end

  test "route to forecast" do
    assert_routing(
      { method: 'get', path: '/forecast/rdu/pvg/2015-03-22T8:27:00/500/1' },
      { controller: "main", action: "forecast", origin: "rdu", destination: "pvg",
        departureTime: "2015-03-22T8:27:00", speed: "500", interval: "1" })
  end
end

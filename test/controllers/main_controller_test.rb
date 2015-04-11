require 'test_helper'
require 'rake'

class MainControllerTest < ActionController::TestCase
  test 'resolve iata airport codes' do
    get :resolve, {'codeOrCoordinates' => 'aaa'}
    assert_response :success
    response = ActiveSupport::JSON.decode @response.body
    assert_instance_of Hash, response
    assert_instance_of Array, response['location']
    assert_equal [0, 1], response['location']
    get :resolve, {'codeOrCoordinates' => 'aaaa'}
    assert_response :unprocessable_entity
    get :resolve, {'codeOrCoordinates' => 'ccc'}
    assert_response :not_found
  end

  test 'resolve coordinates' do
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

  test 'forecast' do
    get :forecast, { origin: 'rdu', destination: 'pvg',
                    departureTime: '2015-03-22T8:27:00', speed: '300', interval: '2' }
    assert_response :success
    response = ActiveSupport::JSON.decode @response.body
    assert_instance_of Hash, response
    forecast = response['forecast']
    assert_instance_of Array, forecast
    assert_instance_of Array, forecast[0]['location'] unless forecast.empty?
  end

  test 'route to resolve' do
    assert_routing(
      { method: 'get', path: '/resolve/rdu' },
      { controller: 'main', action: 'resolve', codeOrCoordinates: 'rdu' })
  end

  test 'route to forecast' do
    mainRoute = { controller: 'main', action: 'forecast', origin: 'rdu', destination: 'pvg',
                  departureTime: '2015-03-22T8:27:00', speed: '500', interval: '1' }
    assert_routing(
      { method: 'get', path: '/forecast/rdu/pvg/2015-03-22T8:27:00/500/1' },
      mainRoute)
    # rails route processing can block values like float number representations with constraints
    mainRoute[:speed] = '500.12'
    mainRoute[:interval] = '0.34'
    mainRoute[:origin] = '  -1.23  , 2.45 '
    mainRoute[:destination] = '-3,4.68'
    path = "/forecast/#{URI.encode mainRoute[:origin]}/#{mainRoute[:destination]}/2015-03-22T8:27:00/" +
         "#{mainRoute[:speed]}/#{mainRoute[:interval]}"
    assert_routing(
      { method: 'get', path: path },
      mainRoute)
  end
end

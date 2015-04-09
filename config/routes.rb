Rails.application.routes.draw do
  # the constraint is required so that float numbers can be passed as a param
  get '/resolve/:airportCode' => 'main#airportCoordinates', :constraints => { :airportCode => /.*/ }
  get '/forecast/:source/:destination/:departureTime/:speed/:interval' => 'main#forecast'
end

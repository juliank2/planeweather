Rails.application.routes.draw do
  get '/resolve/:airportCode' => 'application#airportCoordinates'
  get '/forecast/:source/:destination/:departureTime/:speed/:interval' => 'application#forecast'
end

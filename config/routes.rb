Rails.application.routes.draw do
  get '/airport-coordinates/:airportCode' => 'application#airportCoordinates'
  get '/forecast/:source/:destination/:departureTime/:speed/:interval' => 'application#forecast'
end

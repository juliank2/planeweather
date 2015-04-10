Rails.application.routes.draw do
  # the constraint is required so that float numbers can be passed as a param
  get '/resolve/:codeOrCoordinates' => 'main#resolve', :constraints => { :codeOrCoordinates => /.*/ }
  get '/forecast/:source/:destination/:departureTime/:speed/:interval' => 'main#forecast'
end

Rails.application.routes.draw do
  matchAll = /.*/
  # the constraints are required so that float numbers can be passed as a param.
  get '/resolve/:codeOrCoordinates' => 'main#resolve', constraints: { codeOrCoordinates: matchAll }
  get '/forecast/:origin/:destination/:departureTime/:speed/:interval' => 'main#forecast',
      :constraints => { speed: matchAll, interval: matchAll, origin: matchAll, destination: matchAll }
end

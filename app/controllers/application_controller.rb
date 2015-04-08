class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  # number number -> number
  def latLongToDistance lat, long
  end

  public

  def airportCoordinates
    render json: {test: 1}
  end

  def forecast
  end

end

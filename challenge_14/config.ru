require_relative 'action_controller'

class LoggerMiddleware
  def initialize(app, string)
    @app = app
    @string = string
  end

  def call(environment)
    puts @string
    @app.call(environment)
  end
end

use LoggerMiddleware, 'Rack app got a request!'

run MyApp.new

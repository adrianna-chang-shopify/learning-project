require_relative 'final_project'

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

run MyApp

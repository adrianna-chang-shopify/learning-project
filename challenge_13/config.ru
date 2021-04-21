require_relative 'action_dispatch'

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

class CharsetMiddleware
  def initialize(app, charset: 'UTF-8')
    @app = app
    @charset = charset
  end

  def call(environment)
    response = Rack::Response[*@app.call(environment)]
    response.content_type = "#{response.content_type}; charset=#{@charset}"
    response.finish
  end
end

use LoggerMiddleware, 'Rack app got a request!'
use CharsetMiddleware

run MyApp.new

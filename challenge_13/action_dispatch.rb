### Require dependencies
require 'action_dispatch'
require 'active_record'
require 'cgi'
require 'rack/handler/puma'
require 'rack'

class Blog < ActiveRecord::Base; end

ActiveRecord::Base.establish_connection(
  adapter:  "sqlite3",
  database: "application.sqlite3"
)

# Create the table if it doesn't exist, seed some data
ActiveRecord::Schema.define do
  unless table_exists?(:blogs)
    create_table :blogs do |t|
      t.string :title
      t.text :content
    end
    Blog.create!(title: 'My awesome blog!', content: 'my favourite HTML tags are <p> and <script>')
    Blog.create!(title: 'Another cool blog!', content: 'my favourite HTML tags are <br> and <hr>')
  end
end

router = ActionDispatch::Routing::RouteSet.new
router.draw do
  get '/', to: -> environment {
    response = Rack::Response.new
    response.write '<p><strong>Submit a new Blog Post!</p></strong>'
    response.write "<form method='post' enctype='application/x-www-form-urlencoded' action='/create-post'>"
    response.write "<p><label>Blog Title: <input name='title'></label></p>"
    response.write "<p><label>Content: <textarea name='content'></textarea></label></p>"
    response.write '<p><button>Submit post</button></p>'
    response.write '</form>'
    response.content_type = 'text/html'
    response.finish
  }
  get '/show-data', to: -> environment {
    response = Rack::Response.new
    response.content_type = 'text/html'
    response.finish do
      response.write '<ul>'

      Blog.all.each do |blog|
        response.write '<li>'
        response.write "<strong>Title: #{CGI.escape_html(blog.title)}</strong>, Content: #{CGI.escape_html(blog.content)}"
        response.write '</li>'
      end
      response.write '</ul>'
    end
  }
  post 'create-post', to: -> environment {
    response = Rack::Response.new
    request = Rack::Request.new(environment)
    puts 'Got a new POST request!'

    Blog.create!(request.params)
    response.redirect('/show-data', 303)
    response.finish
  }
  match '*path', via: :all, to: -> environment {
    response = Rack::Response.new
    response.write "Sorry, I don’t know what #{environment['PATH_INFO']} is"
    response.content_type = 'text/plain'
    response.status = 404
    response.finish
  }
end

app = lambda { |environment|
  puts 'Rack app got a request!'
  router.call(environment) 
}

# Run the Puma app server with our web application
Rack::Handler::Puma.run(app, Port: 1234, Verbose: true)

### Require dependencies
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

app = lambda { |environment|
  puts 'Rack app got a request!'
  # Build Rack request
  request = Rack::Request.new(environment)

  # Build Rack response
  response = Rack::Response.new

  if request.get? && request.path == '/show-data'
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
  elsif request.get? && request.path == '/'
    response.write '<p><strong>Submit a new Blog Post!</p></strong>'
    response.write "<form method='post' enctype='application/x-www-form-urlencoded' action='/create-post'>"
    response.write "<p><label>Blog Title: <input name='title'></label></p>"
    response.write "<p><label>Content: <textarea name='content'></textarea></label></p>"
    response.write '<p><button>Submit post</button></p>'
    response.write '</form>'

    # Prepare response
    response.content_type = 'text/html'
    response.finish
  elsif request.get?
    response.write "method is #{request.request_method}, path is #{request.path}"
    response.content_type = 'text/plain'
    response.finish
  elsif request.post? && request.path == '/create-post'
    puts 'Got a new POST request!'

    # The request params can be passed directly to the Blog's create method - neat!
    blog = Blog.create!(request.params)

    # Prepare response
    response.redirect('/show-data', 303)
    response.finish
  end
}

# Run the Puma app server with our web application
Rack::Handler::Puma.run(app, Port: 1234, Verbose: true)

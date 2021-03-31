### Require dependencies
require 'cgi'
require 'rack/handler/puma'
require 'rack'
require 'yaml/store'

# Struct to define what a Blog looks like
Blog = Struct.new(:title, :content, keyword_init: true)

def set_up_blogs_store(store_path)
  store = YAML::Store.new(File.expand_path(store_path, __dir__))
  store.transaction do
    store[:blogs] = [] if store[:blogs].nil?
  end
  
  # Seed some blog data
  # Comment out if you'd like to start from scratch!
  store.transaction do
    if store[:blogs].empty?
      store[:blogs] << Blog.new(title: 'My awesome blog!', content: 'my favourite HTML tags are <p> and <script>')
      store[:blogs] << Blog.new(title: 'Another cool blog!', content: 'my favourite HTML tags are <br> and <hr>')
    end
  end
  store
end

# Set up YAML store
store = set_up_blogs_store('blogs.yml')

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
      blog_data = store.transaction { store[:blogs] }
      loop do
        blog_data.each do |element|
          response.write '<li>'
          response.write "<strong>Title: #{CGI.escape_html(element.title)}</strong>, Content: #{CGI.escape_html(element.content)}"
          response.write '</li>'
        end
        sleep(1)
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

    post = Blog.new
    request.params.each do |name, value|
      post[name] = value
    end

    store.transaction do
      store[:blogs] << post
    end

    # Prepare response
    response.redirect('/show-data', 303)
    response.finish
  end
}

# Run the Puma app server with our web application
Rack::Handler::Puma.run(app, Port: 1234, Verbose: true)

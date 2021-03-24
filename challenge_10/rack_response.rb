### Require dependencies
require 'cgi'
require 'rack/handler/puma'
require 'rack'
require 'uri'
require 'yaml/store'

### Status codes
STATUS_CODES = {
  ok: 200,
  see_other: 303
}

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

  headers = {}
  body = []

  if request.get? && request.path == '/show-data'
    body << '<ul>'
    blog_data = store.transaction { store[:blogs] }
    blog_data.each do |element|
      body << '<li>'
      body << "<strong>Title: #{CGI.escape_html(element.title)}</strong>, Content: #{CGI.escape_html(element.content)}"
      body << '</li>'
    end
    body << '</ul>'

    # Prepare response
    status = :ok
    headers['Content-Type'] = 'text/html'
  elsif request.get? && request.path == '/'
    body << '<p><strong>Submit a new Blog Post!</p></strong>'
    body << "<form method='post' enctype='application/x-www-form-urlencoded' action='/create-post'>"
    body << "<p><label>Blog Title: <input name='title'></label></p>"
    body << "<p><label>Content: <textarea name='content'></textarea></label></p>"
    body << '<p><button>Submit post</button></p>'
    body << '</form>'

    # Prepare response
    status = :ok
    headers['Content-Type'] = 'text/html'
  elsif request.get?
    body << "method is #{request.request_method}, path is #{request.path}"
    status = :ok
    headers['Content-Type'] = 'text/plain'
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
    status = :see_other
    headers['Location'] = '/show-data' # NOTE: Don't need a Content-Type here, we're redirecting!
  end

  [STATUS_CODES[status], headers, body]
}

Rack::Handler::Puma.run(app, Port: 1234, Verbose: true)

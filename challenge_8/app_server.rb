### Require dependencies
require 'cgi'
require 'uri'
require 'yaml/store'
require 'rack'
require 'rack/handler/puma'

### Status codes
STATUS_CODES = {
  ok: 200,
  see_other: 303
}

# Struct to define what a Blog looks like
Blog = Struct.new(:title, :content, keyword_init: true)

# Retrieve data from our YAML store
store = YAML::Store.new(File.expand_path('blogs.yml', __dir__))

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

app = lambda { |environment|
  puts 'Rack app got a request!'
  request_method = environment['REQUEST_METHOD']
  request_path   = environment['PATH_INFO']

  headers = {}
  body = []
  case [request_method, request_path]
  when ['GET', '/show-data']
    body << '<ul>'
    blog_data = store.transaction { store[:blogs] }
    blog_data.each do |element|
      body << '<li>'
      body << "<strong>Title: #{CGI.escape_html(element.title)}</strong>, Content: #{CGI.escape_html(element.content)}"
      body << '</li>'
    end
    body << '</ul>'

    status = :ok
    headers['Content-Type'] = 'text/html'
  when ['POST', '/create-post']
    puts 'Got a new POST request!'

    # We no longer need content length, as the StringIO object allows us to read until the EOF without blocking
    # (Puma handles reading the exact content length from the TCP socket behind the scenes for us).
    # We know this is a small request, so we can read the entire IO object - however, this could very well be a 
    # large request (ie. recall file uploads), in which case  we would want to limit the amount of data read at a time
    # in order to not exhaust our program's memory.
    # Tom & I explored Puma code here to see how Puma handles reading the body from the TCP Server for large streams of
    # data (TLDR: Tempfile!)
    # https://github.com/puma/puma/blob/master/lib/puma/client.rb#L280-L304
    # https://github.com/puma/puma/blob/7970d14e63836d1c47a086928e533eee766af48d/lib/puma/const.rb#L159-L160
    message_body = environment['rack.input'].read

    fields = URI.decode_www_form(message_body)
    post = Blog.new
    fields.each do |name, value|
      post[name] = value
    end

    store.transaction do
      store[:blogs] << post
    end

    # Prepare response
    status = :see_other
    headers['Location'] = '/show-data' # NOTE: Don't need a Content-Type here, we're redirecting!
  when ['GET', '/']
    body << '<p><strong>Submit a new Blog Post!</p></strong>'
    body << "<form method='post' enctype='application/x-www-form-urlencoded' action='/create-post'>"
    body << "<p><label>Blog Title: <input name='title'></label></p>"
    body << "<p><label>Content: <textarea name='content'></textarea></label></p>"
    body << '<p><button>Submit post</button></p>'
    body << '</form>'

    # Prepare response
    status = :ok
    headers['Content-Type'] = 'text/html'
  else
    body << "method is #{request_method}, path is #{request_path}"
    status = :ok
    headers['Content-Type'] = 'text/plain'
  end

  [STATUS_CODES[status], headers, body]
}

Rack::Handler::Puma.run(app, Port: 1234, Verbose: true)

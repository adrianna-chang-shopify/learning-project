### Require dependencies
require 'socket'
require 'cgi'
require 'uri'
require 'yaml/store'

### Define some constants ###
#############################
# More info here: https://tools.ietf.org/html/rfc7231#section-6
STATUS_CODES = {
  ok: 200,
  see_other: 303
}

# Accompanying text for status codes
STATUS_CODES_TEXT = {
  ok: 'OK',
  see_other: 'See Other'
}

HTTP_VERSION = 'HTTP/1.1'

# Struct to define what a Blog looks like
Blog = Struct.new(:title, :content, keyword_init: true)

CRLF = "\r\n"
#############################

# Start a TCP Server on port 1234
server = TCPServer.new 1234
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

loop do
  # Accept a client connection
  client = server.accept
  puts 'Got a new client!'

  # Read the request line
  request_line = client.readline.chomp
  puts 'Parsing HTTP request!'
  method, target, http_version = request_line.split

  puts 'Building response for client!'
  # Check method type and request target to determine what to send back to client
  case [method, target]
  when ['GET', '/show-data']
    message_body = ''
    message_body << '<ul>'

    # Transaction in case someone writes to the store in between our reads,
    # and the data is no longer consistent
    blog_data = store.transaction { store[:blogs] }
    blog_data.each do |element|
      message_body << '<li>'
      message_body << "<strong>Title: #{CGI.escape_html(element.title)}</strong>, Content: #{CGI.escape_html(element.content)}"
      message_body << '</li>'
    end
    message_body << '</ul>'

    # Prepare response
    status_code = :ok
    header_field = 'Content-Type: text/html'
  when ['POST', '/create-post']
    puts 'Got a new POST request!'
    headers = {}
    line = client.readline
    while (line = client.readline) != CRLF
      header_name, _, header_value = line.chomp.partition(': ')
      headers[header_name] = header_value
    end
    content_length = headers['Content-Length']
    body = client.read(content_length.to_i)
    fields = URI.decode_www_form(body)
    post = Blog.new
    fields.each do |name, value|
      post[name] = value
    end

    store.transaction do
      store[:blogs] << post
    end

    # Prepare response
    status_code = :see_other
    header_field = 'Location: /show-data' # NOTE: Don't need a Content-Type here, we're redirecting!
  else
    # Main Page
    message_body =  ''
    message_body << '<p><strong>Submit a new Blog Post!</p></strong>'
    # Method = POST
    # Encoding type = application/x-www-form-urlencoded (usual encoding system, Ruby has built-in decoder)
    # Action = /create-post (Seems like this just needs to be a relative target path, but docs use full URL)
    message_body << "<form method='post' enctype='application/x-www-form-urlencoded' action='/create-post'>"
    message_body << "<p><label>Blog Title: <input name='title'></label></p>"
    message_body << "<p><label>Content: <textarea name='content'></textarea></label></p>"
    message_body << '<p><button>Submit post</button></p>'
    message_body << '</form>'

    # Prepare response
    status_code = :ok
    header_field = 'Content-Type: text/html'
  end

  # Build our status line using whichever status_code we've set
  status_line = "#{HTTP_VERSION} #{STATUS_CODES[status_code]} #{STATUS_CODES_TEXT[status_code]}"

  # Send response to client
  client.write(status_line + CRLF)
  client.write(header_field + CRLF)
  # CRLF to separate the headers from the message body
  client.write(CRLF)
  client.write(message_body)

  client.close
end

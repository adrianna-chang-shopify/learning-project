### Require dependencies
require 'socket'
require 'cgi'
require 'uri'

### Define some constants ###
#############################
# More info here: https://tools.ietf.org/html/rfc7231#section-6
STATUS_CODES = {
  ok: 200,
  redirect: 303
}

# Accompanying text for status codes
STATUS_CODES_TEXT = {
  ok: 'OK',
  redirect: 'See Other'
}

HTTP_VERSION = 'HTTP/1.1'

BLOG_DATA = 
[
  {
    title: 'My awesome blog!',
    content: 'my favourite HTML tags are <p> and <script>'
  },
  {
    title: 'Another cool blog!',
    content: 'my favourite HTML tags are <br> and <hr>'
  }
]

CRLF = "\r\n"
#############################

server = TCPServer.new 1234

loop do
  # Accept a client connection
  client = server.accept
  puts "Got a new client!"
  
  # Read the request line
  request_line = client.readline.chomp
  puts "Parsing HTTP request!"
  method, target, http_version = request_line.split

  puts "Building response for client!"
  status_line = "#{HTTP_VERSION} #{STATUS_CODES[:ok]} #{STATUS_CODES_TEXT[:ok]}"
  header_field = "Content-Type: text/html"

  # Check request target to determine what to send back to client
  if target == '/show-data'
    message_body = ""
    message_body << "<ul>"
    BLOG_DATA.each do |element|
      message_body << "<li>"
      message_body << "<strong>Title: #{CGI.escape_html(element[:title])}</strong>, Content: #{CGI.escape_html(element[:content])}"
      message_body << "</li>"
    end
    message_body << "</ul>"
  elsif target == '/create-post' && method == 'POST'
    status_line = "#{HTTP_VERSION} #{STATUS_CODES[:redirect]} #{STATUS_CODES_TEXT[:redirect]}"
    # Don't need a Content-Type here, we're redirecting!
    header_field = "Location: /show-data"

    puts "Got a new POST request!"
    # Not sure if this is how to do this
    # Let's try reading all the headers in until we get a line that is just CRLF
    headers = {}
    line = client.readline
    while (line = client.readline) != CRLF
      header_name, header_value = line.chomp.split(": ")
      headers[header_name] = header_value
    end
    content_length = headers["Content-Length"]
    body = client.read(content_length.to_i)
    post = Hash[URI.decode_www_form(body)]
    post.transform_keys! { |key| key.to_sym }
    BLOG_DATA << post
  else
    # Main Page
    message_body =  ""
    message_body << "<p><strong>Submit a new Blog Post!</p></strong>"
    # Method = POST
    # Encoding type = application/x-www-form-urlencoded (usual encoding system, Ruby has built-in decoder)
    # Action = /create-post (Seems like this just needs to be a relative target path, but docs use full URL)
    message_body << "<form method=\"post\" enctype=\"application/x-www-form-urlencoded\" action=\"/create-post\">"
    message_body << "<p><label>Blog Title: <input name='title'></label></p>"
    message_body << "<p><label>Content: <textarea name='content'></textarea></label></p>"
    message_body << "<p><button>Submit post</button></p>"
    message_body << "</form>"
  end

  # Send response to client
  client.write(status_line + CRLF)
  client.write(header_field + CRLF)
  # CRLF to separate the headers from the message body
  client.write(CRLF)
  client.write(message_body)

  client.close
end

# - add a form to the main page with multiple input fields (and the correct method, action and enctype) which will send a POST request to a new request path when it’s submitted;
# - accept a POST request to that new request path;
# - read the headers from the POST request to determine the Content-Length;
# - read the request body from the POST request;
# - decode the application/x-www-form-urlencoded-encoded request body to extract the values of the form fields;
# - make a new data item using those values and add it to the application’s collection of data items; and
# - send a response which directs the user back to the main page somehow.

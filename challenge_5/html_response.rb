### Require dependencies
require 'socket'
require 'cgi'

### Define some constants ###
#############################
# More info here: https://tools.ietf.org/html/rfc7231#section-6
STATUS_CODES = {
  ok: 200
}

# Accompanying text for status codes
STATUS_CODES_TEXT = {
  ok: 'OK'
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

  # Check request target to determine what to render for message body / headers
  if target == '/show-data'
    # The browser knows how to add <html> tags and <head> / <body> tags for us!
    header_field = "Content-Type: text/html\r\n"
    message_body = ""
    message_body << "<ul>"
    BLOG_DATA.each do |element|
      message_body << "<li>"
      message_body << "<strong>Title: #{CGI.escape_html(element[:title])}</strong>, Content: #{CGI.escape_html(element[:content])}"
      message_body << "</li>"
    end
    message_body << "</ul>"
  else
    header_field = "Content-Type: text/plain\r\n"
    message_body =  "Request method: #{method}, Request target: #{target}, HTTP Version: #{http_version}"
  end

  # Send response to client
  client.write(status_line + CRLF)
  client.write(header_field + CRLF)
  # CRLF to separate the headers from the message body
  client.write(CRLF)
  client.write(message_body)

  client.close
end

require 'socket'

server = TCPServer.new 1234

# "A request is what a browser will send to your application when you visit a
#   URL like http://localhost:1234/my/awesome/path."

# More info here: https://tools.ietf.org/html/rfc7231#section-6
STATUS_CODES = {
  ok: 200
}

# Accompanying text for status codes
STATUS_CODES_TEXT = {
  ok: 'OK'
}

HTTP_VERSION = 'HTTP/1.1'

loop do
  # Accept a client connection
  client = server.accept
  puts "Got a new client!"
  
  # Read the request line
  request_line = client.readline.chomp
  puts "Parsing HTTP request!"
  method, target, http_version = request_line.split

  puts "Building response for client!"
  # The status line is a single line of text containing:
  # - The HTTP protocol version
  # - The status code
  # - Optionally, a piece of text to describe the status code
  #   Question: Can you make this whatever you want, or will the client expect
  #   the status code to match a given piece of text? When would you ever send
  #   a "non-typical" piece of text here?
  #   Answer: This piece of text doesn't really do anything! HTTP clients are expected to ignore it.
  #   It comes earlier from an era of Internet application protocols that were more frequently used with
  #   interactive text clients.
  # - A CRLF
  status_line = "#{HTTP_VERSION} #{STATUS_CODES[:ok]} #{STATUS_CODES_TEXT[:ok]}\r\n"

  # Feedback from Tom on whether my understanding here is correct:
  # If you have multiple headers, they would each be on separate lines (ie. with a CRLF
  # at the end of each header field)
  # Then, we need ANOTHER CRLF to separate the set of header fields from the message body (see L55)
  header_field = "Content-Type: text/plain\r\n"

  # Build the message body
  # From Tom in the doc: "The message body of a response message will be displayed by the browser"
  # This is why it's important we specify the content type, so the browser knows
  # how to display the information we send in the body
  message_body = "Request method: #{method}, Request target: #{target}, HTTP Version: #{http_version}"

  # Send response to client
  client.write(status_line)
  client.write(header_field)
  # CRLF to separate the headers from the message body
  client.write("\r\n")
  client.write(message_body)

  client.close
end

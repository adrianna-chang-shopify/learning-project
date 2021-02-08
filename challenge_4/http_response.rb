require 'socket'

server = TCPServer.new 1234

# "A request is what a browser will send to your application when you visit a
#   URL like http://localhost:1234/my/awesome/path."

# More info here: https://tools.ietf.org/html/rfc7231#section-6
status_codes = {
  ok: 200
}

# Accompanying text for status codes
status_codes_text = {
  ok: 'OK'
}

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
  status_line = "#{http_version} #{status_codes[:ok]} #{status_codes_text[:ok]}\n"

  # Feedback from Tom on whether my understanding here is correct:
  # If you have multiple headers, they would each be on separate lines (ie. with a new
  # line at the end of each header field)
  # Then, we need ANOTHER new line to separate the set of header fields from the message body (see L55)
  header_field = "Content-Type: text/plain\n"

  # Build the message body
  # From Tom in the doc: "The message body of a response message will be displayed by the browser"
  # This is why it's important we specify the content type, so the browser knows
  # how to display the information we send in the body
  message_body = "Request method: #{method}, Request target: #{target}, HTTP Version: #{http_version}"

  # Send response to client
  client.write(status_line)
  client.write(header_field)
  # New line to separate the headers from the message body
  client.write("\n")
  client.write(message_body)

  client.close
end

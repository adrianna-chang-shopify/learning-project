require 'socket'

server = TCPServer.new 1234

# "A request is what a browser will send to your application when you visit a
#   URL like http://localhost:1234/my/awesome/path."

loop do
  # Accept a client connection
  client = server.accept
  puts "Got a new client!"
  
  # Read the request line
  # Chomp is not strictly needed given our use of String#split (which discards
  # the CLRF for us automatically), but it's nice to encapsulate the reading
  # of this request line into a single line of code that ensures it is cleaned
  # up appropriately (no surprises later on!)
  request_line = client.readline.chomp
  puts "Parsing HTTP request!"
  method, target, http_version = request_line.split

  puts "\n"
  puts "-" * 90
  puts "\n"

  puts "Request method: #{method}"
  puts "Request target: #{target}"
  puts "HTTP Version: #{http_version}"

  client.close

  # Read the rest of the HTTP message
  # The rest is all headers
  # We'll ignore this for now since we just want the request line
  # while !client.eof?
  #   puts client.readline
  # end
end

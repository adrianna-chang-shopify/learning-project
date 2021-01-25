require 'socket'

server = TCPServer.new 1234

# "A request is what a browser will send to your application when you visit a
#   URL like http://localhost:1234/my/awesome/path."

loop do
  # Accept a client connection
  client = server.accept
  puts "Got a new client!"
  
  # Read the request line
  # Do I need the chomp? Seems to work fine without it
  request_line = client.readline.chomp
  request_line_split = request_line.split(' ')

  puts "Parsing HTTP request!"

  puts "\n"
  puts "-" * 90
  puts "\n"

  puts "Request method: #{request_line_split[0]}"
  puts "Request target: #{request_line_split[1]}"
  puts "HTTP Version: #{request_line_split[2]}"

  puts "\n"
  puts "-" * 90
  puts "\n"

  # Read the rest of the HTTP message
  # Are these all headers?
  puts "Getting rest of HTTP message"
  while !client.eof?
    puts client.readline
  end
end

require 'socket'

server = TCPServer.new 1234

loop do
  client = server.accept
  puts "Got a new client!"
  while !client.eof?
    input = client.readline
    client.puts input.upcase
  end
end

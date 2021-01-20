# Learnings from Challenge 1
* TCP = protocol for applications to talk to one another over a network
* TCP establishes a connection between a server and a client
* TCP connection needs an IP address and a port
  * "I want to start talking TCP to <some ip address> on port <some port number>"
  * TCP connection invokes handshake between client and server
* Port designates _which_ application at the IP address to talk to
* Users on a machine are usually restricted to which ports they can designate
for new servers
  * Low-numbered ports usually reserved for super-users
* TCP server can listen for incoming connections on a given port by creating a server socket
  * In Ruby, we can create a new TCPServer, which inherits from TCPSocket class
  * The OS handles creating the socket, and connecting it to the right IP address and port
* When a client connects, a client socket is created
  * The app uses the socket to read and write data across the connection
  * In Ruby, only one client can be served at a time (only a single client socket)
  * `client = server.accept` => a `TCPSocket`!
  * As soon as we call `server.accept` again, we lose connection to the previous client,
  and a new client can be picked up.
* `TCPSocket` implements the IO interface (so like reading from / writing to a file)
* For the challenge, we use `IO#readline`
  * Under the hood, this is using the OS and reading byte by byte until new line is reached
* When we use netcat to connect to our application over TCP, any input to stdin goes through the socket
to the server
  * OS splits the data up into packets to be sent to the socket
* When we close the netcat connection (CTRL+C), a packet is sent by the OS to let the server
know that the client connection is finished (since it's an IO, end of file)
* `#readline` blows up on `EOFError`, so we need to check whether we've reached the end of the file
(`#eof?`) in our infinite loop that reads data from the client
* We can add another outer loop that is responsible for accepting new clients, so that if we end
one of our netcat connections, we can open another one while running the same Ruby program.

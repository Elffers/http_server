require 'socket'

server = TCPServer.new 8000 # Server bind to port 8000

loop do
  client = server.accept
  Thread.new do
    request = client.gets("\r\n\r\n")

    response = "HTTP/1.1 200 OK\r\nconnection: close\r\ncontent-type: text/plain\r\n\r\n"
    body = "It worked!\n"

    sleep 5

    client.write response # client.write sends the actual response message
    client.write body

    client.close
  end
end

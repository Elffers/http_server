require 'socket'
require 'thread' # this is to get mutexes (mutual exclusion)

server = TCPServer.new 8000 # Server bind to port 8000
request_number = 0
mutex = Mutex.new

loop do
  client = server.accept
  Thread.new do
    request = client.gets("\r\n\r\n")

    response = "HTTP/1.1 200 OK\r\nconnection: close\r\ncontent-type: text/plain\r\n\r\n"

    current_request = mutex.synchronize do
      request_number += 1
    end

    body = "#{current_request}\n"

    client.write response # client.write sends the actual response message
    client.write body

    client.close
  end
end

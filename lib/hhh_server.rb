require 'socket'

class HHHServer
  def start

    server = TCPServer.new 8000 # Server bind to port 8000

    loop do
      # server.accept is a blocking process, so the thread stops and waits until
      # a client connects. That is, nothing else gets executed until a 3-way
      # handshake is completed

      client = server.accept
      # the client is a TCPSocket object, which is a stream/connection

      # This only reads the request header, since body always comes after a newline
      request = client.gets("\r\n\r\n")

      # Extracts the request uri
      /[A-Z]+ (?<path>[^ ]+)/ =~ request

      status = "HTTP/1.1 "
      # tacks on path to current dir to request uri
      path = Dir.pwd + path

      # TODO: make sure path name is secure using Pathname
      if File.directory? path
        output = "<ul>"
        Dir.entries(Dir.pwd).map do |file|
          output += "<li><a href=\"/#{file}\">#{file}</a></li>"
        end
        output += "</ul>\n"
        body = output
        status += "200 OK"
        content_type = 'text/html'
      elsif File.exists? path
        body = File.read path
        status += "200 OK"
        content_type = 'text/plain'
      else
        body = "404 Not Found :("
        status += "404 Not Found"
        content_type = "text/plain"
      end

      response = status + "\r\nconnection: close\r\ncontent-type:" + content_type + "\r\n\r\n"

      client.write response
      client.write body

      client.close
    end
  end
end

require 'socket'

class HHHServer
  def initialize(app)
    @app = app
  end

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
      /(?<method>[A-Z]+) (?<request_uri>[^ ]+)/ =~ request

      # Extracts the path
      /(?<path>.+)\?/ =~ request_uri

      # Extracts the query string from path
      /\?(?<query_string>.*)/ =~ request_uri

      env = {
        REQUEST_METHOD    => method,
        HTTP_VERSION      => "1.1",
        RACK_VERSION      => Rack::VERSION,
        SERVER_PROTOCOL   => "1.1",
        QUERY_STRING      => query_string || "",
        PATH_INFO         => path,
        SCRIPT_NAME       => path,
        REQUEST_PATH      => request_uri,
        # RACK_INPUT      => rack_input,
        RACK_ERRORS       => $stderr,
        RACK_MULTITHREAD  => false,
        RACK_MULTIPROCESS => false,
        RACK_RUNONCE      => false,
        RACK_URL_SCHEME   => "http",
        RACK_IS_HIJACK    => false,
        RACK_HIJACK       => lambda { raise NotImplementedError, "only partial hijack is supported."},
        RACK_HIJACK_IO    => nil
      }

      status = "HTTP/1.1 "
      # tacks on request_uri to current dir to request uri
      request_uri = Dir.pwd + request_uri

      # TODO: make sure path name is secure using Pathname
      if File.directory? request_uri
        output = "<ul>"
        Dir.entries(Dir.pwd).map do |file|
          output += "<li><a href=\"/#{file}\">#{file}</a></li>"
        end
        output += "</ul>\n"
        body = output
        status += "200 OK"
        content_type = 'text/html'
      elsif File.exists? request_uri
        body = File.read request_uri
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

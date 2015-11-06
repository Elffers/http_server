require 'socket'

class HHHServer
  HTTP_STATUS_MESSAGE = {
    200 => "OK"
  }

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
      /(?<path>.+)\??/ =~ request_uri

      # Extracts the query string from path
      /\?(?<query_string>.*)/ =~ request_uri
      rack_input = StringIO.new("")
      rack_input.set_encoding(Encoding::BINARY)


      env = {
        'HTTP_VERSION'      => "1.1",
        'REQUEST_METHOD'    => method,
        'rack.version'      => Rack::VERSION,
        'SERVER_PROTOCOL'   => "1.1",
        'SERVER_NAME'       => "HHH",
        'SERVER_PORT'       => "8000",
        'QUERY_STRING'      => query_string || "",
        'PATH_INFO'         => path,
        'SCRIPT_NAME'       => "",
        'REQUEST_PATH'      => request_uri,
        'rack.input'        => rack_input,
        'rack.errors'       => $stderr,
        'rack.multithread'  => false,
        'rack.multiprocess' => false,
        'rack.runonce'      => false,
        'rack.url_scheme'   => "http",
        'rack.is_hijack'    => false,
        'rack.run_once'     => true,
      }

      status_code, header_hash, body = @app.call(env)

      # status = "HTTP/1.1 "

      # tacks on request_uri to current dir to request uri
      # request_uri = Dir.pwd + request_uri

      # TODO: make sure path name is secure using Pathname
      # if File.directory? request_uri
      #   output = "<ul>"
      #   Dir.entries(Dir.pwd).map do |file|
      #     output += "<li><a href=\"/#{file}\">#{file}</a></li>"
      #   end
      #   output += "</ul>\n"
      #   body = output
      #   status += "200 OK"
      #   content_type = 'text/html'
      # elsif File.exists? request_uri
      #   body = File.read request_uri
      #   status += "200 OK"
      #   content_type = 'text/plain'
      # else
      #   body = "404 Not Found :("
      #   status += "404 Not Found"
      #   content_type = "text/plain"
      # end
      # HTTP/1.1 301 Moved Permanently

      message = HTTP_STATUS_MESSAGE[status_code]

      status = "HTTP/1.1 #{status_code} #{message}\r\n"

      client.write status

      headers = header_hash.map do |k, v|
        "#{k}: #{v}\r\n"
      end.join

      client.write headers
      client.write "\r\n"

      body.each { |part| client.write part }

      client.close
    end
  end
end

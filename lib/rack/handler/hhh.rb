require 'hhh_server'

class Rack::Handler::HHH
  def self.run(app, options={})
    server = HHHServer.new
    server.start
  end
end

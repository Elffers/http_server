require 'hhh_server'

class Rack::Handler::HHH
  def self.run(app, options={})
    HHHServer.start
  end
end

require 'uri'
require 'net/http'
require_relative 'auth_client'

uri = URI.parse 'http://localhost:8000/' # Expects auth_server.rb to be running
uri.user = 'username'
uri.password = 'password'

http = Net::HTTP.new uri.host, uri.port
http.set_debug_output $stderr

req = Net::HTTP::Get.new uri.request_uri

res = http.request req

input = res['www-authenticate']

digest_auth = DigestAuth.new('username', 'password')
auth = digest_auth.authenticate(input, uri.request_uri)

req = Net::HTTP::Get.new uri.request_uri
req.add_field 'Authorization', auth

res = http.request req

puts
puts "passed" if res.code == '200'
puts "failed" if res.code != '200'

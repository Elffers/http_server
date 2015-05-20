# Implementation of HTTP Digest Authentication, as per RFC 2617
# (https://www.ietf.org/rfc/rfc2617.txt)
#
# HTTP Authentication is to ensure that a client is authenticated
# on a server for a single request.
#
# Basic Authentication is not secure because the username and password
# are sent via clear text (not plain text, but Base64 encoded,
# which does not require a shared secret to decode.
#
# Digest Auth is more secure because the client uses the password
# to hash the information it gets from the 'www-authenticate' header
# received from the server response (which has a 401 status).
#
# The client then sends this hashed response as the value in 'response' within
# in the 'Authorization' header (Sec 3.2.2) in its subsequent request.
#
# The server can then compare this hash against its own hash of the
# same information to verify the client's credentials.

require 'digest'

class DigestAuth

  attr_reader :input
  attr_accessor :nonce, :realm, :opaque, :algorithm

  def initialize(input)
    # Input is the value of the 'WWW-Authenticate' header sent by the server,
    # which comes in as a set of key-value pairs.
    @input = input
    parse_input
  end

  def authenticate(username, password, uri)
    components = []
    password_hash = password_hash(username, realm, password, uri)
    components.push "username=#{username.dump}"
    components.push "realm=#{realm.dump}"
    components.push "nonce=#{nonce.dump}"
    components.push "uri=#{uri.dump}"
    components.push "qop=auth"
    components.push "nc=#{nonce_count}"
    components.push "cnonce=#{cnonce.dump}"
    components.push "response=#{password_hash.dump}"
    components.push "opaque=#{opaque.dump}" if opaque
    components.push "algorithm=#{algorithm}"
    header = components.join(", ")
    header.prepend("Digest ")
  end

  def cnonce
    "0a4f113b"
  end

  def nonce_count
    "00000001"
  end

  def password_hash(username, realm, password, uri)
    if algorithm == "MD5-sess"
      sess_a1 = [username, realm, password].join(":")
      seg1 = Digest::MD5.hexdigest(sess_a1)
      a1 = [seg1, nonce, cnonce].join(":")
      ha1 = Digest::MD5.hexdigest(a1)
    else
      a1 = [username, realm, password].join(":")
      ha1 = Digest::MD5.hexdigest(a1)
    end
    a2 = ["GET", uri].join(":")
    ha2 = Digest::MD5.hexdigest(a2)
    request_digest = [ha1, nonce, nonce_count, cnonce, qop, ha2].join(":")
    Digest::MD5.hexdigest(request_digest)
  end

  def qop
    "auth"
  end

  # Parses out expected key-value pairs such as realm, nonce, as well as
  # optional params such as opaque and algorithm
  def parse_input
    /Digest\s+realm="(?<realm>.+?)".+nonce="(?<nonce>\S+)".+/ =~ input
    /algorithm=(?<algo>[^,]+)/ =~ input
    /opaque="(?<opaque>\S+)"/ =~ input
    @realm = realm
    @nonce = nonce
    @opaque = opaque
    @algorithm = algo || "MD5"
  end
end

require 'digest'

class DigestAuth

  attr_reader :input
  attr_accessor :nonce, :realm, :opaque, :algorithm

  def initialize(input)
    #This is the value of the WWW-Authenticate header
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

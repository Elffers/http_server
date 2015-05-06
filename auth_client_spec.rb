require_relative 'auth_client'

describe DigestAuth do
  let(:nonce) {"dcd98b7102dd2f0e8b11d0f600bfb0c093" }
  let(:realm) { "testrealm@host.com" }
  let(:opaque) { "5ccc069c403ebaf9f0171e9517f40e41" }
  let(:uri) { "/dir/index.html" }
  let(:username) { "Mufasa" }
  let(:password) { "Circle Of Life" }
  let(:input) { %Q{Digest realm="#{realm}", qop="auth,auth-int", nonce="#{nonce}", opaque="#{opaque}"} }

  let(:input2) { %Q{Digest realm="net-http-digest_auth", nonce="MDAxNDMwODkxNTI2OjY3MDNmYjFiNTgzYWQ4YWY1Zjk4OGNmMGQ4YTA3YjQz", stale=false, algorithm=MD5-sess, qop="auth"} }

  let(:digester) { DigestAuth.new input }

  context ".authenticate" do
    let(:expected) { %Q{Digest username="Mufasa", realm="#{realm}", nonce="#{nonce}", uri="#{uri}", qop=auth, nc=00000001, cnonce="0a4f113b", response="6629fae49393a05397450978507c4ef1", opaque="#{opaque}"} }

    it "should return the proper headers" do
      response = digester.authenticate(username, password, uri )
      expect(response).to eq expected
    end

  end

  context ".password_hash" do
    it "returns md5 hash by default" do
      expect(digester.password_hash(username, realm, password, uri)).to eq "6629fae49393a05397450978507c4ef1"
    end

     it "returns md5-sess hash if specified" do
      digester2 = DigestAuth.new input2
     end
  end

  context ".parse_input" do
    it "returns the realm, nonce, and opaque" do
      digester.parse_input
      expect(digester.nonce).to eq nonce
      expect(digester.realm).to eq realm
      expect(digester.opaque).to eq opaque
    end

    it "returns the algorithm if included" do
      digester2 = DigestAuth.new input2
      expect(digester2.algorithm).to eq "MD5-sess"
    end

  end
end

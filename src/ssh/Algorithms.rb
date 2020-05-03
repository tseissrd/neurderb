class KexAlgorithm
  @@supported = [
    'diffie-hellman-group1-sha1',
    'diffie-hellman-group14-sha1'
    ]
  def self.supported()
    @@supported
  end
end

class Server
end
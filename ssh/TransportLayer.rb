require './ssh/DataTypes.rb'
require './ssh/MessageCodes.rb'
require './ssh/Algorithms.rb'

class Packet
  def self.encode(payload, cipherBlockSize = 0, mac = '')
    @length = payload.size
    @size = Uint32.size + Byte.size + @length
    @paddingLength = 0
    mul = 8
    cipherBlockSize > mul ? mul = cipherBlockSize : ''
    while (@size % mul) != 0
      @paddingLength += 1
      @size += 1
    end
    @data = Uint32.f(@length) + Byte.f(@paddingLength) + payload
    @paddingLength.times {
      @data += Byte.random
    }
    @data
  end
  def self.decode(bstring)
    
  end
end

class TL
  
  def self.idString(comment = '', protver = '2.0', softver = 'ZZzip_0.1')
    if comment.length != 0
      return Bstring("SSH-#{protver}-#{softver + Byte.f(32) + comment + Byte.f(13) + Byte.f(10)}")
    end
    return Bstring("SSH-#{protver}-#{softver + Byte.f(13) + Byte.f(10)}")
  end
  
  def self.exchangeKeysSend(sock)
    payload = Byte.f(SSH_MSG_KEXINIT)
    16.times {
      payload += Byte.random
    }
    payload += Bstring.f(KexAlgorithm.supported.join(','))
      
    puts payload
    sock.write()
  end
  
  
end
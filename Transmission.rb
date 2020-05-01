require './MSGCodes.rb'

class T
  
  include MC
  
  def initialize()
    throw 'not for initialization'
  end
  
  def self.readMsgSafe(sock)
    recbuf = ''
    while !recbuf || recbuf.length < Uint32.size
      recbuf = sock.read(Uint32.size)
    end
    begin
      length = Uint32.to_i(recbuf)
      return sock.read(length)
    rescue
      sock.close
    end
  end
  
  def self.closeConnection(sock, reason)
    sock.write(CANCEL)
    sock.write(Bstring.f(reason))
    sock.close
  end
  
end
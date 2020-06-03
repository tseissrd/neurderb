UTF8ENC = Encoding::UTF_8

class Byte
  def self.f(int)
    if !(int.integer?) || (int < 0) || (int > 255)
      throw 'byte can only be integer from 0 to 255'
    end
    return [int].pack('C')
  end
  def self.to_i(bstr)
    return bstr.unpack('C')[0]
  end
  def self.size()
    return 1
  end
  def self.random()
    f((rand() * 256).floor)
  end
end

class Boolean
  def self.f(bool)
    if !(bool === 0)
      return [1].pack('C')
    end
    return [0].pack('C')
  end
  def self.to_b(bstr)
    return bstr.unpack('C')[0]
  end
  def self.size()
    return 1
  end
end

class Uint32
  def self.f(int)
    if !(int.integer?) || (int < 0) || (int > (2**32-1))
      throw 'uint32 can only be integer from 0 to 2^32 - 1'
    end
    return [int].pack('L>')
  end
  def self.to_i(bstr)
    return bstr.unpack('L>')[0]
  end
  def self.size()
    return 4
  end
end

class Uint64
  def self.f(int)
    if !(int.integer?) || (int < 0) || (int > (2**64-1))
      throw 'uint64 can only be integer from 0 to 2^64 - 1'
    end
    return [int].pack('Q>')
  end
  def self.to_i(bstr)
    return bstr.unpack('Q>')[0]
  end
  def self.size()
    return 8
  end
end

class Bstring
  def self.f(str)
    return Uint32.f(str.bytes.length) + str
  end
  def self.to_s(bstring)
    return bstring[4..(-1)]
  end
end

class Mpint
  def self.f(str)
    if str === '0'
      return Uint32.f(0)
    end
    neg = false
    fstr = ''
    if str[0] === '-'
      fstr = str[1..(-1)]
      neg = true
    else
      fstr = str
    end
    if !(fstr.length.even?)
      fstr = '0' + fstr
    end
    arr = []
    if neg
      comp = '11111111'.to_i(2)
      arr = (Hex.from_s(fstr).map{|b|
        (b.hex ^ comp).to_s(16)
      })
      arr[-1] = (arr[-1].hex + 1).to_s(16)
      if arr[0].hex[7] === 0
        arr.insert(0,'FF')
      end
    else
      arr = Hex.from_s(fstr)
      if arr[0].hex[7] === 1
        arr.insert(0,'00')
      end
    end
    return Uint32.f(arr.length) + (arr.map {|b|
      Byte.f(b.hex)
    }).join
  end
end

class Hex
  def self.from_s(str)
    i = 0
    p = ''
    out = []
    str.split('').each {|c|
      i = i + 1
      if i.even?
        out.push(p + c)
      end
      p = c
    }
    out
  end
  def self.bytes(packedstr)
    return packedstr.unpack('C*').map {|c|
      c = c.to_s(16)
      if c.length === 1
        c = '0' + c
      end
      c
    }
  end
  def self.f(packedstr)
    return bytes(packedstr).join('')
  end
end
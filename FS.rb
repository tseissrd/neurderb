class FS
  
  def self.KiB(qnt)
    return 1024*qnt
  end
  def self.MiB(qnt)
    return (1024**2)*qnt
  end
  def self.GiB(qnt)
    return (1024**3)*qnt
  end
  
  def self.toKiB(qnt)
    return qnt/1024.0
  end
  def self.toMiB(qnt)
    return qnt/(1024.0**2)
  end
  def self.toGiB(qnt)
    return qnt/(1024.0**3)
  end
  
  def self.parse(str)
    if str =~ /KiB/
      return KiB(str[0...-3].to_f)
    elsif str =~ /MiB/
      return MiB(str[0...-3].to_f)
    elsif str =~ /GiB/
      return GiB(str[0...-3].to_f)
    else
      return str.to_f
    end
  end
  
  def self.readable(bytes)
    if bytes < 1024
      return bytes.to_s + 'B'
    elsif toKiB(bytes) < 1024
      return toKiB(bytes).round(2).to_s + 'KiB'
    elsif toMiB(bytes) < 1024
      return toMiB(bytes).round(2).to_s + 'MiB'
    elsif toGiB(bytes) < 1024
      return toGiB(bytes).round(2).to_s + 'GiB'
    end    
  end
  
end
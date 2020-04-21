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
  def self.parse(str)
    if str =~ /KiB/
      return KiB(str[0...-3].to_f)
    end
    if str =~ /MiB/
      return MiB(str[0...-3].to_f)
    end
    if str =~ /GiB/
      return GiB(str[0...-3].to_f)
    end
  end
  
end
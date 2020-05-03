require 'zlib'

class Archive
  
  @@buffer = FS.parse( '64MiB' )
  
  def initialize()
    throw 'not for initialization'
  end
  
  def self.zip(path)
    if File.exist?(path)
      archPath = path + '.gz'
      File.open(path, 'rb') {|rf|
        File.open(archPath, 'wb') {|wf|
          while input = rf.read(@@buffer)
            writestr = Zlib.gzip(input, level: Zlib::BEST_COMPRESSION)
            writelength = Uint32.f(writestr.length)
            wf.write(writelength.to_s + writestr)
          end
        }
      }
    end
  end
  
  def self.unzip(path)
    if File.exist?(path)
      unPath = path.split('.')[0..-2].join('.')
      File.open(path, 'rb') {|rf|
        File.open(unPath, 'wb') {|wf|
          while input = rf.read(Uint32.size)
            input = rf.read(Uint32.to_i(input))
            wf.write(Zlib.gunzip(input))
          end
        }
      }
    end
  end
  
end
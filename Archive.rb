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
            wf.write(Zlib.gzip(input, level: Zlib::BEST_COMPRESSION))
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
          while input = rf.read(@@buffer)
            wf.write(Zlib.gunzip(input))
          end
        }
      }
    end
  end
  
end
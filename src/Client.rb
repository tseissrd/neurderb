require './Networking.rb'

class Client
  
  include MC
  
  def initialize(server_ip = '127.0.0.1', server_port = '56551', buffer_length = '4MiB')
    @server_ip = server_ip
    @server_port = server_port
    @buffer_length = FS.parse(buffer_length)
    @shkey = ''
  end
  
  def open()
	@tcp = TCPSocket.new @server_ip, @server_port
    @tcp.binmode
  end
  
  def import_key(path)
    if File.exist?(path)
      File.open(path, 'rb') {|keyfile|
        @shkey = keyfile.read.chomp('')
      }
    end
  end
  
  def read_config(path)
    if File.exist?(path)
      File.open(path, 'r') {|conf|
        conf.each_line {|ln|
          case ln.split('=')[0]
            when 'server_ip'
              @server_ip = ln.split('=')[1].chomp('')
            when 'server_port'
              @server_port = ln.split('=')[1].chomp('')
            when 'read_buffer'
              @buffer_length = FS.parse(ln.split('=')[1].chomp(''))
          end
        }
      }
    end
  end
  
  def send_message(msg)
    @tcp.write(Bstring.f(msg))
    @tcp.read(1)
  end
  
  def send_file(path)
    path = path.chomp('')
    srvpath = path
    if srvpath.split(':').length > 1
      srvpath = srvpath.split(':')[-1]
    end
    srvpath = srvpath.split('/')[-1]
    readit = 0
    if !File.exist?(path)
      puts "#{path} does not exist"
      return false
    end
    
    #authorize
    @tcp.write(Bstring.f(@shkey))
    resp = @tcp.read(1)
    puts T.readMsgSafe(@tcp)
    if resp === CANCEL
      return false
    end
    
    #signal for receiving
    @tcp.write(Bstring.f('file_receive'))
    @tcp.read(1)
    
    #begin transmission
    sha1 = T.sha1(path)
    File.open(path,'rb') {|fl|
      readit = 0
      @tcp.write(Bstring.f(srvpath))
      @tcp.read(1)
      @tcp.write(Bstring.f(sha1))
      @tcp.read(1)
      while input = fl.read(@buffer_length)
        @tcp.write(Bstring.f(input))
        readit += input.length
        @tcp.read(1)
      end
      @tcp.write(Bstring.f(EOT))
      if @tcp.read(1) === TAB
        puts "#{path.split('/')[-1]} #{FS.readable(readit)} done."
        return sha1
      else
        puts "#{path.split('/')[-1]} failed."
        return false
      end
    }
  end
  
  def get_file(path, tarpath = 'test/' + path, sha1 = 'any')
    
	path = path.chomp('')
	tarpath = tarpath.chomp('')
	
    #authenticate
    @tcp.write(Bstring.f(@shkey))
    resp = @tcp.read(1)
    puts T.readMsgSafe(@tcp)
    if resp === CANCEL
      return false
    end
    
    #signal for sending
    @tcp.write(Bstring.f('file_send'))
    if @tcp.read(1) === CANCEL
      puts T.readMsgSafe(@tcp)
      return false
    end
    
    #send filename
    @tcp.write(Bstring.f(path))
    if @tcp.read(1) === CANCEL
      puts T.readMsgSafe(@tcp)
      return false
    end
    
    #send checksum
    @tcp.write(Bstring.f(sha1))
    if @tcp.read(1) === CANCEL
      puts T.readMsgSafe(@tcp)
      return false
    end
	
    #prepare dir tree
    path = tarpath.chomp('')
    pathArr = tarpath.split('/')
    fullpath = ''
    if pathArr.length > 1
      pathArr[0..(-2)].each {|dn|
        fullpath += dn + '/'
        if !Dir.exist?(fullpath)
          Dir.mkdir(fullpath)
        end
      }
    end
    
    #begin transmission
    writeit = 0
    File.new(tarpath, 'wb').close
    while true
      input = T.readMsgSafe(@tcp)
      if input === EOT
        @tcp.write(TAB)
        puts "done reading #{path} #{FS.readable(writeit)}"
        break
      end
      File.open(tarpath, 'ab') {|wf|
        writeit += wf.write(input)
      }
      @tcp.write(TAB)
    end
    sha1 = T.readMsgSafe(@tcp)
    @tcp.write(TAB)
    if sha1 === T.sha1(tarpath)
      puts "verified #{path}"
    else
      puts "sha-1 verification failed on #{path}"
    end
    
  end
  
  def close
    @tcp.close
  end
  
end
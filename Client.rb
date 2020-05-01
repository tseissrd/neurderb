require './Networking.rb'

class Client
  
  include MC
  
  def initialize(server_ip = '127.0.0.1', server_port = '56551', buffer_length = '4MiB')
    @server_ip = server_ip
    @server_port = server_port
    @tcp = TCPSocket.new @server_ip, @server_port
    @tcp.binmode
    @buffer_length = FS.parse(buffer_length)
    @shkey = ''
  end
  
  def import_key(path)
    if File.exist?(path)
      File.open(path, 'rb') {|keyfile|
        @shkey = keyfile.read.chomp('')
      }
    end
  end
  
  def send_message(msg)
    @tcp.write(Bstring.f(msg))
    @tcp.read(1)
  end
  
  def send_file(path)
    path.chomp!('')
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
    File.open(path,'rb') {|fl|
      readit = 0
      @tcp.write(Bstring.f(path.split('/')[-1]))
      @tcp.read(1)
      while input = fl.read(@buffer_length)
        @tcp.write(Bstring.f(input))
        readit += input.length
        @tcp.read(1)
      end
      @tcp.write(Bstring.f(EOT))
      puts "#{path.split('/')[-1]} #{FS.readable(readit)} done."
    }
  end
  
  def get_file(path)
    #prepare dir tree
    path.chomp!('')
    pathArr = path.split('/')
    fullpath = ''
    if pathArr.length > 1
      pathArr[0..(-2)].each {|dn|
        fullpath += dn + '/'
        if !Dir.exist?(fullpath)
          Dir.mkdir(fullpath)
        end
      }
    end
    
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
    
    #begin transmission
    writeit = 0
    File.new('test/' + path, 'wb').close
    while true
      input = T.readMsgSafe(@tcp)
      if input === EOT
        puts "done reading #{path} #{FS.readable(writeit)}"
        break
      end
      File.open('test/' + path, 'ab') {|wf|
        writeit += wf.write(input)
      }
      @tcp.write(TAB)
    end
    
  end
  
  def close
    @tcp.close
  end
  
end
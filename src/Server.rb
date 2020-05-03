require './Networking.rb'
require './Archive.rb'

#stdout = IO.new(1,'w')

class Server
  
  include MC

  def initialize(ip = '127.0.0.1', port = '56551')
    @server_ip = ip
    @server_port = port
    @dataFolder = '../data/'
    @confFolder = '../conf/'
    @keys = {}
    @pendingZip = []
    @zipping = []
    @buffer_length = FS.parse( '4MiB' )
  end
  
  def read_keys(path = (@confFolder + 'keys.txt'))
    @keys = {}
    if File.exist?(path)
      File.open(path, 'rb') {|rf|
        rf.each_line {|ln|
          @keys[ln.split('<%%E>')[0]] = ln.split('<%%E>')[1]
        }
      }
    end
  end
  
  def set_work_dir(path)
    wdpath = path
    if wdpath[-1] != '/'
      wdpath = wdpath + '/'
    end
    if !Dir.exist?(wdpath)
      Dir.mkdir(wdpath)
    end
    @dataFolder = wdpath
  end
  
  def set_conf_dir(path)
    cfpath = path
    if cfpath[-1] != '/'
      cfpath = cfpath + '/'
    end
    if !Dir.exist?(cfpath)
      Dir.mkdir(cfpath)
    end
    @confFolder = cfpath
  end
  
  def read_conf
    path = @confFolder + 'config.ini'
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
  
  def authorize(shkey)
    if @keys.key?(shkey)
      [shkey[-32..-1], @keys[shkey]]
    else
      false
    end
  end
  
  def ls(folder)
    path = @dataFolder + folder
    if Dir.exist?(path)
      Dir.children(path)
    end
  end
  
  def start(listeners_count, zippers_count)
    zippers = []
    listeners = []
      
    archive = Task.queue {
      while true
        pendingLength = 0
        pending = []
        Task.sync('pendingZip') {
          pendingLength = @pendingZip.length
          if pendingLength > zippers_count
            pendingLength = zippers_count
          end
          pending = @pendingZip[0...pendingLength]
        }
        pending.each {|fn|
          Task.sync('pendingZip') {
            @pendingZip.delete(fn)
          }
          Task.sync('zipping') {
            @zipping.push(fn)
          }
          zippers.push Task.queue {
            origSize = FS.readable(File.size(@dataFolder + fn))
            if File.exist?(@dataFolder + fn + '.gz')
              File.rename(@dataFolder + fn + '.gz', @dataFolder + fn + '.gz.bak')
            end
            puts 'zipping ' + fn
            Archive.zip(@dataFolder + fn)
            File.delete(@dataFolder + fn)
            newSize = FS.readable(File.size(@dataFolder + fn + '.gz'))
            puts "done zipping #{fn}: #{origSize} => #{newSize}"
            Task.sync('zipping') {
              @zipping.delete(fn)
            }
          }
        }
        sleep 5
      end
    }
      
    server = Task.queue {
      TCPServer.open(@server_ip, @server_port) {|tcp|
        tcp.binmode
        listeners_count.times {
            Socket.accept_loop(tcp) {|sock, client|
              listeners.push Task.queue {
              server_tasks = []
              eraseExisting = true
              eof = false
              writing = true
              outio = ''
              filename = ''
              writeit = 0
              clientPath = ''
              sha1 = ''
              shachk = ''
              
              #WRITER
              Task.queue {
                while true
                  Task.sync {
                    if writing
                      if outio.length > 0
                        if !Dir.exist?(@dataFolder + clientPath + filename + '/' + sha1)
                          if !Dir.exist?(@dataFolder + clientPath + filename)
                            if !Dir.exist?(@dataFolder + clientPath)
                              Dir.mkdir(@dataFolder + clientPath)
                            end
                            Dir.mkdir(@dataFolder + clientPath + filename)
                          end
                          Dir.mkdir(@dataFolder + clientPath + filename + '/' + sha1)
                        end
                        if eraseExisting
                          eraseExisting = false
                          File.new(@dataFolder + clientPath + filename + '/' + sha1 + '/' + filename, 'w').close
                        end
                        File.open(@dataFolder + clientPath + filename + '/' + sha1 + '/' + filename, 'ab') {|fl|
                          writeit += fl.write(outio)
                          outio = ''
                        }
                      elsif eof
                        while sha1 === ''
                          sleep 0.1
                        end
                        serversha1 = T.sha1(@dataFolder + clientPath + filename + '/' + sha1 + '/' + filename)
                        if serversha1 === sha1
                          shachk = true
                          File.open(@dataFolder + clientPath + filename + '/last.txt', 'wb') {|last|
                            last.write(serversha1)
                          }
                          puts "#{filename} #{FS.readable(writeit)} ok"                          
                          Task.sync('pendingZip') {
                            @pendingZip.push(clientPath + filename + '/' + sha1 + '/' + filename)
                          }
                          writing = false
                          writeit = 0
                          eraseExisting = true
                          eof = false
                        else
                          shachk = false
                          puts "sha-1 check failed on #{filename}"
                          writing = false
                          writeit = 0
                          eraseExisting = true
                          eof = false
                          File.delete(filename)
                        end
                      end
                    end
                  }
                  sleep 0.1
                end
              }
              
              begin
                input = ''
                
                #authorize
                client = authorize(T.readMsgSafe(sock))
                puts client[1]
                if !client
                  T.closeConnection(sock, 'invalid key')
                  Task.done
                else
                  sock.write(MSG)
                  sock.write(Bstring.f(client[1]))
                end
                clientPath = client[0] + '/'
                
                #get action signal
                cmd = T.readMsgSafe(sock)
                
                #RECEIVE FILE
                if cmd === 'file_receive'
                  sock.write(TAB)
                  
                  #begin transmission
                  filename = T.readMsgSafe(sock)
                  
                  #check for access violation
                  if filename.split('..').length > 1 || filename.split(':').length > 1
                    T.closeConnection(sock, 'access violation')
                    Task.done
                  end
                  sock.write(TAB)
                  
                  sha1 = T.readMsgSafe(sock)
                  
                  eof = false
                  writing = true
                  puts "receiving #{filename} from #{client[1]}"
                  sock.write(TAB)
                  while true
                    length = Uint32.to_i(sock.read(Uint32.size))
                    input = sock.read(length)
                    if input === EOT
                      break
                    end
                    Task.sync('outio') {
                      outio += input
                    }
                    sock.write(TAB)
                    #puts 'waiting for tab'
                  end
                  Task.sync('eof') {
                    eof = true
                  }
                  while shachk === ''
                    sleep 0.1
                  end
                  if shachk
                    sock.write(TAB)
                  else
                    sock.write(CANCEL)
                  end
                
                #SEND FILE
                elsif cmd === 'file_send'
                  sock.write(TAB)
                  filename = T.readMsgSafe(sock)
                  if filename.split('..').length > 1 || filename.split(':').length > 1
                    T.closeConnection(sock, 'access violation')
                    Task.done
                  end
                  if Dir.exist?(@dataFolder + clientPath + filename)
                    sock.write(TAB)
                    sha1 = T.readMsgSafe(sock)
                    if sha1 === 'any'
                      if File.exist?(@dataFolder + clientPath + filename + '/last.txt')
                        File.open(@dataFolder + clientPath + filename + '/last.txt', 'rb') {|last|
                          sha1 = last.read
                        }
                      end
                    end
                    if Dir.exist?(@dataFolder + clientPath + filename + '/' + sha1)
                      if File.exist?(@dataFolder + clientPath + filename + '/' + sha1 + '/' + filename + '.gz')
                        if !@zipping.include?(clientPath + filename + '/' + sha1 + '/' + filename) && !@pendingZip.include?(clientPath + filename + '/' + sha1 + '/' + filename)
                          puts "sending #{filename} to #{client[1]}"
                          sock.write(TAB)
                          #Task.queue {
                            Archive.unzip(@dataFolder + clientPath + filename + '/' + sha1 + '/' + filename + '.gz')
                            File.open(@dataFolder + clientPath + filename + '/' + sha1 + '/' + filename, 'rb') {|rf|
                              while input = rf.read(@buffer_length)
                                #File.binwrite('test.txt', input)
                                writeit += sock.write(Bstring.f(input))
                                if sock.read(1) != TAB
                                  sock.close
                                  Task.done
                                end
                              end
                            }
                            sock.write(Bstring.f(EOT))
                            sock.read(1)
                            sock.write(Bstring.f(T.sha1(@dataFolder + clientPath + filename + '/' + sha1 + '/' + filename)))
                            sock.read(1)
                            puts "sent #{FS.readable(writeit)} of #{filename} to #{client[1]}"
                            File.delete(@dataFolder + clientPath + filename + '/' + sha1 + '/' + filename)
                            #Task.done
                          #}
                        else
                          T.closeConnection(sock, 'still processing')
                          Task.done
                        end
                      else
                        T.closeConnection(sock, 'server error')
                        Task.done
                      end
                    else
                      T.closeConnection(sock, 'no such revision')
                      Task.done
                    end
                  else
                    T.closeConnection(sock, 'not found')
                    Task.done
                  end
                  
                #UNKNOWN SIGNAL
                else
                  sock.write(MSG)
                  T.closeConnection(sock, 'unknown signal')
                  Task.done
                end
                
              ensure
                sock.close
              end
            }
          }
        }
        Task.wait(listeners)
      }
    }
    puts "Listening on #{@server_ip}:#{@server_port}"
    Task.wait(server)
    Task.wait(archive)
  end
  
end
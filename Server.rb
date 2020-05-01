require './Networking.rb'
require './Archive.rb'

#stdout = IO.new(1,'w')

class Server
  
  include MC

  def initialize(ip = '127.0.0.1', port = '56551')
    @server_ip = ip
    @server_port = port
    @dataFolder = './data/'
    @confFolder = './conf/'
    @keys = {}
    @pendingZip = []
    @zipping = []
    @readbuf = FS.parse( '4MiB' )
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
              eof = true
              writing = true
              outio = ''
              filename = ''
              writeit = 0
              clientPath = ''
                
              Task.queue {
                while true
                  Task.sync {
                    if writing
                      if outio.length > 0
                        if !Dir.exist?(@dataFolder + clientPath)
                          Dir.mkdir(@dataFolder + clientPath)
                        end
                        if eraseExisting
                          eraseExisting = false
                          File.new(@dataFolder + clientPath + filename, 'w').close
                        end
                        File.open(@dataFolder + clientPath + filename, 'ab') {|fl|
                          writeit += fl.write(outio)
                          outio = ''
                          if eof
                            puts "#{filename} #{FS.readable(writeit)} ok"
                            Task.sync('pendingZip') {
                              @pendingZip.push(clientPath + filename)
                            }
                            writing = false
                            writeit = 0
                            eraseExisting = true
                          end
                        }
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
                  if filename.split('..').length > 1
                    T.closeConnection(sock, 'access violation')
                    Task.done
                  end
                  
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
                    Task.sync {
                      outio += input
                    }
                    sock.write(TAB)
                  end
                  Task.sync {
                    eof = true
                  }
                
                #SEND FILE
                elsif cmd === 'file_send'
                  sock.write(TAB)
                  filename = T.readMsgSafe(sock)
                  if File.exist?(@dataFolder + clientPath + filename + '.gz')
                    if !@zipping.include?(clientPath + filename)
                      puts "sending #{filename} to #{client[1]}"
                      sock.write(TAB)
                      #Task.queue {
                        Archive.unzip(@dataFolder + clientPath + filename + '.gz')
                        File.open(@dataFolder + clientPath + filename, 'rb') {|rf|
                          while input = rf.read(@readbuf)
                            #File.binwrite('test.txt', input)
                            writeit += sock.write(Bstring.f(input))
                            if sock.read(1) != TAB
                              sock.close
                              Task.done
                            end
                          end
                        }
                        sock.write(Bstring.f(EOT))
                        sock.close
                        puts "sent #{FS.readable(writeit)} of #{filename} to #{client[1]}"
                        File.delete(@dataFolder + clientPath + filename)
                        #Task.done
                      #}
                    else
                      T.closeConnection(sock, 'still processing')
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
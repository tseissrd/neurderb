require './Networking.rb'
require './Archive.rb'
require './NeuralNetworks.rb'
require 'get_process_mem'
require 'sys-cpu'

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
    @DFsize = 0
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
  
  def set_data_dir(path)
    dfpath = path
    if dfpath[-1] != '/'
      dfpath = dfpath + '/'
    end
    if !Dir.exist?(dfpath)
      Dir.mkdir(dfpath)
    end
    @dataFolder = dfpath
  end
  
  def calc_data_size
    out = 0
    Dir.each_child(@dataFolder) {|user|
      userf = @dataFolder + user
      if File.directory?(userf)
        Dir.each_child(userf) {|file|
          filef = userf + '/' + file
          if File.directory?(filef)
            Dir.each_child(filef) {|sha|
              shaf = filef + '/' + sha
              if File.directory?(shaf)
                Dir.each_child(shaf) {|data|
                  dataf = shaf + '/' + data
                  out += File.size(dataf)
                }
              else
                out += File.size(shaf)
              end
            }
          else
            out += File.size(userf)
          end
        }
      else
        out += File.size(userf)
      end
    }
    change_data_size(out)
    out
  end
  
  def change_data_size(inc)
    Task.sync('DFsize') {
      @DFsize += inc
    }
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
            when 'ram_target'
              @ram_target = FS.parse(ln.split('=')[1].chomp(''))
            when 'ram_max'
              @ram_max = FS.parse(ln.split('=')[1].chomp(''))
            when 'fs_target'
              @fs_target = FS.parse(ln.split('=')[1].chomp(''))
            when 'fs_max'
              @fs_max = FS.parse(ln.split('=')[1].chomp(''))
            when 'cpu_target'
              @cpu_target = ln.split('=')[1].chomp('').to_f
            when 'cpu_max'
              @cpu_max = ln.split('=')[1].chomp('').to_f
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
  
  def start(listeners_count = 1, zippers_count = 1)
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
          zippers.push Task.queue('zippers') {
            origSize = File.size(@dataFolder + fn)
            if File.exist?(@dataFolder + fn + '.gz')
              File.rename(@dataFolder + fn + '.gz', @dataFolder + fn + '.gz.bak')
            end
            puts 'zipping ' + fn
            Archive.zip(@dataFolder + fn)
            File.delete(@dataFolder + fn)
            newSize = File.size(@dataFolder + fn + '.gz')
            change_data_size(newSize - origSize)
            puts "done zipping #{fn}: #{FS.readable(origSize)} => #{FS.readable(newSize)}"
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
              listeners.push Task.queue('listeners') {
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
              writer = Task.queue('writers') {
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
                          change_data_size(outio.length)
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
                          if File.exist?(@dataFolder + clientPath + filename + '/last.txt')
                            File.open(@dataFolder + clientPath + filename + '/last.txt', 'rb') {|last|
                              File.open(@dataFolder + clientPath + filename + '/last.txt.temp', 'wb') {|tmp|
                                tmp.write(serversha1 + "\n")
                                last.each_line {|ln|
                                  tmp.write(ln)
                                }
                              }
                            }
                            change_data_size(File.size(@dataFolder + clientPath + filename + '/last.txt.temp')-File.size(@dataFolder + clientPath + filename + '/last.txt'))
                            File.delete(@dataFolder + clientPath + filename + '/last.txt')
                            File.rename(@dataFolder + clientPath + filename + '/last.txt.temp', @dataFolder + clientPath + filename + '/last.txt')
                          elsif
                            File.open(@dataFolder + clientPath + filename + '/last.txt', 'wb') {|last|
                              last.write(serversha1)
                            }
                            change_data_size(File.size(@dataFolder + clientPath + filename + '/last.txt'))
                          end
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
                          change_data_size(-File.size(filename))
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
                if !client
                  T.closeConnection(sock, 'invalid key')
                  Task.done
                else
                  sock.write(MSG)
                  sock.write(Bstring.f(client[1]))
                  puts client[1]
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
                  
                  #REMOVE FILE
                  elsif cmd === 'file_remove'
                    sock.write(TAB)
                    filename = T.readMsgSafe(sock)
                    if filename.split('..').length > 1 || filename.split(':').length > 1
                      T.closeConnection(sock, 'access violation')
                      Task.done
                    end
                    if Dir.exist?(@dataFolder + clientPath + filename)
                      sock.write(TAB)
                      sha1 = T.readMsgSafe(sock)
                      if sha1 === 'all' || (Dir.children(@dataFolder + clientPath + filename).length < 3)
                        if !@zipping.include?(Regexp.new(clientPath + filename + '/.+')) && !@pendingZip.include?(Regexp.new(clientPath + filename + '/.+'))
                          puts "removing #{filename} from #{client[1]}"
                          Dir.each_child(@dataFolder + clientPath + filename) {|fnf|
                            if File.directory?(@dataFolder + clientPath + filename + '/' + fnf)
                              Dir.each_child(@dataFolder + clientPath + filename + '/' + fnf) {|shaf|
                                change_data_size(-File.size(@dataFolder + clientPath + filename + '/' + fnf + '/' + shaf))
                                File.delete(@dataFolder + clientPath + filename + '/' + fnf + '/' + shaf)
                              }
                              Dir.delete(@dataFolder + clientPath + filename + '/' + fnf)
                            else
                              change_data_size(-File.size(@dataFolder + clientPath + filename + '/' + fnf))
                              File.delete(@dataFolder + clientPath + filename + '/' + fnf)
                            end
                          }
                          Dir.delete(@dataFolder + clientPath + filename)
                          sock.write(TAB)
                          puts "done removing #{filename} from #{client[1]}"
                        else
                          T.closeConnection(sock, 'still processing')
                          Task.done
                        end
                      else
                        if sha1 === 'last'
                          if File.exist?(@dataFolder + clientPath + filename + '/last.txt')
                            File.open(@dataFolder + clientPath + filename + '/last.txt', 'rb') {|last|
                              sha1 = last.readline.chomp('')
                            }
                          end
                        end
                        if Dir.exist?(@dataFolder + clientPath + filename + '/' + sha1)
                          if File.exist?(@dataFolder + clientPath + filename + '/' + sha1 + '/' + filename + '.gz')
                            if !@zipping.include?(clientPath + filename + '/' + sha1 + '/' + filename) && !@pendingZip.include?(clientPath + filename + '/' + sha1 + '/' + filename)
                              puts "removing #{filename}@#{sha1} from #{client[1]}"
                              change_data_size(-File.size(@dataFolder + clientPath + filename + '/' + sha1 + '/' + filename + '.gz'))
                              File.delete(@dataFolder + clientPath + filename + '/' + sha1 + '/' + filename + '.gz')
                              Dir.delete(@dataFolder + clientPath + filename + '/' + sha1)
                              File.open(@dataFolder + clientPath + filename + '/last.txt', 'rb') {|last|
                                File.open(@dataFolder + clientPath + filename + '/last.txt.temp', 'wb') {|tmp|
                                  last.each_line {|ln|
                                    if ln.chomp('') != sha1
                                      tmp.write(ln)
                                    end
                                  }
                                }
                              }
                              
                              change_data_size(File.size(@dataFolder + clientPath + filename + '/last.txt.temp')-File.size(@dataFolder + clientPath + filename + '/last.txt'))
                              File.delete(@dataFolder + clientPath + filename + '/last.txt')
                              File.rename(@dataFolder + clientPath + filename + '/last.txt.temp', @dataFolder + clientPath + filename + '/last.txt')
                              sock.write(TAB)
                              puts "done removing #{filename}@#{sha1} from #{client[1]}"
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
                      end
                    else
                      T.closeConnection(sock, 'not found')
                      Task.done
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
                          sha1 = last.readline.chomp('')
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
                            change_data_size(File.size(@dataFolder + clientPath + filename + '/' + sha1 + '/' + filename))
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
                            change_data_size(-File.size(@dataFolder + clientPath + filename + '/' + sha1 + '/' + filename))
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
                  T.closeConnection(sock, 'unknown signal')
                  Task.done
                end
                
              ensure
                sock.close
              end
              Task.wait(writer)
            }
          }
        }
        Task.wait(listeners)
      }
    }
    
    #neural controller initialization
    netw = ''
    if File.exist?("planning.cfg")
      perc = NeuralNetwork.new()
      perc.loadFile('planning.cfg')
    else
      perc = NeuralNetwork.newPerceptron(9,6,6,3)
    end
    #if File.exist?("planningSOM.cfg")
    #  som = NeuralNetwork.new()
    #  som.loadFile('planningSOM.cfg')
    #else
      som = SelfOrganizing.newSOM(500, [ [0,1], [0,1], [0,1], [0,50], [0,50], [0,50] ])
      #som = SelfOrganizing.newSOM(50, [ [0,1], [0,1], [0,1] ])
    #end
    
    i = 0
    cycles = 100
    accuracy = 0
    #patterns
    patterns = []
    preparation_tasks = []
    cycles.times {
      preparation_tasks.push Task.queue {
        #INS
        #utilization
        cpu = Random.rand
        rmu = Random.rand
        fsu = Random.rand
        #current maxima
        maxl = Random.rand(0..50)
        maxw = Random.rand(0..50)
        maxz = Random.rand(0..50)
        
        #TEMPLATE OUTPUTS
        cl = 1 - 1.2 * cpu
        rl = 1 - 1.2 * rmu
        fl = 0
        specl = 0
        if maxl > maxw
          specl = -1.3
        end
        dl = cl + rl + fl + specl
        dl = 0 if (dl < 0) && (maxl === 1)
        
        cw = 1 - 4 * cpu
        rw = -2 + 7 * rmu
        fw = 5 - 10 * fsu
        dw = cw + rw + fw
        dw = maxl - maxw if maxl - maxw < cw + rw + fw 
        dw = 0 if (dw < 0) && (maxw === 1)
        
        cz = 2 - 7 * cpu
        rz = 2 - 7 * rmu
        fz = -2 + 7 * fsu
        dz = cz + rz + fz
        dz = 0 if (dz < 0) && (maxz === 0)
        Task.sync('patterns') {
          patterns.push([[cpu,rmu,fsu,maxl.to_f/50,maxw.to_f/50,maxz.to_f/50], perc.createPattern([dl,dw,dz])])
        }
      }
    }
    Task.wait(preparation_tasks)
    
    time_start = Time.new
    puts 'training started'
    
    timer = Task.queue {
      while i < cycles
        sleep 15
        puts "#{i}/#{cycles} (#{(i.to_f/cycles*100).round(1)}%) -- #{((Time.new - time_start).to_f/60).round(2)}min. elapsed -- accuracy ~#{(accuracy.to_f/i).round(2)}"
      end
    }
    
    patterns.each {|pat|
      #TRAINING
      begin
        insSOM = pat[0]
        outsSOM = som.makeInput(insSOM).center
        som.activateAll
        som.train
        ins = outsSOM + [@cpu_target,@ram_target,@fs_target]
        perc.inputLayer.setActivation(ins)
        output = perc.evaluate
        
        perc.train(pat[1])
        
        immediate_accuracy = 0
        cc = -1
        output.each {|neu|
          cc += 1
          #puts 'neu'
          #puts neu[1]
          #puts 'pat'
          #puts pat[1][cc][1]
          immediate_accuracy += (1 - (neu[1] - pat[1][cc][1]).to_f.abs/pat[1][cc][1].abs)*100
        }
        #puts 'immediate_accuracy'
        #puts immediate_accuracy
        accuracy += immediate_accuracy.to_f/3
        #puts 'accuracy'
        #puts accuracy
        
        i += 1
      ensure
        perc.saveFile('planning.cfg')
      end
    }
    
    time_elapsed = Time.new - time_start
    puts "trained #{cycles} samples in #{(time_elapsed.to_f/60).round(2)}min. / #{(cycles.to_f/time_elapsed.to_f).round(2)} samples/s.}"
    
    #perc.inputLayer.setActivation([0.2,0.1,0.95] + [@cpu_target,@ram_target,@fs_target])
    perc.inputLayer.setActivation([0.2,0.1,0.95,15.to_f/50,15.to_f/50,2.to_f/50] + [@cpu_target,@ram_target,@fs_target])
    puts perc.evaluate()
    return
    
    planning = Task.queue {
      while true
        #OUTS
        #Task.groupMax('listeners') - +CPU, +RAM
        #Task.groupMax('writers') - +CPU, -RAM, +FS
        #Task.groupMax('zippers') - +CPU, +RAM, -FS
        
        #INS
        #GetProcessMem.new.bytes
        #Sys::CPU.load_avg
        #DFsize
        #@cpu_max
        #@ram_max
        #@fs_max
        #---------------
        #PERCEPTRON ONLY:
        #@cpu_target
        #@ram_target
        #@fs_target
        
        #raw usage data
        r_cpu = Sys::CPU.load_avg
        r_ram = GetProcessMem.new.bytes.to_f
        r_fs = @DFsize
        
        #max percentage usage data
        p_cpu = r_cpu.to_f/@cpu_max
        p_ram = r_ram.to_f/@ram_max
        p_fs = r_fs.to_f/@fs_max
        
        puts "CPU: #{r_cpu}"
        puts "RAM: #{FS.readable(r_ram)}"
        puts "FS: #{FS.readable(r_fs)}"
        puts p_cpu
        puts p_ram
        puts p_fs
        
        
        
        sleep 10
      end
    }
    puts "data folder size: #{FS.readable(calc_data_size)}"
    puts "Listening on #{@server_ip}:#{@server_port}"
    Task.wait(server)
    Task.wait(archive)
    Task.wait(planning)
  end
  
end
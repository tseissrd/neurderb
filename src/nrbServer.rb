require './Server.rb'

Task.max = 20

serv = Server.new
serv.read_conf
serv.read_keys
Task.queue {
  serv.start(5, 3)
}

puts serv.ls('2f1j48ijf214891j4712fjj982f1j48')

Task.wait
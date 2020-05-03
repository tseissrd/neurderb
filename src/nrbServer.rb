require './Server.rb'

Task.max = 20

serv = Server.new
serv.set_work_dir('../data')
serv.read_conf
serv.read_keys
Task.queue {
  serv.start(5, 3)
}

Task.wait
require './Server.rb'

Task.max = 100

serv = Server.new
serv.set_data_dir('../data')
serv.read_conf
serv.read_keys
#1 server itself, 1 archieve + 1 zipper, 1 listener + 1 writer = 5 tasks min 
#Task.groupMax('listeners', 1)
#Task.groupMax('')
serv.start
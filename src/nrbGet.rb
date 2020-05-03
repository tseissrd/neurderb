require './Client.rb'

client = Client.new
client.import_key('../shkey.txt')
client.read_config('../config.ini')
client.open
client.get_file(ARGV[0], ARGV[1], ARGV[2])
client.close
require './Client.rb'
require './ssh/Ssh.rb'
require './FS.rb'

while true
  puts 'r/w'
  cmd = gets.chomp('')
  puts 'enter name of the file'
  file = gets
  client = Client.new('127.0.0.1','56551','4MiB')
  client.import_key('./shkey.txt')
  if cmd === 'w'
    client.send_file(file)
  elsif cmd === 'r'
    client.get_file(file)
  end
  client.close
end
require './Client.rb'
require './ssh/Ssh.rb'
require './FS.rb'

while true
  client = Client.new('127.0.0.1','56551','4MiB')
  puts 'r/w - read/write files, q - quit'
  cmd = gets.chomp('')
  if cmd === 'q'
    break
  end
  puts 'enter name of the file'
  file = gets
  client.import_key('../shkey.txt')
  client.read_config('../config.ini')
  client.open
  if cmd === 'w'
    client.send_file(file)
  elsif cmd === 'r'
    client.get_file(file)
  end
  client.close
end
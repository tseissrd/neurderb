require './Client.rb'
require './ssh/Ssh.rb'
require './FS.rb'

if ARGV.length === 0
  while true
    client = Client.new
	  puts 'r/w/d - read/write/delete files, q - quit'
	  cmd = gets.chomp('')
	  if cmd === 'q'
	    break
	  end
	  puts 'enter path to the file'
	  input = gets.chomp('').split(':')
	  file = input[0]
	  sha = ''
	  if input.length > 1
	    sha = input[1]
	  end
	  client.import_key
	  client.read_config
	  client.open
	  if cmd === 'w'
	    time_start = Time.new
	    if file.split('/').length > 1
	      client.send_file(file)
	    else
        client.send_file('../' + file)
	    end
	    time_elapsed = Time.new - time_start
	    puts "elapsed #{time_elapsed} s."
	  elsif cmd === 'r'
      if sha === ''
        sha = 'any'
      end
	    client.get_file(file, "../received/#{file}", sha)
	  elsif cmd === 'd'
	    if sha === ''
	      sha = 'last'
	    end
	    client.remove_file(file, sha)
	  end
    client.close
  end
else
  cmd = ARGV[0].chomp('').downcase
  case cmd
    when 'help'
      puts 'send <path> - send files to server'
      puts 'get <name[:sha|any]> [destination] - receive files from server'
      puts 'delete <name[:sha|last|all]> - delete files on server'
      puts 'help - display this info'
      puts 'example usage: "cli get testfile.txt:example_sha"'
    when 'send'
      if ARGV.length < 2
        puts 'no path specified'
        return
      end
      client = Client.new
      client.read_config
      client.import_key
      client.open
      if ARGV[1].split('/').length > 1
        client.send_file(ARGV[1].chomp(''))
      else
        client.send_file('../' + ARGV[1].chomp(''))
      end
      client.close
      return
    when 'get'
      if ARGV.length < 2
        puts 'no file specified'
        return
      end
      client = Client.new
      client.read_config
      client.import_key
      client.open
      input = ARGV[1].chomp('').split(':')
      file = input[0]
      if ARGV.length < 3
        dest = '../received/' + file
      else
        dest = ARGV[2]
      end
      sha = 'any'
      if input.length > 1
        sha = input[1]
      end
      client.get_file(file, dest, sha)
      client.close
      return
    when 'delete'
      if ARGV.length < 2
        puts 'no file specified'
        return
      end
      client = Client.new
      client.read_config
      client.import_key
      client.open
      input = ARGV[1].chomp('').split(':')
      file = input[0]
      sha = 'last'
      if input.length > 1
        sha = input[1]
      end
      client.remove_file(file, sha)
      return
    else
      puts 'try running with "cli help"'
      return
  end
end
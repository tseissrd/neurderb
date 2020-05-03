require './Client.rb'

client = Client.new
client.import_key('../shkey.txt')
client.read_config('../config.ini')
client.open
sha1 = client.send_file(ARGV[0].split('\\').join('/'))
if sha1
  fname = ARGV[0].split('\\')[-1]
  client.close
  #File.delete(ARGV[0])
  File.open(ARGV[0].split('.')[0..-2].join('.') + '.bat', 'w') {|f|
    bat = "@ECHO OFF\n"
    bat += "set pwd=%cd%\n"
    bat += "FOR /F \"usebackq tokens=3*\" %%A IN (`REG QUERY \"HKEY_LOCAL_MACHINE\\Software\\Neurderb\" /v Install_Dir`) DO (\n"
    bat += "set appdir=%%A %%B\n"
    bat += ")\n"
    bat += "FOR /F \"usebackq tokens=3*\" %%A IN (`REG QUERY \"HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Neurderb\" /v Install_Dir`) DO (\n"
    bat += "set appdir=%%A %%B\n"
    bat += ")\n"
    bat += "cd \"%appdir%/src\"\n"
    bat += "ruby nrbGet.rb #{fname} \"%pwd%/#{fname}\" #{sha1}"
    #bat += "DEL \"%~f0\""
    f.write(bat)
  }
end
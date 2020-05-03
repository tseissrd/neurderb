require 'ssh/TransportLayer.rb'

test = 'zlib,none'
#puts Hex.bytes(Bstring.f(test))
puts 'test' + Byte.f(32) + 'test'
#puts Packet.new(Bstring.f('testtest'))
#chk = false
#500000.times {
#  if (rand() * 256).floor === 255
#    chk = true
#  end
#}
#if chk
#  puts 'ok'
#end

puts 'привет'.bytes.size
puts test = Bstring.f('привет')
puts Bstring.to_s(test)
TL.exchangeKeysSend('test')
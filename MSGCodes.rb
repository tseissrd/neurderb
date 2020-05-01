require './ssh/DataTypes.rb'

module MC
  EOT = Byte.f(4)
  MSG = Byte.f(6)
  TAB = Byte.f(9)
  CANCEL = Byte.f(24)
end
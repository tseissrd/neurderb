require 'fiddle'
#require 'Win32API'

ATOM = PTR = UINT = Fiddle::TYPE_UINTPTR_T
INT = Fiddle::TYPE_INT
DOUBLE = Fiddle::TYPE_DOUBLE

puts Fiddle::Pointer['C:\Windows\System32\inetcpl.cpl']
  
def ptr(obj)
  Fiddle::Pointer[obj]
end

RT_ICON         =  3
DIFFERENCE      = 11
RT_GROUP_ICON   = RT_ICON + DIFFERENCE

NIF_MESSAGE = 1
NIF_ICON    = 2
NIF_TIP     = 4
NIM_ADD     = 0
NIM_MODIFY  = 1
NIM_DELETE  = 2

WNDCLASSA = [
    
  ]

shell32 = Fiddle::Handle.new('shell32')
user32 = Fiddle::Handle.new('user32')
#ExtractIcon       = Win32API.new('shell32',  'ExtractIconA',       'LPI',  'L')
puts shell32

register_class = Fiddle::Function.new(user32['RegisterClassA'], [PTR], ATOM)
puts register_class

create_window = Fiddle::Function.new(shell32['CreateWindowExA'],
  [
    UINT,
    UINT,
    UINT,
    
  ]
  )

extract_icon = Fiddle::Function.new(shell32['ExtractIconA'],
  [
    UINT,
    UINT,
    INT
  ],
    UINT)
puts extract_icon
#
#hicoY = ExtractIcon.call(0, 'C:\WINDOWS\system32\INETCPL.CPL', 21)  # Green tick
#hicoN = ExtractIcon.call(0, 'C:\WINDOWS\system32\INETCPL.CPL', 22)  # Red minus
#
gicon = extract_icon.call(0, ptr('C:\Windows\System32\inetcpl.cpl'), 21)
ricon = extract_icon.call(0, ptr('C:\Windows\System32\inetcpl.cpl'), 22)
puts gicon
puts ricon
#Shell_NotifyIcon  = Win32API.new('shell32',  'Shell_NotifyIconA', 'LP',   'I')
#
notify_icon = Fiddle::Function.new(shell32['Shell_NotifyIconA'],
  [
    UINT,
    UINT
  ],
    INT)
puts notify_icon
tiptxt = 'test icon (ruby)'
puts ([6*4+64, 0, 'ruby'.hash, NIF_ICON | NIF_TIP, gicon, 0].pack('LLIIIL')).size
puts 6*4 + 64
puts 'ruby'.hash
pnid = [24, 0, 'ruby'.hash, NIF_ICON, gicon].pack('LLIIL')
ret = notify_icon.call(NIM_ADD, ptr(pnid))
puts ret
p 'Err: NIM_ADD' if ret == 0
#
puts Fiddle.last_error
   sleep(15)   #  <----<<
#
pnid = [6*4+64, 0, 'ruby'.hash, NIF_ICON | NIF_TIP, 0, ricon].pack('LLIIIL') << tiptxt << "\0"*(64 - tiptxt.size)
ret = notify_icon.call(NIM_MODIFY, ptr(pnid))
puts ret
p 'Err: NIM_MODIFY' if ret == 0
#
   sleep(6)   #  <----<<
#
pnid = [6*4+64, 0, 'ruby'.hash, 0, 0, 0].pack('LLIIIL') << "\0"
ret = notify_icon.call(NIM_DELETE, ptr(pnid))
puts ret
p 'Err: NIM_DELETE' if ret == 0
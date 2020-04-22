require "Zipper"
require "FS"

testArch = Archieve.new('./testArch.zz')
testArch.add('neurde.png')
puts testArch.pending
testArch.zip
testArch.unzip

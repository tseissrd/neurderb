require "./Zipper"
require "./FS"

#testArch = Archieve.new('./testArch.zz',128,'128MiB')
#testArch.add('neurde.png')
#testArch.add('testfile.pdf')
#testArch.add('testlarge.zip')
#puts testArch.pending
#testArch.zip
#puts testArch.list
#puts FS.readable(testArch.saved)
#testArch.unzip('test')
input = 'hello hello hello hello ello lloh'
output = Zlib.gzip(input)
puts output
puts Zlib.gunzip(output)
output = Zlib.deflate(input)
puts output
puts Zlib.inflate(output)
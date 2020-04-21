require "Task"
require "FS"

class Archieve
  def initialize(path, wordsize = 16, dictsize = "64MiB")
    @path = path
    @lsNew = ['dict']
    @wordSize = wordsize
    @dictSize = FS.parse(dictsize)
  end
  def add(path)
    if File.file(path)
      @lsNew.push(path)
      puts @lsNew
      return path
    end
  end
  
  def zip
    if !(File.file?(@path))
      archieve = File.new(@path, mode="w")
      @lsNew.each do |rf|
        if File.file?(rf)
          
        end
      end
    end
  end
  
end
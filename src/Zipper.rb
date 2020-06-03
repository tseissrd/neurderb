require "./Task"
require "./FS"
require "./ssh/DataTypes.rb"

class Archieve

  ENCSTRPFX = ["%ZZenc"].pack('B')
  ENCSTRSFX = ["%"].pack('B')
  ENCRGX = Regexp.new("^#{ENCSTRPFX}[0-9]+#{ENCSTRSFX}")

  BEGFSTRPFX = ["%ZZbegf"].pack('B')
  BEGFSTRSFX = ["%"].pack('B')
  BEGFRGX = Regexp.new("^#{BEGFSTRPFX}.+#{BEGFSTRSFX}")

  def initialize(path, wordsize = 16, dictsize = "64MiB")
    @path = path
    @wordSize = FS.parse(wordsize)
    @dictSize = FS.parse(dictsize)
    @lsNew = []
    @writeit = 0
    @readbuf = FS.parse("6MiB")
  end

  def write(path, dict)
    if File.file?(@path)
      if File.file?(path)
        input = "#{BEGFSTRPFX}#{path}#{BEGFSTRSFX}"
        @writeit += IO.binwrite(@path,input,@writeit)
        File.open(path, "r") {|fl|
          while input = fl.read(@wordSize)
            if !(dict[input])
              if ((dict.size + 1) * @wordSize) < @dictSize
                dict[input] = @writeit
              end
            else
              input = "#{ENCSTRPFX}#{dict[input]}#{ENCSTRSFX}"
            end
            @writeit += IO.binwrite(@path,input,@writeit)
          end
        }
      end
    end
  end

  def read(arc,path,readit)
    if File.file?(@path)
      if !(File.file?(path))
        writeit = 0
        arc.seek(readit)
        File.new(path,"w").close
        #File.open(@path,"r") {|arc|
          while input = arc.read(@wordSize)
            if input =~ BEGFRGX
              sstr = input.scan(BEGFRGX).last
              return arc.tell - @wordSize + sstr.length
            end
            if input =~ ENCRGX
              sstr = input.scan(ENCRGX).last
              prevPos = arc.tell - @wordSize + sstr.length
              arc.seek(sstr[6...-1].to_i)
              input = arc.read(@wordSize)
              arc.seek(prevPos)
            end
            writeit += IO.binwrite(path,input,writeit)
          end
        #}
      end
    end
  end

  def add(path)
    if File.file?(path)
      @lsNew.push(
        {
          label: path,
          size: '*'
        }
        )
      return path
    end
  end

  def zip
    if !(File.file?(@path))
      File.new(@path, "w").close
      dict = {}
      @lsNew.each do |rf|
        rfl = rf[:label]
        if File.file?(rfl)
          write(rfl, dict)
        end
      end
    end
  end

  def unzip(unzippath)
    if File.file?(@path)
      File.open(@path) {|arc|
        while input = arc.read(@wordSize)
          if input =~ BEGFRGX
            sstr = input.scan(BEGFRGX).last
            path = sstr[7...-1] + 'test'
            readit = arc.tell - @wordSize
            readit = read(arc,path,readit)
            arc.seek(readit)
          end
        end
      }
    end
  end

  def list
    @ls
  end

  def pending
    @lsNew
  end

end 
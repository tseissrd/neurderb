require 'sys-cpu'
require 'get_process_mem'
require './FS.rb'
require './Task.rb'

Task.max = 100**2

#cpu = Sys::CPU.new
memfil = []

task = Proc.new {
	while true
	memfil.push(11.342445545**55)
	sleep 0.1
	Task.queue(&task)
	end
}

Task.queue(&task)
while true
puts Task.currentCount
puts FS.readable(GetProcessMem.new.bytes)
puts Sys::CPU.load_avg
end

return 0


require './NeuralNetworks.rb'

net = SelfOrganizing.newSOM(200, [[0.0,0.0], [0.0,0.0]])
export = net.export
puts export
puts 'END'

File.open('test.csv', 'w') {|fl|
  export.each {|ln|
    fl.write(ln + "\n")
  }
  fl.write("END\n")
}

samples = []
csamples = 80000

inputvar = []

inputvar[0] = [10,50]
inputvar[1] = [20,60]
inputvar[2] = [30,70]
inputvar[3] = [40,80]
inputvar[4] = [50,90]
inputvar[5] = [60,80]
inputvar[6] = [70,70]
inputvar[7] = [80,60]
inputvar[8] = [90,50]
inputvar[9] = [80,40]
inputvar[10] = [70,30]
inputvar[11] = [60,20]
inputvar[12] = [50,10]
inputvar[13] = [40,20]
inputvar[14] = [30,30]
inputvar[15] = [20,40]
inputvar[16] = [10,50]

csamples.times{
  input = inputvar[rand(inputvar.length)]
  samples.push(input)
}

i = 0
samples.each {|smp|
  net.makeInput(smp)
  net.activateAll
  net.train((1.0/csamples)*(csamples-i))
  i += 1
}

export = net.export
puts export

File.open('test.csv', 'a') {|fl|
  export.each {|ln|
    fl.write(ln + "\n")
  }
  fl.write("END\n")
}
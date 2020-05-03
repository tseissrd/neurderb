$LOAD_PATH << '.'
def err(n)
  case n
    when -1 then puts "incorrect input"
  end
  exit
end
require "NeuralNetworks"
#INPUT > 1 -> OUTPUT = 1, INPUT == 1 -> OUTPUT = 0
#3 INPUT NEURONS, 2 OUTPUT NEURONS, 1 BIAS NEURON
bias = -1.0
mode = 'eval'
input = []
neu = []
output = []
cfgcheck = File.exist?("sneurde.cfg")
weight = Array.new(8)
if cfgcheck
	fle = File.new("sneurde.cfg","r")
	i = 0
	fle.each_line do |l| 
	  weight[i] = l.to_f
	  i = i+1
	end
	if i != 8
	  cfgcheck = false
	end
	fle.close()
end
if !cfgcheck
	for i in 0...8
		weight[i] = (rand(100) + 1.0)/100
	end
	fle = File.new("sneurde.cfg","w")
	fle.close()
end
while true
	choice = true
	while choice
		puts 'input ( 1/2/3 -> 0|1 ( >1 ), mode, weights, reset, exit )'
		kinput = gets.chop
		if kinput == 'mode'
			puts 'train/eval'
			kinput = gets.chop
			if kinput == 'train'
				mode = 'train'
			elsif kinput == 'eval'
				mode = 'eval'
			else
				err(-1)
			end
		elsif kinput == 'reset'
      for i in 0...8
        weight[i] = (rand(100) + 1.0)/100
      end
    elsif kinput == 'weights'
      weight.each do |w|
        puts w
      end
		elsif kinput == 'exit'
		  exit(0)
		else
			kinput = kinput.to_i
			choice = false
		end
	end
	if kinput == 1
		input[0] = 1.0
		input[1] = 0.0
		input[2] = 0.0
	elsif kinput == 2
		input[0] = 0.0
		input[1] = 1.0
		input[2] = 0.0
	elsif kinput == 3
		input[0] = 0.0
		input[1] = 0.0
		input[2] = 1.0
	else
		err(-1)
	end
	#stage 1
	puts "Stage 1"
	i = 0
	prop = input[0]*weight[0] + input[1]*weight[2] + input[2]*weight[4] + bias*weight[6]
	output[i] = NeuralNetworks.sigmoid(prop)
	puts output[i]
	i = 1
	prop = input[0]*weight[1] + input[1]*weight[3] + input[2]*weight[5] + bias*weight[7]
	output[i] = NeuralNetworks.sigmoid(prop)
	puts output[i]
	if output[0] >= output[1]
		chose = 0
		puts '=1'
	else
		chose = 1
		puts '>1'
	end
	if mode == 'train'
		puts 'true or false?'
		kinput = gets.chop
		if kinput == 'true'
			if chose == 0
				errc = 1.0-output[0]
				weight[0] += weight[0]*errc
				weight[2] += weight[2]*errc
				weight[4] += weight[4]*errc
				weight[7] += weight[7]*errc
				errc = output[1]-1.0
				weight[1] += weight[1]*errc
				weight[3] += weight[3]*errc
				weight[5] += weight[5]*errc
				weight[6] += weight[6]*errc
			else
				errc = output[0]-1.0
				weight[0] += weight[0]*errc
				weight[2] += weight[2]*errc
				weight[4] += weight[4]*errc
				weight[7] += weight[7]*errc
				errc = 1.0-output[1]
				weight[1] += weight[1]*errc
				weight[3] += weight[3]*errc
				weight[5] += weight[5]*errc
				weight[6] += weight[6]*errc
			end
		elsif kinput == 'false'
			if chose == 0
				errc = output[0]-1.0
				weight[0] += weight[0]*errc
				weight[2] += weight[2]*errc
				weight[4] += weight[4]*errc
				weight[7] += weight[7]*errc
				errc = 1.0-output[1]
				weight[1] += weight[1]*errc
				weight[3] += weight[3]*errc
				weight[5] += weight[5]*errc
				weight[6] += weight[6]*errc
			else
				errc = 1.0-output[0]
				weight[0] += weight[0]*errc
				weight[2] += weight[2]*errc
				weight[4] += weight[4]*errc
				weight[7] += weight[7]*errc
				errc = output[1]-1.0
				weight[1] += weight[1]*errc
				weight[3] += weight[3]*errc
				weight[5] += weight[5]*errc
				weight[6] += weight[6]*errc
			end
		end
		weight.each do |w|
			if w<0.0
				w=0.0
			elsif w>1.0
				w=1.0
			end
		end
	end
	fle = File.open("sneurde.cfg", "w")
	weight.each do |w|
		fle.puts w
	end
	fle.close()
end
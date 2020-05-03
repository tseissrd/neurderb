require "NeuralNetworks"
#7 inputs, 3 outputs, 2 hidden layers of 5 neurons each
neurons = []

#inputs 0-6


## ТОДО РАСПАРАЛЕЛИТЬ ВЫЧИСЛЕНИЯ ДЕЛЬТ

#test = ''
#Task.queue {test = '123'}
#Task.wait
#puts test
#return 0
Task.max = 20

netw = ''
if File.exist?("dneurde.cfg")
  netw = NeuralNetwork.new()
  netw.loadFile('dneurde.cfg')
else
  netw = NeuralNetwork.newPerceptron(7,5,5,3)
end

r = 0
startD = Time.new
#while true do
for repeats in 0...500 do
  mode = 'eval'
  #puts 'input'
  #input = gets.to_i
  input = rand(7) - 3
  if input === -3
    netw.inputLayer.setActivation([1,0,0,0,0,0,0])
    pattern = netw.createPattern([1,0,0])
  end
  if input === -2
    netw.inputLayer.setActivation([0,1,0,0,0,0,0])
    pattern = netw.createPattern([1,0,0])
  end
  if input === -1
    netw.inputLayer.setActivation([0,0,1,0,0,0,0])
    pattern = netw.createPattern([1,0,0])
  end
  if input === 0
    netw.inputLayer.setActivation([0,0,0,1,0,0,0])
    pattern = netw.createPattern([0,1,0])
  end
  if input === 1
    netw.inputLayer.setActivation([0,0,0,0,1,0,0])
    pattern = netw.createPattern([0,0,1])
  end
  if input === 2
    netw.inputLayer.setActivation([0,0,0,0,0,1,0])
    pattern = netw.createPattern([0,0,1])
  end
  if input === 3
    netw.inputLayer.setActivation([0,0,0,0,0,0,1])
    pattern = netw.createPattern([0,0,1])
  end
  res = netw.evaluate()
  #puts repeats+1
  #puts res[0][1]
  #puts res[1][1]
  #puts res[2][1]
  if res[0][1].to_f >= res[1][1].to_f
    if res[0][1].to_f >= res[2][1].to_f
      puts input.to_s + '<0'
    else
      puts input.to_s + '>0'
    end
  else
    if res[1][1].to_f >= res[2][1].to_f
      puts input.to_s + '=0'  
    else
      puts input.to_s + '>0'
    end
  end
  puts '------------------------------'
  if mode === 'train'
    netw.train(pattern)
    netw.saveFile('dneurde.cfg')
  end
  r += 1
  endD = Time.new
  result = r/(endD - startD)
  puts result
end
require "Task.rb"

class Connection
  def initialize(neu1,neu2,wgt = 0)
    @neu1 = neu1
    @neu2 = neu2
    @wgt = wgt.to_f
    @learningRate = 0.3
  end
  def neurons
    [@neu1,@neu2]
  end
  def weight
    @wgt
  end
  def train(dweight)
    @wgt = @wgt + dweight
  end
  def learningRate
    @learningRate
  end
end
  
class Neuron
  def initialize(cnts = []) # [[neuron(Neuron),weight(flt),reverse(bool)]...]
    @activation = 0
    @connections = []
    cnts.each do |cn|
      connectionAdd(cn)
    end
  end
  def connectionAdd(cnt) # [neuron(Neuron),weight(flt),reverse(bool)]
    if cnt[2] === false
      @connections.push(Connection.new(itself,cnt[0],cnt[1]))
    else
      cnt[0].connectionAdd([itself,cnt[1],false])
    end
  end
  def getConnectionTo(neu)
    if @connections.find_index {|cn| cn.neurons[1] === neu}
      @connections[@connections.find_index {|cn| cn.neurons[1] === neu}]
    end
  end
  def activation
    @activation
  end
  def setActivation(activation)
    @activation = activation
  end
  def to_i
    activation
  end
end
  
class NeuralNetwork
  
  def initialize(neurons = [])
    @neuronsCount = 0
    @neurons = []
    neurons.each do |n|
      @neurons.push(n)
      @neuronsCount = @neuronsCount + 1
    end
  end
  
  def self.newPerceptron(*layers) #[ <input layer neurons count>[, <hidden layer 1 neurons count>, ... <hidden layer N neurons count>], <output layer neurons count> ]
    if layers.length < 2
      throw('There must be at least two layers (input and output)')
    end
    
    i = 0
    neurons = []
    layer_ncount = []
    layer = []
    cnts = []
    for j in 0...layers.length
      layer_ncount[j] = layers[j]
    end
    
    for j in 0...layers.length
      cnts[j] = []
      if j != 0
        for k in i...(i + layer_ncount[j]) do
          cnts[j][k] = layer[j-1].generateConnections(true)
        end
      end
      for k in i...(i + layer_ncount[j]) do
        if j != 0
          neurons.push(Neuron.new(cnts[j][k]))
        else
          neurons.push(Neuron.new())
        end
      end
      layer[j] = Layer.new(neurons[i..(i+layer_ncount[j])])
      i = i + layer_ncount[j]
    end
    new(neurons)
    
  end
  
  def neuronAdd(neu)
    @neurons.push(neu)
    @neuronsCount = @neuronsCount + 1
  end
  
  def neurons
    @neurons
  end
  
  def inNeurons
    out = []
    @neurons.each do |n1|
      isIn = true
      @neurons.each do |n2|
        if getConnection(n2,n1)
          isIn = false
          break
        end
      end
      if isIn
        out.push(n1)
      end
    end
    out
  end
  
  def outNeurons
    out = []
    @neurons.each do |n1|
      isOut = true
      @neurons.each do |n2|
        if getConnection(n1,n2)
          isOut = false
          break
        end
      end
      if isOut
        out.push(n1)
      end
    end
    out
  end
  
  def connections
    connections = []
    i = 0
    @neurons.each do |n1|
      @neurons.each do |n2|
        if getConnection(n1,n2)
          connections[i] = getConnection(n1,n2)
          i = i+1
        end
      end
    end
    connections
  end
  
  def loadFile(lfile)
    file = File.new(lfile,'r')
    @neurons = []
    @weights = []
    file.each_line do |ln|
      if ln[0] === 'n'
        ln[1...ln.length()].to_i.times {@neurons.push(Neuron.new())} 
      elsif ln[0] === 'c'
        @neurons[ln.split(':')[0][1...ln.length()].to_i].connectionAdd([@neurons[ln.split(':')[1].split('=')[0].to_i],ln.split('=')[1].to_f,false])
      end
    end
  end
  
  def saveFile(lfile)
    file = File.new(lfile, 'w')
    file.puts "# n - neurons (n<num>)"
    file.puts "# c - connection (c<connectionfrom>:<connectionto>=<weight>)"
    file.puts 'n' + @neurons.length().to_s
    i = 0
    connections.each do |cn|
      file.puts 'c' + @neurons.find_index(cn.neurons[0]).to_s + ':' + @neurons.find_index(cn.neurons[1]).to_s + '=' + cn.weight.to_s
    end
    file.close()
  end
  
  def getConnection(neu1,neu2)
    neu1.getConnectionTo(neu2)
  end
  
  def learningDelta(neu1, pattern)
    out = 0
    if outNeurons().include?(neu1)
      pattern.each do |pat|
        if pat[0] === neu1
          out = pat[1] - neu1.activation()
        end
      end
    else
      out = 0
      @neurons.each do |neu2|
        if getConnection(neu1,neu2)
          out = out + learningDelta(neu2,pattern)*getConnection(neu1,neu2).weight()
        end
      end
    end
    out
  end
  
  def train(pattern=[]) #[ [neuron, output], ...]
    if pattern.length() != outNeurons().length()
      throw('incorrect training pattern') 
    end
    pattern.each do |pat|
      changes = {}
      @neurons.each do |neubase|
      #connections().each do |con|
        networkInput = 0
        @neurons.each do |neu|
          #if getConnection(neu,pat[0])
          if getConnection(neu,neubase)
            networkInput = networkInput + neu.activation()
          end
        end
        @neurons.each do |neu|
          #if getConnection(neu,pat[0])
          if getConnection(neu,neubase)
            #con = getConnection(neu,pat[0])
            con = getConnection(neu,neubase)
            #con.train(con.learningRate()*neu.activation()*dsigmoid(networkInput)*learningDelta(pat[0], pattern))
            changes[con] = con.learningRate()*neu.activation()*dsigmoid(networkInput)*learningDelta(neubase, pattern)
          end
        end
      end
      connections().each do |con|
        con.train(changes[con])
      end
    end
  end
  
  def activate(neuron)
    wgtSum = 0
    inCheck = true
    @neurons.each do |neu|
      if getConnection(neu,neuron)
        inCheck = false
        wgtSum = wgtSum + activate(neu)*getConnection(neu,neuron).weight()
      end
    end
    if inCheck === false
      neuron.setActivation(sigmoid(wgtSum))
    end
    neuron.activation()
  end
  
  def evaluate()
    out = []
    outNeurons.each do |n|
      Task.queue {
        activate(n)
        out.push([n,n.activation()])
      }
    end
    Task.wait
    out
  end
  
  def inputLayer()
    Layer.new(inNeurons())
  end
  
  def outputLayer()
    Layer.new(outNeurons())
  end
  
  def createPattern(outputs)
    if outputs.length() != outNeurons.length()
      throw 'Incorrect number of outputs defined'
    end
    out = []
    i = 0
    outNeurons().each do |neu|
      out.push([neu,outputs[i]])
      i = i + 1
    end
    out
  end
  
#  def graph(neuron)
#    @neurons.each do |neu|
#      getConnection(neu,neuron)
#    end    
#  end
  
end

class Layer
  
  def initialize(neurons = [])
    @neurons = neurons
  end
  
  def neuronAdd(neu)
    @neurons.push(neu)
  end
  
  def generateConnections(dir = false, mode = 'rand')
    out = []
    @neurons.each do |neu|
      wgt = 0
      if mode === 'rand'
        wgt = (rand(100) + 1.0)/100
      end
      out.push([neu,wgt,dir])
    end
    out
  end
  
  def setActivation(activations = [])
    if activations.length() != @neurons.length()
      throw 'incorrect layer activation input'
    end
    i = 0
    @neurons.each do |n|
      n.setActivation(activations[i])
      i = i + 1
    end
    true
  end
  
end

def sigmoid(n)
  1.0/(1+2.718**(-n))
end

def dsigmoid(n)
  ( 2.718**(-n) )/( (1+2.718**(-n))**2 )
end
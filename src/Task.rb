class Task
  @@max = 1
  @@current = 0
  @@queued = 0
  @@queueMtx = Mutex.new()
  @@taskLock = ConditionVariable.new()
  @@userResources = {}
  
  def self.currentCount()
    @@current
  end
  
  def self.max=(newMax)
    @@max = newMax
  end
  
  def self.queue(&prc)
    waitPrc = Proc.new {
      @@queueMtx.synchronize {
        @@current -= 1
        @@queued -= 1
        @@taskLock.signal
      }
    }
    scheduled = (prc >> waitPrc)
    @@queueMtx.synchronize {
      @@queued += 1
      if @@current >= @@max
        @@taskLock.wait(@@queueMtx)
      end
      @@current += 1
    }
    Thread.new(&scheduled)
  end
  
  def self.wait(threads = [])
    if !(threads.class == Thread) && threads.length === 0
      @@queueMtx.synchronize {
        while @@queued > 0
          @@taskLock.wait(@@queueMtx)
        end
      }
    else
      waitFor = threads
      if !(threads.class == Array)
        waitFor = [threads]
      end
      waitFor.each {|thr|
        thr.join
      }
    end
  end
  
  def self.sync(resource = @@queueMtx, &prc)
    if resource.class != Mutex
      if !@@userResources.key?(resource)
        @@userResources[resource] = Mutex.new
      end
      @@userResources[resource].synchronize(&prc)
    else
      resource.synchronize(&prc)
    end
  end
  
  def self.done
    Thread.current.exit
  end
  
end
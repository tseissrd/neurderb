class Task
  @@max = 1
  @@current = 0
  @@queued = 0
  @@queueMtx = Mutex.new()
  @@taskLock = ConditionVariable.new()
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
  def self.wait()
    @@queueMtx.synchronize {
      while @@queued > 0
        @@taskLock.wait(@@queueMtx)
      end
    }
  end
  def self.sync(&prc)
    @@queueMtx.synchronize(&prc)
  end
end
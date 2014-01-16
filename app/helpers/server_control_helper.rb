module ServerControlHelper
  def pid_running(pid)
    begin
      Process.getpgid(pid)
      return true
    rescue Errno::ESRCH
      return false
    end
  end
  
  def sort_ps(x, y)
    x = x.split(" ")[2].to_f
    y = y.split(" ")[2].to_f
    return y <=> x
  end

  def analyse_uptime(str)
    uptime = str.split(" ")
    longminutes = uptime[-1]

    stdin, stdout, stderr = Open3.popen3("cat", "/proc/cpuinfo")
    stderr = stderr.gets(nil)
    stdout = stdout.gets(nil)
    if stderr.nil?
      cores = stdout.grep(/processer/).count
    else
      stdin, stdout, stderr = Open3.popen3("sysctl", "-n", "hw.ncpu")
      stderr =  stderr.gets(nil)
      if stderr.nil?
        cores = stdout.gets(nil).split("\n").join("")
      else
        cores = 1
      end
    end

    ideal = cores.to_f
    if longminutes.to_f >= (ideal - 0.3)
      return ["high", longminutes, uptime[0], uptime[2]]
    else
      return ["low", longminutes, uptime[0], uptime[2]]
    end
  end
end

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

  def sort_ps_mem(x, y)
    x = x.split(" ")[3].to_f
    y = y.split(" ")[3].to_f
    return y <=> x
  end

  def analyse_uptime(str)
    uptime = str.split(" ")
    longminutes = uptime[-1]

    stdin, stdout, stderr = Open3.popen3("cat", "/proc/cpuinfo")
    stderr = stderr.gets(nil)
    stdout = stdout.gets(nil)
    if stderr.nil?
      cores = stdout.split("\n").grep(/processor/).count
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
      return ["high", longminutes, uptime[0], uptime[2], cores]
    else
      return ["low", longminutes, uptime[0], uptime[2], cores]
    end
  end

  def analyse_network(str, os)
    generator = ColorGenerator.new saturation: 0.75, lightness: 0.5
    netstats = Hash.new
    if os == "osx"
      interfaces = str.split("\n")
      interfaces = interfaces[1..-1]
      interfaces.each do |interface|
        interface = interface.split(" ")
        unless interface[6] == "0" and interface[9] == "0"
          netstats[interface[0]] = {:received_bytes => interface[6], :transmitted_bytes => interface[9], :color => "##{generator.create_hex}"}
        end
      end
    else
      interfaces = str.split("\n")
      interfaces = interfaces[2..-1]
      interfaces.each do |interface|
        interface = interface.split(" ")
        unless interface[6] == "0" and interface[9] == "0"
          netstats[interface[0].gsub(/:/, "")] = {:received_bytes => interface[1], :transmitted_bytes => interface[9], :color => "##{generator.create_hex}"}
        end
      end
    end
    return netstats
  end

  def get_connection_speeds(kilob)
    speed = Hash.new
    speed["terabytes"] = (kilob.to_f / 1024.0 / 1024.0 / 1024.0).round(2)
    if speed["terabytes"] <= 0.0
      speed["terabytes"] = 0
    end
    speed["gigabytes"] = (kilob.to_f / 1024.0 / 1024.0).round(2)
    if speed["gigabytes"] <= 0.0
      speed["gigabytes"] = 0
    end
    speed["megabytes"] = (kilob.to_f / 1024.0).round(2)
    if speed["megabytes"] <= 0.0
      speed["megabytes"] = 0
    end
    speed["kilobytes"] = (kilob.to_f).round(2)
    if speed["kilobytes"] <= 0.0
      speed["kilobytes"] = 0
    end
    if speed["terabytes"] >= 1.0
      speed["best"] = "terabytes"
      return speed
    elsif speed["gigabytes"] >= 1.0
      speed["best"] = "gigabytes"
      return speed
    elsif speed["megabytes"] >= 1.0
      speed["best"] = "megabytes"
      return speed
    else
      speed["best"] = "kilobytes"
      return speed
    end
  end
end
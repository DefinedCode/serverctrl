class ServerControlController < ApplicationController
  
  require 'open3'
  
  def index
    stdin, stdout = Open3.popen3('uptime')
    uptime = stdout.gets(nil)
    @analysed = view_context.analyse_uptime(uptime)
  end

  def processes
    stdin, stdout = Open3.popen3('ps', 'aux')
    process_list = stdout.gets(nil).split("\n")[1..-1]
    @process_list = process_list.sort { |x, y| view_context.sort_ps(x, y) }

    if params[:id].nil?
      @status = ""
    else
      if view_context.pid_running(params[:id].to_i)
        @status = "Process ID #{params[:id]} is running."
      else
        @status = "Process ID #{params[:id]} is not running."
      end
    end
  end

end

class ServerControlController < ApplicationController
  before_filter :login_required, :except=>['login']

  require 'open3'
  
  def index
    stdin, stdout = Open3.popen3('uptime')
    uptime = stdout.gets(nil)
    @analysed = view_context.analyse_uptime(uptime)
    @day_load_history = Array.new
    @dates = Array.new
    Stat.where(:type => "load", :created_at.gte => (Date.today)).asc(:created_at).each do |stat|
      @day_load_history.push(stat.value.to_f)
      @dates.push("\"#{stat.created_at.strftime("%H:%M")}\"")
    end
    stdin, stdout = Open3.popen3('ps', 'aux')
    process_list = stdout.gets(nil).split("\n")[1..-1]
    @process_list_cpu = process_list.sort { |x, y| view_context.sort_ps(x, y) }.take(3)
    @process_list_mem = process_list.sort { |x, y| view_context.sort_ps_mem(x, y) }.take(3)
    if os ==  "osx"
      stdin, stdout = Open3.popen3('netstat', '-bi')
      network = stdout.gets(nil)
      @analysed_network = view_context.analyse_network(network, os)
    else
      network = File.open("/proc/net/dev") { |f| f.read }
      @analysed_network = view_context.analyse_network(network, os)
    end
    @load = @day_load_history.sort[-1].round(1)
    nets = Hash.new
    nets["meta"] = Hash.new
    innet = Stat.where(:type => "innet", :created_at.gte => (Date.today)).asc(:created_at)
    innet.each_with_index do |interf, index|
      if index == 0 
        old_value = Stat.where(:type => "innet", :value => interf.value, :created_at.gte => (Date.today - 1)).desc(:created_at).first
      else
        old_value = innet[index - 1]
      end
      if nets[interf.value].nil?
        nets[interf.value] = Hash.new
        traffic_s = (interf.valuetwo.to_i - old_value.valuetwo.to_i) / 1800 / 1024
        if (traffic_s / 1024) >= 1
          if (traffic_s / 1024 / 1024) >= 1
            if (traffic_s / 1024 / 1024 / 1024) >= 1
              traffic = traffic_s / 1024 / 1024 / 1024
              nets["meta"]["type"] = "terabytes"
            else
              traffic = traffic_s / 1024 / 1024
              nets["meta"]["type"] = "gigabytes"
            end
          else
            traffic = traffic_s / 1024
            nets["meta"]["type"] = "megabytes"
          end
        else
          traffic = traffic_s
          nets["meta"]["type"] = "kilobytes"
        end
        nets[interf.value][interf.created_at.strftime("%H:%M").to_s] = traffic
      else
        traffic_s = (interf.valuetwo.to_i - old_value.valuetwo.to_i) / 1200 / 1024
        if (traffic_s / 1024) >= 1
          if (traffic_s / 1024 / 1024) >= 1
            if (traffic_s / 1024 / 1024 / 1024) >= 1
              traffic = traffic_s / 1024 / 1024 / 1024
              nets["meta"]["type"] = "terabytes"
            else
              traffic = traffic_s / 1024 / 1024
              nets["meta"]["type"] = "gigabytes"
            end
          else
            traffic = traffic_s / 1024
            nets["meta"]["type"] = "megabytes"
          end
        else
          traffic = traffic_s
          nets["meta"]["type"] = "kilobytes"
        end
        nets[interf.value][interf.created_at.strftime("%H:%M").to_s] = traffic
      end
    end
  end

  def login
    if request.post?
      user = User.where(:username => params[:username]).first
      if user.nil?
        render :text => "User does not exist"
      elsif user && user.authenticate(params[:password])
        session[:user] = user
        redirect_to action: "index"
      else
        render :text => "Incorrect username or password."
      end
    end
  end

  def logout
    session[:user] = nil
    redirect_to action: "index"
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

  def web
    setup_nginx_dir = "/etc/nginx/conf.d/"
    first_conf = "/Users/will3942/Desktop/nginx.conf"
    parser = NginxParser.new(first_conf)
    @parsed = parser.parse.to_json
  end

  def setup
    
  end

end

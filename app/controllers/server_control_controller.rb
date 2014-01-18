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
      @dates.push(stat.created_at.strftime("%m-%d-%H-%M-%S"))
    end
    stdin, stdout = Open3.popen3('ps', 'aux')
    process_list = stdout.gets(nil).split("\n")[1..-1]
    @process_list_cpu = process_list.sort { |x, y| view_context.sort_ps(x, y) }.take(3)
    @process_list_mem = process_list.sort { |x, y| view_context.sort_ps_mem(x, y) }.take(3)
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
    first_conf = "/etc/nginx/conf.d/default.conf"
    parser = NginxParser.new(first_conf)
    render :text => parser.parse.to_json
  end

end

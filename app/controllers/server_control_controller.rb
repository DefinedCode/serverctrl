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
    @interface_colors = Hash.new
    @speed_type = Hash.new
    nets = Hash.new
    @speed_type["meta"] = Hash.new
    innet = Stat.where(:type => "innet", :created_at.gte => (Date.today)).asc(:created_at)
    innet.each_with_index do |interf, index|
      old_value = Stat.where(:_id.lt => interf._id, :type => "innet", :value => interf.value).order_by([[:_id, :desc]]).limit(1).first
      unless old_value.nil?
        seconds = ((interf.created_at.to_datetime - old_value.created_at.to_datetime) * 24 * 60 * 60).round(0)
        if nets[interf.value].nil?
          nets[interf.value] = Hash.new
          traffic_s = (interf.valuetwo.to_f - old_value.valuetwo.to_f) / seconds.to_f / 1024.0
          speeds = view_context.get_connection_speeds(traffic_s)
          if @speed_type["meta"]["type"].nil?
            @speed_type["meta"]["type"] = speeds["best"]
          else
            case speeds["best"]
            when "terabytes"
              @speed_type["meta"]["type"] = speeds["best"]
            when "gigabytes"
              case @speed_type["meta"]["type"]
              when "terabytes"
                # c o o l
              else
                @speed_type["meta"]["type"] = speeds["best"]
              end
            when "megabytes"
              case @speed_type["meta"]["type"]
              when "terabytes"
                # c o o l
              when "gigabytes"
                # c o o l
              else
                @speed_type["meta"]["type"] = speeds["best"]
              end
            when "kilobytes"
              case @speed_type["meta"]["type"]
              when "terabytes"
                # c o o l
              when "gigabytes"
                # c o o l
              when "megabytes"
                # c o o l
              else
                @speed_type["meta"]["type"] = speeds["best"]
              end
            else
              # W H Y  W T F ?
            end
          end
          nets[interf.value][interf.created_at.strftime("%H:%M").to_s] = speeds
          if @interface_colors[interf.value].nil?
            if @analysed_network[interf.value].nil?
              color = "#" + (ColorGenerator.new saturation: 0.75, lightness: 0.5).create_hex
              @interface_colors[interf.value] = color
              nets[interf.value]["color"] = color
            else
              color = @analysed_network[interf.value][:color]
              @interface_colors[interf.value] = color
              nets[interf.value]["color"] = color
            end
          else
            nets[interf.value]["color"] = @interface_colors[interf.value]
          end
        else
          traffic_s = (interf.valuetwo.to_f - old_value.valuetwo.to_f) / seconds.to_f / 1024.0
          speeds = view_context.get_connection_speeds(traffic_s)
          if @speed_type["meta"]["type"].nil?
            @speed_type["meta"]["type"] = speeds["best"]
          else
            case speeds["best"]
            when "terabytes"
              @speed_type["meta"]["type"] = speeds["best"]
            when "gigabytes"
              case @speed_type["meta"]["type"]
              when "terabytes"
                # c o o l
              else
                @speed_type["meta"]["type"] = speeds["best"]
              end
            when "megabytes"
              case @speed_type["meta"]["type"]
              when "terabytes"
                # c o o l
              when "gigabytes"
                # c o o l
              else
                @speed_type["meta"]["type"] = speeds["best"]
              end
            when "kilobytes"
              case @speed_type["meta"]["type"]
              when "terabytes"
                # c o o l
              when "gigabytes"
                # c o o l
              when "megabytes"
                # c o o l
              else
                @speed_type["meta"]["type"] = speeds["best"]
              end
            else
              # W H Y  W T F ?
            end
          end
          nets[interf.value][interf.created_at.strftime("%H:%M").to_s] = speeds
          if @interface_colors[interf.value].nil?
            if @analysed_network[interf.value].nil?
              color = "#" + (ColorGenerator.new saturation: 0.75, lightness: 0.5).create_hex
              @interface_colors[interf.value] = color
              nets[interf.value]["color"] = color
            else
              color = @analysed_network[interf.value][:color]
              @interface_colors[interf.value] = color
              nets[interf.value]["color"] = color
            end
          else
            nets[interf.value]["color"] = @interface_colors[interf.value]
          end
        end
      end
    end

    outnets = Hash.new
    outnet = Stat.where(:type => "outnet", :created_at.gte => (Date.today)).asc(:created_at)
    outnet.each_with_index do |interf, index|
      old_value = Stat.where(:_id.lt => interf._id, :type => "outnet", :value => interf.value).order_by([[:_id, :desc]]).limit(1).first
      unless old_value.nil?
        seconds = ((interf.created_at.to_datetime - old_value.created_at.to_datetime) * 24 * 60 * 60).round(0)
        if outnets[interf.value].nil?
          outnets[interf.value] = Hash.new
          traffic_s = (interf.valuetwo.to_f - old_value.valuetwo.to_f) / seconds.to_f / 1024.0
          speeds = view_context.get_connection_speeds(traffic_s)
          if @speed_type["meta"]["type"].nil?
            @speed_type["meta"]["type"] = speeds["best"]
          else
            case speeds["best"]
            when "terabytes"
              @speed_type["meta"]["type"] = speeds["best"]
            when "gigabytes"
              case @speed_type["meta"]["type"]
              when "terabytes"
                # c o o l
              else
                @speed_type["meta"]["type"] = speeds["best"]
              end
            when "megabytes"
              case @speed_type["meta"]["type"]
              when "terabytes"
                # c o o l
              when "gigabytes"
                # c o o l
              else
                @speed_type["meta"]["type"] = speeds["best"]
              end
            when "kilobytes"
              case @speed_type["meta"]["type"]
              when "terabytes"
                # c o o l
              when "gigabytes"
                # c o o l
              when "megabytes"
                # c o o l
              else
                @speed_type["meta"]["type"] = speeds["best"]
              end
            else
              # W H Y  W T F ?
            end
          end
          outnets[interf.value][interf.created_at.strftime("%H:%M").to_s] = speeds
          if @interface_colors[interf.value].nil?
            if @analysed_network[interf.value].nil?
              color = "#" + (ColorGenerator.new saturation: 0.75, lightness: 0.5).create_hex
              @interface_colors[interf.value] = color
              outnets[interf.value]["color"] = color
            else
              color = @analysed_network[interf.value][:color]
              @interface_colors[interf.value] = color
              outnets[interf.value]["color"] = color
            end
          else
            outnets[interf.value]["color"] = @interface_colors[interf.value]
          end
        else
          traffic_s = (interf.valuetwo.to_f - old_value.valuetwo.to_f) / seconds.to_f / 1024.0
          speeds = view_context.get_connection_speeds(traffic_s)
          if @speed_type["meta"]["type"].nil?
            @speed_type["meta"]["type"] = speeds["best"]
          else
            case speeds["best"]
            when "terabytes"
              @speed_type["meta"]["type"] = speeds["best"]
            when "gigabytes"
              case @speed_type["meta"]["type"]
              when "terabytes"
                # c o o l
              else
                @speed_type["meta"]["type"] = speeds["best"]
              end
            when "megabytes"
              case @speed_type["meta"]["type"]
              when "terabytes"
                # c o o l
              when "gigabytes"
                # c o o l
              else
                @speed_type["meta"]["type"] = speeds["best"]
              end
            when "kilobytes"
              case @speed_type["meta"]["type"]
              when "terabytes"
                # c o o l
              when "gigabytes"
                # c o o l
              when "megabytes"
                # c o o l
              else
                @speed_type["meta"]["type"] = speeds["best"]
              end
            else
              # W H Y  W T F ?
            end
          end
          outnets[interf.value][interf.created_at.strftime("%H:%M").to_s] = speeds
          if @interface_colors[interf.value].nil?
            if @analysed_network[interf.value].nil?
              color = "#" + (ColorGenerator.new saturation: 0.75, lightness: 0.5).create_hex
              @interface_colors[interf.value] = color
              outnets[interf.value]["color"] = color
            else
              color = @analysed_network[interf.value][:color]
              @interface_colors[interf.value] = color
              outnets[interf.value]["color"] = color
            end
          else
            outnets[interf.value]["color"] = @interface_colors[interf.value]
          end
        end
      end
    end

    @out = outnets
    @in = nets
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

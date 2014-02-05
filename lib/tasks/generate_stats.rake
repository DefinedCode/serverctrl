require "#{Rails.root}/app/helpers/server_control_helper"
include ServerControlHelper

namespace :generate_stats do
  desc "Store the average server load to MongoDB"
  task load: :environment do
    stdin, stdout = Open3.popen3('uptime')
    uptime = stdout.gets(nil)
    analysed = analyse_uptime(uptime)
    @stat = Stat.create(
      'type' => "load",
      'value' => analysed[1].to_s,
      'valuetwo' => '',
      )
  end
  desc "Store the average inbound network connection to MongoDB"
  task innet: :environment do
    if os ==  "osx"
      stdin, stdout = Open3.popen3('netstat', '-bi')
      network = stdout.gets(nil)
      analysed_network = analyse_network(network, os)
    else
      network = File.open("/proc/net/dev") { |f| f.read }
      analysed_network = analyse_network(network, os)
    end
    old_stat = Stat.where(:type => "innet").desc(:created_at).first
    if old_stat.nil?
      prev_connec = 0
      analysed_network = analysed_network.sort{|key,value| value[1][:received_bytes].to_i }
      @stat = Stat.create(
        'type' => "innet",
        'value' => '0',
        'valuetwo' => analysed_network[0][1][:received_bytes].to_s,
        )
    else
      prev_connec = old_stat.valuetwo.to_i
      analysed_network = analysed_network.sort{|key,value| value[1][:received_bytes].to_i }
      traffic_kb = (analysed_network[0][1][:received_bytes].to_i - prev_connec.to_i) / 1800 / 1024
      unless traffic_kb.to_i < 0
        @stat = Stat.create(
          'type' => "innet",
          'value' => traffic_kb.to_s,
          'valuetwo' => analysed_network[0][1][:received_bytes].to_s,
          )
      end
    end
  end
  desc "Store the average outbound network connection to MongoDB"
  task outnet: :environment do
    if os ==  "osx"
      stdin, stdout = Open3.popen3('netstat', '-bi')
      network = stdout.gets(nil)
      analysed_network = analyse_network(network, os)
    else
      network = File.open("/proc/net/dev") { |f| f.read }
      analysed_network = analyse_network(network, os)
    end
    old_stat = Stat.where(:type => "outnet").desc(:created_at).first
    if old_stat.nil?
      analysed_network = analysed_network.sort{|key,value| value[1][:transmitted_bytes].to_i }
      @stat = Stat.create(
        'type' => "outnet",
        'value' => '0',
        'valuetwo' => analysed_network[0][1][:transmitted_bytes].to_s,
        )
    else
      prev_connec = old_stat.valuetwo.to_i
      analysed_network = analysed_network.sort{|key,value| value[1][:transmitted_bytes].to_i }
      traffic_kb = (analysed_network[0][1][:transmitted_bytes].to_i - prev_connec.to_i) / 1800 / 1024
      unless traffic_kb.to_i < 0
        @stat = Stat.create(
          'type' => "outnet",
          'value' => traffic_kb.to_s,
          'valuetwo' => analysed_network[0][1][:transmitted_bytes].to_s,
          )
      end
    end
  end

  def os
    os = Stat.where(:type => "os").first.value
    return os
  end

end

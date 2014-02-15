require "#{Rails.root}/app/helpers/server_control_helper"
require 'open3'
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
    analysed_network.each do |interf|
      @stat = Stat.create(
        'type' => "innet",
        'value' => interf[0].to_s,
        'valuetwo' => interf[1][:received_bytes].to_s,
        )
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
    analysed_network.each do |interf|
      @stat = Stat.create(
        'type' => "outnet",
        'value' => interf[0].to_s,
        'valuetwo' => interf[1][:transmitted_bytes].to_s,
        )
    end
  end

  def os
    os = Stat.where(:type => "os").first.value
    return os
  end

end

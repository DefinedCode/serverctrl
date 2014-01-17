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
      )
  end

end

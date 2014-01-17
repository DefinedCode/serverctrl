namespace :setup do
  desc "Setup the control panel."
  task start: :environment do
    if ENV['RAILS_ENV'] != "production"
      puts "Rails environment is not production. Please re-run command with rake setup:start RAILS_ENV=\"production\""
      next
    end
    puts "Welcome to ServerCtrl setup."
    puts "----------------------------------------"
    if ask_question("Is this user and app running as root? (y/n)")
      if ask_question("Is MongoDB installed? (y/n)")
        puts "Starting to create your admin account."
        unless User.all.count > 0
          Rake::Task["user:create"].invoke
          if User.all.count > 0
            puts "Account setup finished."
          end
        else
          puts "Admin account already created."
        end
        puts "Now installing crontab to generate graphs."
        stdin, stdout, stderr = Open3.popen3('whenever', '--update-crontab')
        if stdout.gets(nil).include? "crontab file updated"
          puts "Crontab updated successfully"
        else
          puts "Error, crontab not updated! Printing logs (email logs to will@will3942.com if it does not work when you try again)."
          puts stdout.gets(nil)
          puts stderr.gets(nil)
        end
        puts "Creating MongoDB indexes"
        Rake::Task["db:mongoid:create_indexes"].invoke
        puts "----------------------------------------"
        puts "Setup completed successfully."
        puts "ServerCtrl installed."
        puts "Please run 'rails s' in a screen session ('screen -d -m -S ServerCtrl rails s')"
        puts "Goodbye."
      else
        puts "Please install MongoDB, if apt is installed (usually on Ubuntu/Debian) use 'apt-get install mongodb', otherwise find out how to install MongoDB at http://mongodb.org."
        next
      end
    else
      puts "Make sure the user is root and the app will be run as root."
    end
  end

  def ask_question(q)
    print q + " "
    input = STDIN.gets.chomp
    if input == 'y' or input == 'yes' or input == 'YES' or input == 'Yes'
      return true
    else
      return false
    end
  end

  def get_input(str)
    print str + ": "
    input = STDIN.gets.chomp
    unless input == "" or input == " "
      return input
    else
      return false
    end
  end
end

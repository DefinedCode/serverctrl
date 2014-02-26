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
        puts "Removing any existing data"
        Rake::Task["db:mongoid:purge"].invoke
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
        if ask_question("Are you running on Mac OS X? (y/n)")
          puts "Writing launch script to /usr/local/bin/"
          FileUtils.copy(Rails.root.join("init_script.sh"), "/usr/local/bin/serverctrl")
          puts "Creating launch script"
          f = File.open("/usr/local/bin/serverctrl", 'r')
          skip = f.readlines
          f.close
          skip[1] = "PROG_PATH=\"#{Rails.root}\"\n"
          f = File.open("/usr/local/bin/serverctrl", 'w')
          f.write(skip.join)
          f.close
          File.chmod(0766, "/usr/local/bin/serverctrl")
          puts "Launch script created."
          osx = true
          @stat = Stat.create(
            'type' => "os",
            'value' => "osx",
            )
        else
          @stat = Stat.create(
            'type' => "os",
            'value' => "linux",
            )
          osx = false
          puts "Moving script to /etc/init.d/ to allow for launching worldwide."
          FileUtils.copy(Rails.root.join("init_script.sh"), "/etc/init.d/serverctrl")
          puts "Creating launch script"
          f = File.open("/etc/init.d/serverctrl", 'r')
          skip = f.readlines
          f.close
          skip[1] = "PROG_PATH=\"#{Rails.root}\"\n"
          f = File.open("/etc/init.d/serverctrl", 'w')
          f.write(skip.join)
          f.close
          File.chmod(0766, "/etc/init.d/serverctrl")
          puts "Launch script created."
        end
        puts "Getting inital load stats."
        Rake::Task["generate_stats:load"].invoke
        puts "Getting inital network stats."
        Rake::Task["generate_stats:innet"].invoke
        Rake::Task["generate_stats:outnet"].invoke
        puts "Precompiling assets."
        Rake::Task["assets:precompile"].invoke
        puts "----------------------------------------"
        puts "Setup completed successfully."
        puts "ServerCtrl installed."
        puts "Make sure bundler is installed for root, `gem install bundler` or `sudo gem install bundler`."
        puts "ServerCtrl must be run as root. Either prepend the following commands with sudo or run as root."
        if osx
          puts "To launch run 'serverctrl start' or 'sudo serverctrl start'"
        else
          puts "To launch run '/etc/init.d/serverctrl start' or 'sudo /etc/init.d/serverctrl start'"
        end
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

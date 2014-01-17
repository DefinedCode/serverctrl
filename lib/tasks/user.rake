namespace :user do
  desc "Create a User"
  task create: :environment do
    STDOUT.sync = true
    if ENV['RAILS_ENV'] == "production"
      puts "Creating a new user for the server control panel."
      if ask_question("Are you sure you want to continue? (y/n)")
        username = get_input("Please enter username")
        password = get_input("Please enter password")
        password_confirmation = get_input("Please enter password again")
        if password == password_confirmation
          if User.where(username: username).first.nil?
            user = User.create(username: username, password: password, password_confirmation: password_confirmation)
            unless user.nil?
              puts "User created."
            else
              puts "User not created!"
            end
          else
            puts "Username already taken."
          end
        else
          puts "Passwords are not the same! Please try again."
        end
      else
        puts "Quit."
      end
    else
      puts "Rails environment is not production. Please re-run command with rake user:create RAILS_ENV=\"production\""
    end
  end

  desc "Delete a User"
  task delete: :environment do
    STDOUT.sync = true
    if ENV['RAILS_ENV'] == "production"
      puts "Deleting a user."
      if ask_question("Are you sure you want to continue? (y/n)")
        username = get_input("Please enter username")
        password = get_input("Please enter password")
        password_confirmation = get_input("Please enter password again")
        if password == password_confirmation
          user = User.where(username: username).first
          unless user.nil?
            user.destroy
            puts "User #{username} deleted."
          else
            puts "User #{username} does not exist."
          end
        else
          puts "Passwords are not the same! Please try again."
        end
      else
        puts "Quit."
      end
    else
      puts "Rails environment is not production. Please re-run command with rake user:delete RAILS_ENV=\"production\""
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

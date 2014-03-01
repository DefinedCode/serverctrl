if [ "$(id -u)" != "0" ]; then
    echo -e "[ERROR] ServerCtrl must be run as root." 1>&2
    exit 1
fi
gem install bundler
bundle install
rake assets:precompile RAILS_ENV="production"
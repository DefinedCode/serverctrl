class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  def login_required
    if session[:user].nil?
      redirect_to action: "login"
      return true
    else
      if session[:user].authenticate(session[:user].password)
        return false
      else
        return true
      end
    end
  end

  def current_user
    session[:user]
  end

  def os
    os = Stat.where(:type => "os").first.value
    return os
  end

  def setup_complete
    status = Stat.where(:type => "setup_status").first
    if status.nil?
      return false
    elsif status.value == "false"
      return false
    elsif status.value == "true"
      return true
    else
      return false
    end
  end
end

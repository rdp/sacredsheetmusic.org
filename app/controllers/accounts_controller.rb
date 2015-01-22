# Handles login / logout of the admin section
# copied verbatim :)

class AccountsController < ApplicationController
  layout 'accounts'
  before_filter :ssl_required

  def login
    if request.post?
      if user = User.authenticate(params[:user_login], params[:user_password])
        session[:user] = user.id
        flash['notice']  = "Login successful, welcome #{user.login}"
        redirect_back_or_default :action => "welcome"
      else
        flash.now['notice']  = "Login unsuccessful"
        @login = params[:user_login]
      end
    end
  end
  
  def logout
    session[:user] = nil
    flash[:notice] = 'logged out' # hard to get to username :|
    redirect_to "/"
  end
    
  def welcome
    flash.keep # :|
  end
  
end

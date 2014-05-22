# Handles login / logout of the admin section
# copied verbatim :)

class AccountsController < ApplicationController
  layout 'accounts'
  before_filter :ssl_required

  def login
    if request.post?
      if user = User.authenticate(params[:user_login], params[:user_password])
        session[:user] = user.id
        flash['notice']  = "Login successful"
        # assume a lay user
        redirect_back_or_default :controller => '/content_nodes', :action => 'show_by_name', :name => 'self-upload'
      else
        flash.now['notice']  = "Login unsuccessful"
        @login = params[:user_login]
      end
    end
  end
  
  def logout
    session[:user] = nil
    flash[:notice] = 'logged out' # doesn't work?
    redirect_to "/"
  end
    
  def welcome
  end
  
end

class Admin::BaseController < ApplicationController
  layout 'admin'
  before_filter :ssl_required
  
  # Check permissions for everything on the admin side.   These are action names
  before_filter :login_required, :except => [:login, :new_song_editor]
  before_filter :check_authorization, :except => [:login, :index] # runs the "authorized?" method which is by default true

  before_filter :set_substruct_defaults, :except => [:login]
  private
    def set_substruct_defaults
      @logged_in_user = User.find(session[:user])
    end
end

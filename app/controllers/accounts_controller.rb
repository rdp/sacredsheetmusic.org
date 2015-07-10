# Handles login / logout of the admin section. OK this is weird why have this here and not in the admin section, which already carefully made accomodations for "login" to not require log in? huh?

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

  def new_song_editor
    @title = "create new user to upload your songs"
    if session[:user]
      @user = User.find session[:user] # already logged in, so an update
      if @user.is_admin?
        raise "admins should not use this" # too dangerous since it messes with permissions :P
      end
      @composer_tag = @user.composer_tag
      @user.password = @user.password_confirmation =  '' # show blank typically to start since these are md5's anyway at save time apparently gets replaced with an md5 equivalent. weird.
    else
      @user = User.new
      @composer_tag = Tag.new
    end

    if request.post?
      # update_attributes attempts a save, and sets local attribute values, and sets id. wow.
      # TODO relookup composer tag? huh?
      if @user.update_attributes(params["user"]) && @composer_tag.update_attributes(params["composer_tag"])
        # assume the rest will all work LOL
        composers = Tag.find_by_name "Composers"
        @composer_tag.parent = composers
        @composer_tag.save!
        composers.alphabetize_children!
        @user.composer_tag = @composer_tag # in case of an initial save...
        @user.save!
        product_editor = Role.find_by_name "Product Editor"
        @user.roles << product_editor unless @user.roles.contain?(product_editor)
        # TODO send email so they can remember their login name? or make them remember it LOL
        Rails.logger.info "SUCCESS creating #{@user.login} #{@composer_tag.name}"
        flash[:notice] = "Successfully created login #{@user.login}, use it to login now"
        redirect_to "/admin" # forces a re-login
        return
      else
        # fall through and render with failure messages
      end
    end
    render :layout => 'main_no_box_admin'
  end

end

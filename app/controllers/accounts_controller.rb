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
    Rails.logger.info params.inspect
    if session[:user]
      @user = User.find session[:user] # already logged in, so an update
    end
    if request.post?
      if !@user
         Rails.logger.info("saving user #{params[:user]} all are #{User.all.map &:login}")
         @user = User.new(params[:user]) # disallow any failure for now :|
         Rails.logger.info("saving user name #{@user.login} #{@user.inspect} all are #{User.all.map &:login}")
         @user.save!
      end 
      @user.update_attributes!(params["user"]) # implies a save, BTW
      @composer_tag = @user.composer_tag || Tag.create!(params["composer_tag"])
      @composer_tag.update_attributes(params["composer_tag"])
      composers = Tag.find_by_name "Composers"
      @composer_tag.parent = composers
      @composer_tag.save!
      composers.alphabetize_children!
      @user.composer_tag = @composer_tag # in case an initial save
      product_editor = Role.find_by_name "Product Editor"
      @user.roles << product_editor unless @user.roles.contain?(product_editor)
      # TODO send email so they can remember their login name?
      flash[:notice] = 'Successfully created login, use it to login now'
      Rails.logger.info "SUCCESS creating #{@user.login}"
      redirect_to '/admin' and return # force them to use it to login now :)
    end
    # edit or new
    if @user
      if @user.is_admin?
        raise "admins should not use this"
      end
      @composer_tag = @user.composer_tag
    else
      # new login request...
      @user = User.new
      @composer_tag = Tag.new
    end

    @user.password = @user.password_confirmation =  '' # show blank typically to start since these are md5's anyway
    render :layout => 'main_no_box_admin'
  end

end

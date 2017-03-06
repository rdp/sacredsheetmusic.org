# Handles login / logout of the admin section. OK this is weird why have this here and not in the admin section, which already carefully made accomodations for "login" to not require log in? huh?

class AccountsController < ApplicationController
  layout 'accounts'
  before_filter :ssl_required

  def login
    @title = "Login to access admin area"
    if request.post?
      if user = User.authenticate(params[:user_login], params[:user_password])
        session[:user] = user.id
        flash[:notice] = "Login successful, welcome #{user.login}"
        redirect_back_or_default :action => "welcome"
      else
        flash.now[:notice]  = "Login unsuccessful"
        @login = params[:user_login]
      end
    end
  end
  
  def logout
    session[:user] = nil
    flash[:notice] = 'logged out' # hard to get to username here :|
    redirect_to "/"
  end
    
  def welcome
    flash.keep # :|
  end

  def reset_password
    @title = "Reset user password"
    if request.post?
      if session[:user]
        throw "resetting password when currently logged in? please <a href=/logout>logout</a> first..."
      end
      composer_tag = Tag.find_by_composer_email_if_contacted! params[:email_to_reset]
      composer_user = composer_tag.admin_user || raise("no admin user to reset?")
      new_password = generate_random_password 
      composer_user.password = composer_user.password_confirmation = new_password
      composer_user.save! # md5 it
      send_success_account_email composer_user, composer_tag, new_password 
      flash[:notice] = "Successfully reset password and sent it to your email #{params[:email_to_reset]}, please check it, and use that to login!"
      redirect_to "/about/self-upload" # a page that display the flash pretti-ly :)
      return
    else
      # its all in the view 
    end
  end

  def edit_composer_login
    if !session[:user]
      flash[:notice] = "you need to login first, before you can edit your profile"
      redirect_to "/about/self-upload" # a page that display the flash pretti-ly :)
      return
    end
    @title = "Edit login to upload your songs"
    @user = User.find session[:user] # already logged in, so force an update [or edit view]
    if @user.is_admin?
      raise "admins should not use this, too dangerous since it messes with permissions :P"
    end
    @composer_tag = @user.composer_tag
    @user.password = @user.password_confirmation =  '' # show blank typically to start since these are md5's anyway at save time apparently gets replaced with an md5 equivalent. weird. Except then you can't save it because it doesn't match? huh wuh?
    new_edit_composer_login 
  end

  def new_composer_login
    @title = "Create new login to upload your songs"
    @user = User.new
    @composer_tag = Tag.new # hopefully this avoids them trying to "take over"/hijack any existing account...
    if session[:user] && !request.post?
      render :text => "please logout before creating a new login on the site, so you don't accidentally overwrite/adjust your current one trying to create a new login! If you'd like to edit your account go to <a href=/accounts/edit_composer_login >here</a>."
      return # happened once :|
    end
    new_edit_composer_login
  end

  def new_edit_composer_login
    if request.post?
      if !session[:user] && Tag.find_by_name(params['composer_tag']['name'])
        render :text => "appears that you already have an account in our system, please email us rogerdpack@gmail.com so we can create you a login for you manually, sorry about this...]. <br/>If you already have a login created for you to upload songs, please login using it first, <a href='/admin'>here</a>.<br/>if you forgot your password, please email us."
        return
      end

      # update_attributes attempts a save, and sets local attribute values, and sets id. wow.
      if @user.update_attributes(params["user"]) && @composer_tag.update_attributes(params["composer_tag"])
        # assume the rest will all work LOL
        composers = Tag.find_by_name "Composers"
        @composer_tag.parent = composers
        @composer_tag.save!
        composers.alphabetize_children!
        @user.composer_tag = @composer_tag # in case of an initial save...
        @user.password = @user.password_confirmation = "" # password being present [and md5'ed in this case] disallows resaving. weird.

        @user.save!
        product_editor = Role.find_by_name "Product Editor"
        @user.roles << product_editor unless @user.roles.contain?(product_editor)
        send_success_account_email @user, @composer_tag
        Rails.logger.info "SUCCESS creating #{@user.login} #{@composer_tag.name}"
        flash[:notice] = "Successfully #{session[:user] ? "edited" : "created"} login [#{@user.login}], use it to login here :)"
        redirect_to "/admin" # forces a re-login
        return
      else
        # fall through and render with failure messages
      end
    end
    render :layout => 'main_no_box_admin', :action => 'new_composer_login'
  end

private
    def send_success_account_email user, composer_tag, new_password = nil
              # obviously I need a real template LOL
              if session[:user]
                prefix = "Updated your account info"
              else
                prefix="Pleased to meet you"
              end
              adjust_user_url = url_for(:action => 'edit_composer_login')
              message = "#{prefix} #{composer_tag.name} your login is\n#{user.login}\nEnjoy! Any questions, don't hesitate to ask!\nYou can adjust your bio/profile/password by going here:" + adjust_user_url + "\nAnd enter new songs here:" + url_for(:controller => "/accounts", :action=>"login")
              if new_password
                message += "\n Your newly reset password is #{new_password}.  You can change it (if desired) here: " + adjust_user_url
              end
              OrdersMailer.deliver_inquiry(
                "Message from freeldssheetmusic.org: #{prefix}",
                 message,
                 Preference.get_value('mail_username'),
                 composer_tag.composer_email_if_contacted
              )
    end

end

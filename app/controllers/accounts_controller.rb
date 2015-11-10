# Handles login / logout of the admin section. OK this is weird why have this here and not in the admin section, which already carefully made accomodations for "login" to not require log in? huh?

class AccountsController < ApplicationController
  layout 'accounts'
  before_filter :ssl_required

  def login
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
    flash[:notice] = 'logged out' # hard to get to username :|
    redirect_to "/"
  end
    
  def welcome
    flash.keep # :|
  end

  def new_composer_login
    @title = "Create login to upload your songs"
    if session[:user]
      @title = "Edit login to upload your songs"
      @user = User.find session[:user] # already logged in, so force an update [or edit view]
      if @user.is_admin?
        raise "admins should not use this" # too dangerous since it messes with permissions :P
      end
      @composer_tag = @user.composer_tag
      @user.password = @user.password_confirmation =  '' # show blank typically to start since these are md5's anyway at save time apparently gets replaced with an md5 equivalent. weird. Except then you can't save it because it doesn't match? huh wuh?
    else
      @user = User.new
      @composer_tag = Tag.new # hopefully this avoids them trying to "take over"/hijack an existing account...
    end

    if request.post?
      if !session[:user] && Tag.find_by_name(params['composer_tag']['name'])
        render :text => "appears that you already have an account in our system, please email us rogerdpack@gmail.com so we can create you a login for you manually, sorry about that]. <br/>If you already have a login created for you to upload songs, please login using it first, <a href='/admin'>here</a>.<br/>if you forgot your password, please email us."
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
    render :layout => 'main_no_box_admin'
  end

private
    def send_success_account_email user, composer_tag
              # obviously I need a real template LOL
              if session[:user]
                prefix = "Updated your account info"
              else
                prefix="Pleased to meet you"
              end
              OrdersMailer.deliver_inquiry(
                'Welcome to freeldssheetmusic.org (login account info or updated info)',
                "#{prefix} #{composer_tag.name} your login is\n#{user.login}\nEnjoy! Any questions, don't hesitate to ask!\nYou can adjust your bio/profile/password by going here:" + url_for() + "\nAnd enter new songs here:" + url_for(:controller => "/accounts", :action=>"login"),
                 Preference.get_value('mail_username'),
                 composer_tag.composer_email_if_contacted
              )
    end

end

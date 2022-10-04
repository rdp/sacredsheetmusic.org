require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/controllers/substruct_application_controller"

module SubstructApplicationController
  
  def redirect_to_sacredsheetmusic
    if ENV['RAILS_ENV'] == "production" 
      if (request.host =~ /^www/) || (request.host !~ /sacredsheetmusic.org/) # redirect all old url's...and www's...
         redirect_to "http://sacredsheetmusic.org" + request.request_uri, :status => :moved_permanently 
         flash.keep
         return false
      end
    end
  end

  def set_substruct_view_defaults
    # TODO - Clean up this messy navigation generation stuff...
        @cname = self.controller_name
        @aname = self.action_name
        @store_name = Preference.get_value('store_name') || 'Substruct'
        # Is this a blog post?
        @blog_post = false
        if (@cname == 'content_nodes' && @content_node) then
                if (@content_node.is_blog_post?) then
                        @blog_post = true
                end
        end
  end

  # run in a before filter...for everything I believe...
  def get_nav_tags
    # huh? Why do they all need this? I guess for the typical layout?
    @main_nav_tags = Tag.find_ordered_parents.reject{|t| t.name_in_nav == 'skip'}
    # a few use this, I added it :)
    if session[:user]
      @user = User.find(session[:user]) # NB admin also already has an @logged_in_user before filter
    end
  end

end

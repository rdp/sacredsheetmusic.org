require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/controllers/substruct_application_controller"

module SubstructApplicationController
  
  def redirect_to_freeldssheetmusic
    if ENV['RAILS_ENV'] == "production" 
      if (request.host =~ /^(www|admin)/) || (request.host !~ /localhost|freeldssheetmusic.org/) # allow localhost:3000 etc. redirect all old url's...
         redirect_to "http://freeldssheetmusic.org" + request.request_uri, :status => :moved_permanently 
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

  # run in a before filter...
  def get_nav_tags
    # huh?
    @main_nav_tags = Tag.find_ordered_parents.reject{|t| t.name_in_nav == 'skip'}
    # a few use this
    if session[:user]
      @user = User.find(session[:user])
    end
  end

end

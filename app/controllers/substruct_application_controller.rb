require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/controllers/substruct_application_controller"

module SubstructApplicationController
  
  def redirect_to_freeldssheetmusic
    if ENV['RAILS_ENV'] == "production" 
      #if( (request.host !~ /freeldssheetmusic.org/) || (request.host =~ /choirarrangements.freeldssheetmusic.org/) )
      if request.host =~ /^(www|choirarrangements)/ || (request.host !~ /localhost|freeldssheetmusic.org/) # allow localhost:3000
         redirect_to "http://freeldssheetmusic.org" + request.request_uri, :status => :moved_permanently 
         flash.keep
         return false
      end

      if request.request_uri.in? ['/index-of-free-lds-mormon-arrangements-choir-piano-solo', '/lds-ward-choir-music', '/choir-arrangements']
        redirect_to "/", :status => :moved_permanently # this is a 301, apparently preferred, viz: http://webdesign.about.com/od/http/qt/tip301v302redir.htm
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
  
end

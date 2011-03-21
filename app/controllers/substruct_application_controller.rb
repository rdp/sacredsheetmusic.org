require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/controllers/substruct_application_controller"

module SubstructApplicationController
  
  def redirect_to_freeldssheetmusic
    if ENV['RAILS_ENV'] == "production" 
      if request.host !~ /freeldssheetmusic.org/
         redirect_to "http://freeldssheetmusic.org" + request.request_uri
         flash.keep
         return false
      end
      
      if request.request_uri == '/'
        redirect_to "/lds-ward-choir-music"
        flash.keep
        return false
      end
    end
    
  end
  
end

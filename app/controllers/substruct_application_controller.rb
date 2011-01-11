require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/controllers/substruct_application_controller"

module SubstructApplicationController
  
  def redirect_to_freewardchoir
    if ENV['RAILS_ENV'] == "production" 
      if request.host !~ /freemusicformormons/
         redirect_to "http://freemusicformormons.com" + request.request_uri
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

require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/controllers/substruct_application_controller"

module SubstructApplicationController
  
  def redirect_to_freewardchoir
    p ENV['RAILS_ENV']*100
    if ENV['RAILS_ENV'] == "production" 
      if request.host !~ /freewardchoir/
         redirect_to "http://freewardchoir.musicformormons.com" + request.request_uri
         flash.keep
         return false
      end
    end
    
  end
  
end

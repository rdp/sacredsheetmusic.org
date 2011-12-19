require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/controllers/substruct_application_controller"
require 'sane'

module SubstructApplicationController
  
  def redirect_to_freeldssheetmusic
    if ENV['RAILS_ENV'] == "production" 
      #if( (request.host !~ /freeldssheetmusic.org/) || (request.host =~ /choirarrangements.freeldssheetmusic.org/) )
      if request.host =~ /^www/ || (request.host !~ /freeldssheetmusic.org/)
         redirect_to "http://freeldssheetmusic.org" + request.request_uri
         flash.keep
         return false
      end
      if request.request_uri.in? ['/', '/lds-ward-choir-music', '/choir-arrangements']
        redirect_to "/index-of-free-lds-mormon-arrangements-choir-piano-solo"
        flash.keep
        return false
      end
    end
    
  end
  
end

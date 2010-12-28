class StoreController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :search
  
  def show2
    @product = Product.find(params['id'])
  end

  # Downloads a file using the old system :P
  
  def download_file
    # Now find download...
    file = Download.find(:first, :conditions => ["id = ?", params[:download_id]])
    
    # Ensure it belongs to the passed in order.
    if file && File.exist?(file.full_filename)
      send_file(file.full_filename)
    else
      render(:file => "#{RAILS_ROOT}/public/404.html", :status => 404) and return
    end
  end
  
  
end
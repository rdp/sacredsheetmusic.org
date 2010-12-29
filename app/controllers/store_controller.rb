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

  # Our simple store index
  def index
    @title = "Songs"
    respond_to do |format|
      format.html do
        @tags = Tag.find_alpha
        @tag_names = nil
        @viewing_tags = nil
        @products = Product.paginate(
          :order => 'name ASC',
          :conditions => Product::CONDITIONS_AVAILABLE,
          :page => params[:page],
          :per_page => @@per_page
        )
        render :action => 'index.rhtml' and return
      end
      format.rss do
        @products = Product.find(
          :all,
          :conditions => Product::CONDITIONS_AVAILABLE,
          :order => "date_available DESC"
        )
        render :action => 'index.rxml', :layout => false and return
      end
    end
  end 
  
end

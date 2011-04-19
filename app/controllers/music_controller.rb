class MusicController < StoreController
 @@per_page = 116

 skip_before_filter :verify_authenticity_token, :only => [:add_comment, :search]

 def add_comment
  product = Product.find(params['id'])
   if (params['recaptcha'] || '').downcase != 'monday'
    flash[:notice] = 'Recaptcha failed -- hit back in your browser and try again'
   else
     new_hash = {}
     # extract the ones we care about
     for key in [:id, :comment, :user_name, :user_email, :user_url, :overall_rating, :difficulty_rating]
      new_hash[key] = params[key]
     end
     product.comments << Comment.new(new_hash)
     flash[:notice] = 'Comment saved'
   end
   redirect_to :action => :show, :id => product.code
 end

 def product_matches p, parent_tag_groups
  # it must match one member of each group
  for tag_ids in parent_tag_groups.values
    return false if (tag_ids - p.tag_ids).length == tag_ids.length # no intersection? you're done
  end
  true
 end


  def show
    @product = Product.find_by_code(params[:id])
    if !@product
      flash[:notice] = "Sorry, we couldn't find the product you were looking for"
      redirect_to :action => 'index' and return false
    end
    @title = @product.name
    @images = @product.images.find(:all)
    @default_image = @images[0]
    @variations = @product.variations.find(
      :all,
      :order => '-variation_rank DESC',
      :conditions => 'quantity > 0'
    )
    render :layout => 'main_no_box'
  end

  def advanced_search

  end

  def advanced_search_post
   tags = params[:product][:tag_ids].map{|id| Tag.find(id)}
  
   parent_tag_groups = {}
   for tag in tags
    if tag.parent
      parent_id = tag.parent.id
      child_id = tag.id
    else
      # allow for parent tags, too
      parent_id = child_id = tag.id
    end
     parent_tag_groups[parent_id] ||= []
     parent_tag_groups[parent_id] << child_id
   end

   all_products = Product.find(:all) # LODO sql for all this :)
  
   @products = all_products.select{|p|
     product_matches(p, parent_tag_groups)
   }
  
   @do_not_paginate = true # XXXX enable paginate
   render :action => 'index.rhtml'
 end

  # Shows products by tag or tags.
  # Tags are passed in as id #'s separated by commas.
  #
  def show_by_tags
    # Tags are passed in as an array.
    # Passed into this controller like this:
    # /store/show_by_tags/tag_one/tag_two/tag_three/...
    @tag_names = params[:tags] || []
    # Generate tag ID list from names
    tag_ids_array = Array.new
    for name in @tag_names
      temp_tag = Tag.find_by_name(name)
      if temp_tag then
        tag_ids_array << temp_tag.id
      else
        render(:file => "#{RAILS_ROOT}/public/404.html", :status => 404) and return
      end
    end

    if tag_ids_array.size == 0
      render(:file => "#{RAILS_ROOT}/public/404.html", :status => 404) and return
    end

    if temp_tag.parent
      # my own :P
      # @tag_names.unshift temp_tag.parent.name
    end

    @viewing_tags = Tag.find(tag_ids_array, :order => "parent_id ASC")
    viewing_tag_names = @viewing_tags.collect { |t| " > #{t.name}"}
    @title = "Songs #{viewing_tag_names}"
    @tags = Tag.find_related_tags(tag_ids_array)

    # Paginate products so we don't have a ton of ugly SQL
    # and conditions in the controller
    list = Product.find_by_tags(tag_ids_array, true)
    list = list.sort_by{|p| p.name}
    pager = Paginator.new(list, list.size, @@per_page, params[:page])
    @products = returning WillPaginate::Collection.new(params[:page] || 1, @@per_page, list.size) do |p|
      p.replace list[pager.current.offset, pager.items_per_page]
    end

    if @viewing_tags[0].bio
      @display_bio = @viewing_tags[0].bio
    end
    if @viewing_tags[0].composer_contact.present?
      @display_composer_contact = @viewing_tags[0].composer_contact
      @display_composer_contact = "mailto:" + @display_composer_contact if @display_composer_contact =~ /.@./ 
    end

    render :action => 'index.rhtml'
  end
  
  # Downloads a file using the original way
  # this way forces an "out of browser" download which is good...
  def download_file
    download_helper 'attachment'
  end

  # inline is both mp3 and pdf's...
  def inline_download_file
    download_helper 'inline'
  end

  def download_helper disposition
    logger.info request.headers['User-Agent']
    logger.info request.headers['Accept-Language']
    # find download...
    file = Download.find(:first, :conditions => ["id = ?", params[:download_id]])
    if file && File.exist?(file.full_filename)
      if request.headers['Accept-Language'] && (request.headers['User-Agent'] !~ /bot /i)
        # I think even mp3's get one of these hits first, before
        # they pass it off to their browser...
        file.count += 1
      end
      file.save # necessary? probably...
      args = {:disposition => disposition}
      # allow for mp3 style download to not be type pdf
      # TODO this doesn't actually inline anything else then...but at least it wurx
      filename = file.full_filename
      if filename =~ /\.pdf$/
        args[:type] = 'application/pdf'
      elsif filename =~ /\.(mid|midi|mp3|wav)/
        args[:type] = "audio/#{$1}"
      end
      send_file(file.full_filename, args)
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
  
  def search
    @search_term = params[:search_term]
    @title = "Search Results for: #{@search_term}"
    
    # XXX paginate :)
    
    @products = Product.find(:all,
      :order => 'name ASC',
      :conditions => [
        "(name LIKE ? OR code = ?) AND #{Product::CONDITIONS_AVAILABLE}", 
        "%#{@search_term}%", @search_term
      ]
    )

    # search for tags, too
    @tags = Tag.find(:all,
      :order => 'name ASC',
      :conditions => [
        "(name LIKE ?)", 
        "%#{@search_term}%"
      ]
    )
    
    all_ids = @products.map(&:id) + @tags.map{|t| t.products.map(&:id)}.flatten
    # re map to fellas...
    @products = all_ids.uniq.map{|id| Product.find(id) }

    # Paginate products so we don't have a ton of ugly SQL
    # and conditions in the controller
    list = @products
    pager = Paginator.new(list, list.size, @@per_page, params[:page])
    @products = returning WillPaginate::Collection.new(params[:page] || 1, @@per_page, list.size) do |p|
      p.replace list[pager.current.offset, pager.items_per_page]
    end
 
    # If only one product comes back, take em directly to it.
    if @products.size == 1
      redirect_to :action => 'show', :id => @products[0].code and return
    else
      render :action => 'index.rhtml'
    end
  end

end

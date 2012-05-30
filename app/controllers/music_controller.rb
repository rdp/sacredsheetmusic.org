class MusicController < StoreController
 @@per_page = 11116

 skip_before_filter :verify_authenticity_token, :only => [:add_comment, :search]

  def session_object
    @_session_object ||= Session.find_or_create_by_sessid(request.session_options[:id])
  end

   # Wishlist items
  def wishlist
       @title = "Saved Bookmarkeds"
       @wishlist_items = session_object.wishlist_items # lacks pagination...
  end
  
  def add_to_wishlist
    if params[:id]
      if item = Item.find_by_id(params[:id])
        session_object.wishlist_items << WishlistItem.new(:item_id => item.id)
      else
        flash[:notice] = "Sorry, we couldn't find the item that you wanted to add to your wishlist. Please try again."
      end
    else
      flash[:notice] = "You didn't specify an item to add to your wishlist..."
    end
    redirect_to :action => 'wishlist' and return
  end

  def remove_wishlist_item
    WishlistItem.find(params[:id]).destroy
    render :text => '' # render nothing...
  end

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
     flash[:notice] = 'Comment saved! Thanks!'
     OrdersMailer.deliver_inquiry(
       Preference.get_value('mail_username'),
       new_hash.pretty_inspect + ' http://freeldssheetmusic.org/s/' + product.code + "\n" + product.composer_tag.andand.composer_contact
      )
     product.clear_my_cache
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
 
 def wake_up
  Cache.first
  Product.first
  #Download.first # sigh
  #Tag.first # might be cached LOL
  render :text => "what a beautiful morning!" and return # for cron
 end

 def redirect_to_original_url
   redirect_to_original_url_helper false
 end

 def redirect_to_original_url_v # v meaning "with view" :P
   redirect_to_original_url_helper true
 end

 private
 def redirect_to_original_url_helper inc_view
   product = Product.find_by_code(params[:id])
   if !product
     flash[:notice] = 'unexpected redirect not found this should never happen'
     render(:file => "#{RAILS_ROOT}/public/404.html", :status => 404) and return
   end
   if not_a_bot
     # avoid after_save blocks ...
     Product.increment_counter(:redirect_count, product.id)
     Product.increment_counter(:view_count, product.id) if inc_view
   end
   redirect_to product.original_url # not permanent redirect code...not sure if that's right...
 end 

 private
 def redirect_to_tag name
   redirect_to '/' + name.gsub(' ', '_').gsub('/', '%2F'), :status => :moved_permanently
   true
 end

 public 
 def show
    id = params[:id]
    if !id.present?
      render(:file => "#{RAILS_ROOT}/public/404.html", :status => 404) and return
    end

    @product = Product.find_by_code(id, :include => [:downloads, {:tags => [:parent]}]) # no cacheing yet on the show page...
    # nb that we can't include :images because it comes in unsorted...Rails!!!

    if !@product || request.request_uri =~ /music.show/ || request.request_uri.start_with?( '/m/')
      if Product.find_by_code(new_id = id.gsub(/[-]+/, '-'))
        redirect_to :action => 'show', :id => new_id, :status => :moved_permanently
        return false
      else
        check_id = id.gsub('_', ' ')
        if Tag.find_by_name(check_id)
          redirect_to_tag(check_id) and return
        else
          flash[:notice] = "Sorry, we couldn't find the song you were looking for, we've been under a bit of construction so please search again it may have moved! " + id.to_s
          redirect_to :action => 'index', :status => 303 and return false # 303 is not found redirect 301 is moved permanently
        end
      end
      # never get here...
    end

    if @product.code != id
      # mis capitalized
      redirect_to :action => 'show', :id => @product.code, :status => :moved_permanently
      return
    end
    if not_a_bot
      # avoid after_save blocks ...
      Product.increment_counter(:view_count, @product.id)
    end
    if @product.composer_tag
       @title = "#{@product.name} (by #{@product.composer_tag.name})"
    else
       @title = @product.name
    end
    @images = @product.images
    @default_image = @images[0]

    #@variations = @product.variations.find(
    #  :all,
    #  :order => '-variation_rank DESC',
    #  :conditions => 'quantity > 0'
    #)

    render :layout => 'main_no_box'
  end

  def advanced_search
    # place holder...
  end

  def advanced_search_post
   tags = params[:product][:tag_ids].map{|id| Tag.find(id)}
   @title = 'Advanced search:' + tags.map{|t| t.name}.join(' and ') 
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

   all_products = Product.find(:all, :conditions => Product::CONDITIONS_AVAILABLE) # LODO sql for all the above :)
  
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
    # /tag_one/tag_two/tag_three/...

    @tag_names = params[:tags] || []
    if @tag_names == ['index-of-free-lds-mormon-arrangements-choir-piano-solo'] # LODO could make this a route...
        render_component(
              :controller => "content_nodes",
              :action => "show_by_name",
              :params => {
                :name => @tag_names[0],
              }
            )
      return
    end
    # Generate tag ID list from names
    tag_ids_array = Array.new
    for name in @tag_names
      if name =~ / /
        redirect_to_tag(name) and return
      end
      real_name = name.gsub('_', ' ')# allow for cleaner google links coming in...
      temp_tag = Tag.find_by_name(real_name) 
      if temp_tag then
        tag_ids_array << temp_tag.id
      else
        render(:file => "#{RAILS_ROOT}/public/404.html", :status => 404) and return
      end
      if temp_tag.name != real_name # redirect capitalization fail
        redirect_to_tag(temp_tag.name) and return
      end  
    end

    if tag_ids_array.size == 0
      render(:file => "#{RAILS_ROOT}/public/404.html", :status => 404) and return
    end

    @viewing_tags = Tag.find(tag_ids_array, :order => "parent_id ASC", :include => :parent)
    # Paginate products so we don't have a ton of ugly SQL
    # and conditions in the controller
    all_products = Product.find_by_tags(tag_ids_array, true)
    if @viewing_tags[0].is_hymn_tag? || @viewing_tags[0].is_topic_tag?
      session['rand_seed'] ||= rand(300000) # the irony
      srand(session['rand_seed'])
      all_products = all_products.sort_by{ rand }
      srand # re-enable randomizer
    else
      #all_products = all_products.sort_by{|p| p.name} # already sorted  by :date_available
    end
    pager = Paginator.new(all_products, all_products.size, @@per_page, params[:page])
    @products = returning WillPaginate::Collection.new(params[:page] || 1, @@per_page, all_products.size) do |p|
      p.replace all_products[pager.current.offset, pager.items_per_page]
    end

    @tag_names = @viewing_tags.map{|t| t.is_hymn_tag? ? t.name + " sheet music (#{@products.size} free arrangements)" : t.name}
    viewing_tag_names = @tag_names.join(" > ")
    @title = "#{viewing_tag_names}"

    if @viewing_tags[0].bio
      @display_bio = @viewing_tags[0].bio
    end

    if @viewing_tags[0].composer_contact.present?
      @composer_tag = @viewing_tags[0]
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

  def ambiguous_download
    download_helper 'inline', false
  end

  def not_a_bot
    ua = request.headers['User-Agent']
    al = request.headers['Accept-Language']
    not_bot = al.present?

    not_bot = true if ua =~ /MSIE \d.\d|Mac |Apple|translate.google.com|Gecko|player|Windows NT/i # players and browser players, etc.
    not_bot = true if ua =~ /^Mozilla\/\d/ # [Mozilla/5.0] [] huh? maybe their default player? # This kind of kills our whole system though...
    not_bot = true if ua =~ /stagefright/ # android player
    # but it's fun to try and perfect :P
    # slightly prefer to undercount uh guess
    not_bot = false if ua =~ /yahoo.*slurp/i
    not_bot = false if ua =~ /spider/i # baiduspider
    not_bot = false if ua =~ /bot[^a-z]/i # robot, bingbot (otherwise can't get the Mozilla with bingbot, above), various others calling themselves 'bot'
    not_bot = false if ua =~ /crawler/i # alexa crawler etc.

    if not_bot
      prefix= "not bot:"
    else
      prefix= "yes bot:"
    end
    logger.info "#{prefix} [#{ua}] [#{al}]" unless ua =~ /Wget/
    if session[:user]
      logger.info "logged in user, fingindo ser bot para nao adjustar numeros"
      return false
    end

    not_bot
  end

  def download_helper disposition, add_count = true
    # find download...
    file = Download.find(:first, :conditions => ["id = ?", params[:download_id]])
    if file && File.exist?(file.full_filename)
      if add_count && not_a_bot
        # unfortunately I think mp3's get downloaded via browser sometimes (via qt) on page view
        # so I guess this'll be half and half still...
        file.count += 1
        file.save # necessary? probably...
      end
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

  # Our simple all songs list
  def index
    if request.request_uri == '/music'
      redirect_to :action => :index, :status => :moved_permanently
      return
    end
    @title = "All Songs"
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
        render(:file => "#{RAILS_ROOT}/public/404.html", :status => 404) and return # no rss for now--facebook uh guess :P
      end
    end
  end 

  def most_recently_added
        @title = 'Recently added'
        @products = Product.paginate(
          :order => 'date_available DESC',
          :conditions => Product::CONDITIONS_AVAILABLE,
          :page => params[:page],
          :per_page => 50
        )
        render :action => 'index.rhtml' and return
  end
  
  def search
    @search_term = params[:search_term] || ''
    unless @search_term.present?
      flash[:notice] = "please enter a search query at all!"
      logger.debug("no search terms?" + params.inspect)
      redirect_to :action => 'index' and return false
    end
    @title = "Search Results for: #{@search_term}"
    
    super_search_terms = params[:search_term].split.map{|word| first_part=word.split("'")[0]; word.downcase == 'oh' ? 'o' : word}.map{|name| name.downcase.gsub(/[^a-z0-9]/, '')}.map{|name| ["%#{name}%"]*3}.flatten
    super_search_query = (["(items.name like ? or tags.name like ? or items.description like ?)"]*(super_search_terms.length/3)).join(" and ")

    # XXX paginate :)
    conds = [
        "(items.name LIKE ? OR code = ? OR (#{super_search_query})) AND #{Product::CONDITIONS_AVAILABLE}", 
        "%#{@search_term}%", @search_term # name, code
    ] + super_search_terms

    products = Product.find(:all, :include => [:tags],
      :order => 'items.name ASC', :conditions => conds
    )

    # search for matching tags, too
    @tags = Tag.find(:all,
      :order => 'name ASC',
      :conditions => [
        "(name LIKE ?)", 
        "%#{@search_term}%"
      ]
    )

    good_hits = Product.find(:all, :conditions => ['name like ?',  "%#{@search_term}%"])
    
    all_ids_merged = good_hits.map(&:id) + products.map(&:id) + @tags.map{|t| t.products.map(&:id)}.flatten

    # re map to fellas...
    @products = all_ids_merged.uniq.map{|id| Product.find(id) }

    # Paginate products so we don't have a ton of ugly SQL
    # and conditions in the controller
    list = @products
    pager = Paginator.new(list, list.size, @@per_page, params[:page])
    @products = returning WillPaginate::Collection.new(params[:page] || 1, @@per_page, list.size) do |p|
      p.replace list[pager.current.offset, pager.items_per_page]
    end
 
    # If only one product comes back, take em directly to it.
    session[:last_search] = @search_term
    if @products.size == 1
      flash[:notice] = 'Found one song that matches: ' + @search_term
      redirect_to :action => 'show', :id => @products[0].code and return
    else
      render :action => 'index.rhtml'
    end
  end

  def radio_playlist_all
    server = "http://" + request.env["SERVER_NAME"]
    dls = Download.find(:all, :order => "rand()").select{|dl| dl.name =~ /.mp3$/i}
    # create playlist
    out = "#EXTM3u\n"
    dls.each_with_index{|dl,idx|
      url = server + dl.relative_path_to_web_server
      if dl.product
        composer = dl.product.composer_tag ? " #{dl.product.composer_tag.name}" : ''
        name = composer + ',' + dl.product.name
      else
        name = dl.name
      end
      idx = idx + 1 # 1 based :)
    
    out  += <<-EOL
#EXTINF:-1, #{name}
#{url}
    EOL
    }    
    render :text => out, :content_type => "audio/x-mpegurl"
  end

end

class MusicController < StoreController
 @@per_page = 11116

 skip_before_filter :verify_authenticity_token, :only => [:add_comment, :search]

  def session_object
    @_session_object ||= Session.find_or_create_by_sessid(request.session_options[:id])
  end

   # Wishlist items
  def wishlist
     @title = "Saved Bookmarked songs"
     @wishlist_items = session_object.wishlist_items # lacks pagination...
  end
  
  def add_to_wishlist
    if params[:id]
      if item = Item.find_by_id(params[:id])
        if not_a_bot || logged_in_user?
          session_object.wishlist_items << WishlistItem.new(:item_id => item.id)
        end
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

 # this is an "or" currently, for if it has any tags...
 def find_by_tag_ids(tag_ids, find_available=true, order_by="items.name ASC")
    sql = "products_tags.tag_id IN (?)"
    sql << "AND #{Product::CONDITIONS_AVAILABLE}" if find_available==true
  #  sql << "GROUP BY items.id HAVING COUNT(*)=#{tag_ids.length} "
    Product.find(:all, :group => 'items.id', :joins => :tags, :group => 'items.id', :include => :tags, :conditions => [sql, tag_ids], :order => order_by)
 end 

 def wake_up
  #Cache.first
  #Product.first
  #Download.first
  #Tag.first # might be cached so might not need this LOL
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
     # avoid all after_save procs ...
     Product.increment_counter(:redirect_count, product.id)
     Product.increment_counter(:view_count, product.id) if inc_view
   end
   redirect_to product.original_url # not permanent redirect code...not sure which is right...
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
    #
    @already_bookmarked = session_object.wishlist_items.map{|wl| wl.item}.include? @product

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

  def filter_by_current_main_tag! these_products
    if these_products.length > 1
      @was_filtered_able = true
      old_id = session['filter_all_tag_id']
      logger.info old_id
      if old_id.present?
        @old_global_filter = old_id.to_i 
        @total_count_before_filtering = these_products.length
      #logger.info these_products.map{|p| p.tag_ids}.inspect
        
        these_products.select!{|p| p.tag_ids.include? @old_global_filter }
        if @title
           @title += " (#{@total_count_before_filtering} arrangements limited to only #{Tag.find(old_id).name} [#{these_products.length}])"
        end
      end
    end
  end 

  def change_global_filter
   id = params['id']
   session['filter_all_tag_id'] = id
   if id.present?
     flash[:notice] = "Ok, results (and future results) now filtered/limited to just #{Tag.find(id).name}"
   else
     flash[:notice] = "Ok, showing *all* results now"
   end
   render :text => "alert('asdf');" # does nothing [?!]
  end

  def render_home
        render_component(
              :controller => "content_nodes",
              :action => "show_by_name",
              :params => {
                :name => 'index-of-free-lds-mormon-arrangements-choir-piano-solo',
              }
            )
  end

  def reset
    expire_page :action => :show_by_tags   
    render :text => "ok reset 'em"
  end

  #caches_page :show_by_tags, :index
  def render_cached_if_exists cache_name
    if Time.now.wday == 0 # Sunday
      cache_name = cache_name + '_sunday'
    end
    if logged_in_user?
      cache_name = cache_name + '_admin'
    end
    filename = RAILS_ROOT+"/public/cache/#{cache_name}.html"
    if File.file? filename
     logger.info "rendering early cache #{cache_name}..."
     render :text => File.read(filename) and return true
    else
     logger.info "early cache doesn't exist #{cache_name}..."
    end
    false
  end

  def render_and_cache rhtml_name, cache_name
    if Time.now.wday == 0 # Sunday
      cache_name = cache_name + '_sunday'
    end
    if logged_in_user?
      cache_name = cache_name + '_admin'
    end
    text = render_to_string rhtml_name
    cache_dir = RAILS_ROOT+"/public/cache"
    Dir.mkdir cache_dir unless File.directory?(cache_dir)
    if !flash[:notice].present?
      File.write("#{cache_dir}/#{cache_name}.html", text)
    end
    render :text => text 
  end


  # Shows products by tag or tags.
  # Tags are passed in as id #'s separated by commas.
  #
  def show_by_tags
    # Tags are passed in as an array.
    # Passed into this controller like this [except we only use at most one]...:
    # /tag_one/tag_two/tag_three/...
    tag_names = params[:tags] || [] # 
    not_a_bot # for logging purposes :P
    raise 'multiple tags names not expected?' + tag_names.inspect if tag_names.length != 1 # LODO check
    cache_name = tag_names[0].gsub('/', '_') # filenames can't have slashes...
    if !session['filter_all_tag_id'].present? && !flash[:notice].present?
      return if render_cached_if_exists(cache_name)
    end
    # Generate tag ID list from names
    tag_ids_array = Array.new
    tag_names.map!{|name|
      if name =~ / / # old school name 
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
      real_name
    }

    if tag_ids_array.size == 0
      render(:file => "#{RAILS_ROOT}/public/404.html", :status => 404) and return
    end

    @viewing_tags = Tag.find(tag_ids_array, :order => "parent_id ASC", :include => [:parent, :children])

    # Paginate products so we don't have a ton of ugly SQL
    # and conditions in the controller
    # 
    # lacking #tag_ids for now [non eager load] might actually be ok...
    all_products = Product.find_by_tags(tag_ids_array, true, "items.name ASC")
    if !@viewing_tags[0].is_composer_tag?#~ /arrangements/i
      all_products = randomize(all_products)
    else
      # all_products = all_products.sort_by{|p| p.name} # already sorted by name
    end

    #viewing_tag_names = tag_names.join(" > ")
    original_size = all_products.size
    t = @viewing_tags[0]
    if original_size > 0
      if t.is_topic_tag?
        @title = "#{t.name} sheet music (#{original_size} Free Arrangements)"
      else # arrangement...
        @title = "#{t.name} (#{original_size} Free Arrangements)"
      end
    else
      # don't say Topics (0 free arrangements) LOL
    end
    @products = paginate_and_filter(all_products)

    if @viewing_tags[0].bio
      @display_bio = @viewing_tags[0].bio
    end

    if @viewing_tags[0].composer_contact.present?
      @composer_tag = @viewing_tags[0]
    end
    if !session['filter_all_tag_id'].present?
      render_and_cache('index.rhtml', cache_name)
    else
      render 'index.rhtml' # render every time...
    end
  end

  def only_on_this_site
    @products = Tag.find_all_by_only_on_this_site(true).map{|t| t.products}.flatten 
    def @products.total_pages # fake it out :P
      1
    end
    render 'index.rhtml'
  end

  def randomize all_products
    titles = {} # keep them organized by title.
    # keep them random within title though :P
    all_products.sort_by{ rand }.sort_by{|p| 
      if p.hymn_tags.length > 0
        hymn_tag = p.hymn_tags.sort_by{|t| t.name}.first 
        titles[hymn_tag] ||= rand
        titles[hymn_tag]
      else
        rand # an original, I presume
      end
    }
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
    not_bot = false if ua =~ /robot/i #  http://help.naver.com/robots/ Yeti
    not_bot = false if ua =~ /crawler/i # alexa crawler etc.
    not_bot = false if ua =~ /webfilter/ # genio crawler
    not_bot = false if ua =~ /walker/i # webwalker
    not_bot = false if ua =~ /nutch/i # aghaven/nutch crawler
    not_bot = false if ua =~ /Chilkat/ # might be a crawler...prolly http://www.forumpostersunion.com/showthread.php?t=4895
    not_bot = false if ua =~ /search.goo.ne.jp/ # ichiro

    if not_bot
      prefix= "not bot:"
    else
      prefix= "yes bot:"
    end
    logger.info "#{prefix} [#{ua}] [#{al}]" unless ua =~ /Wget/
    if logged_in_user?
      logger.info "logged in user, fingindo ser bot para nao adjustar numeros"
      return false
    end

    not_bot
  end

  def logged_in_user?
    session[:user]
  end

  def download_helper disposition, add_count = true # this can get down to 7ms
    file = Download.find(params[:download_id])
    if file && File.exist?(filename = file.full_filename)
      if add_count && not_a_bot
       # unfortunately I think mp3's get downloaded via browser sometimes (via qt) on page view
       # so I guess this'll be half and half still...
       file.update_attribute(:count, file.count + 1) # waaay faster than file.save gah, could use update_attributes here?
      end
      args = {:disposition => disposition}
      # allow for mp3 style download to not be type pdf
      # LODO this doesn't actually inline anything else besides pdf...but at least it wurx
      if filename =~ /\.pdf$/
        args[:type] = 'application/pdf'
      elsif filename =~ /\.(mid|midi|mp3|wav)/
        args[:type] = "audio/#{$1}"
      else
        logger.info "whoa unknown type from filename? #{filename}" 
      end
      send_file(filename, args)
    else
      render(:file => "#{RAILS_ROOT}/public/404.html", :status => 404) and return
    end
  end

  def current_process_count_including_us
    count_including_us = `ps -ef | egrep wilkboar.*dispatch.fcgi | wc -l`.to_i-2
  end

#  def warmup_cache_in_other_thread
#    Thread.new { Dir[RAILS_ROOT + '/public/cache/*'].each{|f| File.read(f) }} # warm up thread LOL
#  end 

  def all_no_cache
    if current_process_count_including_us < 2
      Thread.new {  `curl http://freeldssheetmusic.org/music/wake_up` }# unfortunately have to 'wait' for this inline
      # otherwise the request just gets handled by this process again. 
      start = Time.now
      while((Time.now - start) < 5 && current_process_count_including_us < 2)
        sleep 0.1
      end
      logger.info "bumped it to #{current_process_count_including_us}"
    else
      logger.info "already high enough #{current_process_count_including_us}"
    end
    #@no_individ_cache = true # LODO remove...
    #index # reads them all
    render :text => 'ok'
  end

  # Our simple all songs list
  def index
    return if render_cached_if_exists('all_songs')
    @title = "All Songs"
    respond_to do |format|
      format.html do
        @tags = Tag.find_alpha
        @viewing_tags = nil # paginate_and_filter
        @products = Product.find(:all,
          :order => 'name ASC',
          :conditions => Product::CONDITIONS_AVAILABLE
        )
        def @products.total_pages # fake it out :P
          1
        end
        render_and_cache('index.rhtml', 'all_songs') and return
      end
      format.rss do
        render(:file => "#{RAILS_ROOT}/public/404.html", :status => 404) and return # no rss for now--facebook uh guess :P
      end
    end
  end 

  def most_recently_added
    @title = 'Recently added'
    @products = paginate_and_filter(Product.find(:all,
      :order => 'date_available DESC',
      :conditions => Product::CONDITIONS_AVAILABLE
    ), 50)
    render :action => 'index.rhtml' and return
  end
  
  def search
    @search_term = params[:q] || ''
    unless @search_term.present?
      flash[:notice] = "please enter a search query at all!"
      logger.debug("no search terms?" + params.inspect)
      redirect_to :action => 'index' and return false
    end

    @title = "Search Results for: #{@search_term}"
    super_search_terms = @search_term.split.map{|word| first_part=word.split("'")[0]; word.downcase == 'oh' ? 'o' : word}.map{|name| name.downcase.gsub(/[^a-z0-9]/, '')}.map{|name| ["%#{name}%"]*3}.flatten
    super_search_query = (["(items.name like ? or tags.name like ? or items.description like ?)"]*(super_search_terms.length/3)).join(" and ")

    # XXX paginate within the query itself LOL :)
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

    # re map to product objects...
    all_products = all_ids_merged.uniq.map{|id| Product.find(id) }.select{|p| p.date_available < Time.now}
    all_products = randomize(all_products)
    @products = paginate_and_filter all_products
 
    # If only one product comes back, take em directly to it.
    session[:last_search] = @search_term
    if all_ids_merged.uniq.size == 1 && @products.length > 0 # we're showing it
      # only redirect if one query matches, not if their filter gets it down to just 1 possible, since we don't list filters at all on the show page
      flash[:notice] = 'Found (showing) one song that matches: ' + @search_term
      redirect_to :action => 'show', :id => @products[0].code and return
    else
      render :action => 'index.rhtml'
    end
  end

#  def search_and_paginate_and_filter terms
#    products = Product.find terms
#    paginate_and_filter(products)
#  end

  def paginate_and_filter products, per_page = @@per_page
    # filter first
    filter_by_current_main_tag! products
    # Paginate products so we don't have a ton of ugly SQL
    # and conditions in the controller
    list = products
    pager = Paginator.new(list, list.size, per_page, params[:page])
    returning WillPaginate::Collection.new(params[:page] || 1, per_page, list.size) do |p|
      p.replace list[pager.current.offset, pager.items_per_page]
    end
  end

end

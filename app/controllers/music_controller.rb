class MusicController < StoreController
#  @@per_page = 3

 skip_before_filter :verify_authenticity_token, :only => :add_comment # until I get it setup right...

 def add_comment

    #post :add_comment, :id => p.id, :comment => 'new comment34', :user_name => 'user name', 
    #   :user_email => 'a@a.com', :user_url => 'http://fakeurl', :overall_rating => 3 # no difficulty rating
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

 def advanced_search_post
   tag_ints = params[:product][:tag_ids].map{|id| id.to_i}
   all_products = Product.find(:all) # LODO sql for this :)
  
   @products = all_products.select{|p|
     # must have all, or rather it must include them all so subtracting them results in size 0
     (tag_ints - p.tag_ids).length == 0
   }
#  require '_dbg'
  
   @do_not_paginate = true # XXXX paginate ?
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

    @viewing_tags = Tag.find(tag_ids_array, :order => "parent_id ASC")
    viewing_tag_names = @viewing_tags.collect { |t| " > #{t.name}"}
    @title = "Songs #{viewing_tag_names}"
    @tags = Tag.find_related_tags(tag_ids_array)

    # Paginate products so we don't have a ton of ugly SQL
    # and conditions in the controller
    list = Product.find_by_tags(tag_ids_array, true)
    pager = Paginator.new(list, list.size, @@per_page, params[:page])
    @products = returning WillPaginate::Collection.new(params[:page] || 1, @@per_page, list.size) do |p|
      p.replace list[pager.current.offset, pager.items_per_page]
    end

    render :action => 'index.rhtml'
  end
end

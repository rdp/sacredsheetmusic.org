class MusicController < StoreController

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

 def advanced_search
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

end

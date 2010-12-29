class MusicController < StoreController

 skip_before_filter :verify_authenticity_token, :only => :add_comment # until I get it setup right...

 def add_comment

    #post :add_comment, :id => p.id, :comment => 'new comment34', :user_name => 'user name', 
    #   :user_email => 'a@a.com', :user_url => 'http://fakeurl', :overall_rating => 3 # no difficulty rating

   product = Product.find(params['id'])
   new_hash = {}
   # extract the ones we care about
   for key in [:id, :comment, :user_name, :user_email, :user_url, :overall_rating, :difficulty_rating]
    new_hash[key] = params[key]
   end
   product.comments << Comment.new(new_hash)
   redirect_to :action => :show, :id => product.code
 end

end

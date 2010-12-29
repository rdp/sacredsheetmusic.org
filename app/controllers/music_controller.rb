class MusicController < StoreController

 skip_before_filter :verify_authenticity_token, :only => :add_comment # until I get it setup right...

 def add_comment
   product = Product.find(params['id'])
   product.comments << Comment.new(:comment => params['comment'])
   redirect_to :action => :show, :id => product.code
 end

end

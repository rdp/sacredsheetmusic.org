class WishlistToSession < ActiveRecord::Migration
def self.up
    rename_column :wishlist_items, :order_user_id, :session_id
  end
  
  def self.down
   raise 'huh?'
  end
end

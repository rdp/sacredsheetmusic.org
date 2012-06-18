require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/session"

class Session

  has_many :wishlist_items,
    :dependent => :destroy,
    :order => "created_on DESC"

  def self.clear!
   raise 'dont call this'
   delete_all # skips validation...
  end  
end

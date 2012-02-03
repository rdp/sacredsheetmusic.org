require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/session"

class Session
  def self.clear!
   delete_all # skips validation...
  end  
end

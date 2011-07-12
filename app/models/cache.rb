class Cache < ActiveRecord::Base
  set_table_name 'cache'

  def self.get_or_set(hash)
    if a = Cache.find_by_hash_key(hash)
      # assume string for now
      a.string_value
    else
      string_value = yield
      outgoing = Cache.new :hash_key => hash, :string_value => string_value
      outgoing.save
      string_value 
    end
  end
end

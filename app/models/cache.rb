class Cache < ActiveRecord::Base
  set_table_name 'cache'
  def self.clear!
     delete_all
  end
  # one that uses AR instance' attributes too <yikes rails>
  def self.get_or_set_records collection, identifier
    if collection.length > 0
      get_or_set( [identifier, collection.map{|record| [record, record.attributes]}].hash) { yield }
    else
     get_or_set( [collection, identifier].hash) { yield }
    end 
  end

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

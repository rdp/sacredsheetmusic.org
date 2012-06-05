class Cache < ActiveRecord::Base

  # hash_key
  # parent_id

  set_table_name 'cache'

  def self.clear!
     delete_all # skips validations
  end

  def self.delete_by_type type
    verify_type type
    delete_all(["cache_type = ?", type])
  end

  # uses AR instance' attributes too <yikes rails' #hash ...>
  #def self.get_or_set_records_with_attributes collection, identifier
  #  get_or_set_int( collection.map{|record| [record, record.attributes]}, identifier) { yield }
  #end

  CACHE_TYPES = ['probs', 'tags', 'single_product', 'group_products'] 
  def self.verify_type type
    raise type + ' not in types ' + CACHE_TYPES.inspect unless CACHE_TYPES.contain? type
  end

  def self.map_get_or_set(collection, some_unique_identifier, type, get_int_proc)
    collection.map{|item|
      int = get_int_proc[item]
      get_or_set_int(int, some_unique_identifier, type)
   }

  end

  def self.get_or_set_int(int, some_unique_identifier, type)
    verify_type type
    hash = [int, some_unique_identifier, type].hash
    if a = Cache.find_by_hash_key(hash)
      # assume string for now
      a.string_value
    else
      string_value = yield
      outgoing = Cache.new :hash_key => hash, :string_value => string_value, :parent_id => int, :cache_type => type
      outgoing.save
      string_value 
    end
  end
end

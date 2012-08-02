class Cache < ActiveRecord::Base

  # hash_key
  # parent_id

  set_table_name 'cache'
  # use sqlite for this table...
  establish_connection(:adapter => 'sqlite3', :database =>  SQLITE3_LOCATION, :timeout => 100000)

  def self.clear!
    delete_all # skips validations
    Rails.cache.clear
  end

  def self.delete_by_type type
    verify_type type
    delete_all(["cache_type = ?", type])
    Rails.cache.clear
  end

  # uses AR instance' attributes too <yikes rails' #hash ...>
  #def self.get_or_set_records_with_attributes collection, identifier
  #  get_or_set_int( collection.map{|record| [record, record.attributes]}, identifier) { yield }
  #end

  CACHE_TYPES = ['probs', 'tags', 'single_product', 'group_products'] 
  def self.verify_type type
    raise type + ' not in types ' + CACHE_TYPES.inspect unless CACHE_TYPES.contain? type
  end

  def self.map_get_or_set(collection, some_unique_identifier, type, get_int_proc, &block)
   # lodo not need get_int_proc at all...
    
   hash_keys = collection.map{|item|
     [get_int_proc[item], some_unique_identifier, type].hash
   }
   all_got = Cache.find(:all, :conditions => ['hash_key in (?) and cache_type = ?', hash_keys, type])
   # hash them and search them, in case the order comes back weird...
   hashed = {}
   all_got.each{|cache| hashed[cache.hash_key] = cache.string_value}
   out = []
   hash_keys.each_with_index{|hash_key, idx| 
      if hashed[hash_key]
       out << hashed[hash_key]
      else
       out << get_or_set_int(get_int_proc[collection[idx]], some_unique_identifier, type) { block.call(collection[idx]) }
      end
   }
   out
  end

  def self.get_or_set_int(int, some_unique_identifier, type)
    verify_type type
    hash = [int, some_unique_identifier, type].hash
    if (val = Rails.cache.read(hash))
     logger.info "cache hit"
     return val
    elsif entry = Cache.find_by_hash_key_and_cache_type(hash, type)
      # assume string for now
      logger.info "cache semihit"
      Rails.cache.write(hash, entry.string_value)
      return entry.string_value
    else
      logger.info "cache mis"
      string_value = yield
      outgoing = Cache.new :hash_key => hash, :string_value => string_value, :parent_id => int, :cache_type => type
      outgoing.save
      Rails.cache.write(hash, string_value)
      string_value 
    end
  end
end

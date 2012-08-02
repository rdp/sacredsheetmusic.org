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

  def self.warmup_in_other_thread
    Thread.new {
      size = 0
      for entry in Cache.find(:all, :conditions => ['cache_type = ?', 'single_product'])
        Rails.cache.write(entry.hash_key, entry.string_value)
        size += 1
      end
      Rails.logger.info "warmed it up with #{size}"
    }
  end

  def self.map_get_or_set(collection, some_unique_identifier, type, get_int_proc, &block)
   # lodo not need get_int_proc at all...
   hits = 0 
   hashed_results = {}
   to_look_for = []
   hash_keys = collection.map{|item|
     hash_key = [get_int_proc[item], some_unique_identifier, type].hash
     if (val = Rails.cache.read(hash_key))
      hashed_results[hash_key] = val
      hits+=1
     else
      to_look_for << hash_key
     end
     hash_key
   }
   if to_look_for.length > 0
     all_got = Cache.find(:all, :conditions => ['hash_key in (?) and cache_type = ?', to_look_for, type])
   else
     all_got =[]
   end
   
   # hash them and search them, in case the order comes back weird...
   all_got.each{|cache| 
     hashed_results[cache.hash_key] = cache.string_value
     Rails.cache.write(cache.hash_key, cache.string_value)
   }
   out = []
   hash_keys.each_with_index{|hash_key, idx| 
      if val = hashed_results[hash_key]
        out << val
      else
        out << get_or_set_int(get_int_proc[collection[idx]], some_unique_identifier, type) { block.call(collection[idx]) }
      end
   }
   logger.info "after previous semi/mis, had #{hits} hits/#{collection.length}"
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
      logger.info "cache semihit #{hash} #{Rails.cache.inspect}"
      Rails.cache.write(hash, entry.string_value)
      return entry.string_value
    else
      logger.info "cache mis"
      string_value = yield
      unless type == 'group_products'
        entry = Cache.new :hash_key => hash, :string_value => string_value, :parent_id => int, :cache_type => type
        entry.save
      end
      Rails.cache.write(hash, string_value)
      string_value 
    end
  end
end

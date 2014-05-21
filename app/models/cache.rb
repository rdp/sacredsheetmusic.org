class Cache < ActiveRecord::Base

  # hash_key
  # parent_id

  set_table_name 'cache'

  CACHE_TYPES = ['probs', 'tags', 'single_product', 'group_products'] 

  def self.clear!
    puts "not clearing the public/cache folder...yes restarting this rails app [all instance] to clear all local caches"
    delete_all # skips validations
    Product.update_all("thumbnail_html_cache = null")
    #clear_html_cache
    clear_local_caches!
  end

  def self.clear_local_caches!
    Rails.cache.clear # like this should even matter...
    require 'fileutils'
    FileUtils.touch RAILS_ROOT + "/tmp/restart.txt"
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

  def self.verify_type type
    raise type + ' not in types ' + CACHE_TYPES.inspect unless CACHE_TYPES.contain? type
  end

  def self.warmup_in_other_thread # kind of other thread...called in like config/environment.rb or something
    start = Time.now
     puts 'about to warmup'

     raise 'dont use this anymore for now, was causing RAM failure'
    #list = Cache.find(:all)
    puts 'warmup 2'
    Thread.new {
       puts 'warmup start thred'
      
      Rails.logger.info "just getting list took #{Time.now - start}"
      for entry in list
      # copy them into local process cache...
        Rails.cache.write(entry.hash_key, entry.string_value)
      end
      Rails.logger.info "warmed it up [copied to proc cache] in other thread with #{list.size} in #{Time.now - start}s" # doesn't output for some reason...odd... takes 3s sometimes?
     }
#    Thread.new { 
#      for file in all_cache_files
#        File.read(file) rescue nil # hope this avoids disappearing files throwing...
#      end
#    }
  end

  def self.all_cache_files
    Dir[RAILS_ROOT+"/public/cache/*"]
  end

  def self.clear_html_cache
    for file in all_cache_files
      File.delete file # not multiple processs safe though...
    end
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
      logger.info "cache semihit"
      Rails.cache.write(hash, entry.string_value)
      return entry.string_value
    else
      logger.info "cache real mis"
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

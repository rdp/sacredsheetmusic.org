class CreateCache < ActiveRecord::Migration
  def self.up
    raise 'need sqlite3' if Cache.connection.class.to_s =~ /mysql/i

    create_table :cache do |t|
      #t.column <sigh> 
    end
    add_column :cache, :hash_key, :bigint
    add_column :cache, :marshalled_value, :longtext, :default => nil
    add_column :cache, :string_value, :longtext, :default => nil
    add_index  :cache, :hash_key
  end
 
  def self.down
    drop_table :cache
  end
end

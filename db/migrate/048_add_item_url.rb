class AddItemUrl < ActiveRecord::Migration

  def self.up
    add_column :items, :original_url, :string
  end

  def self.down
    remove_column :items, :original_url
  end
  
end

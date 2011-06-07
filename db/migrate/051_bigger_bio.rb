class BiggerBio < ActiveRecord::Migration

  def self.up		
    change_column :tags, :bio, :longtext
  end

  def self.down
    change_column :tags, :bio, :string
  end
  
end

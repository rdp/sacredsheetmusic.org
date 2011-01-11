class TagsAddBioAndAutoDisplay < ActiveRecord::Migration

  def self.up		
    add_column :tags, :bio, :string
    add_column :tags, :always_display_text, :string
  end

  def self.down
    remove_column :tags, :bio
    remove_column :tags, :always_display_text
  end
  
end

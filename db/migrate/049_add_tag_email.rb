class AddTagEmail< ActiveRecord::Migration

  def self.up
    add_column :tags, :composer_contact, :string
    remove_column :tags, :always_display_text # from 46...
  end

  def self.down
    remove_column :tags, :composer_contact
    add_column :tags, :always_display_text, :string
  end
  
end

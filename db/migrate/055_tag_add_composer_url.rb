class TagAddComposerUrl < ActiveRecord::Migration

  def self.up
    add_column :tags, :composer_url, :string
  end

  def self.down
    remove_column :tags, :composer_contact
  end
  
end

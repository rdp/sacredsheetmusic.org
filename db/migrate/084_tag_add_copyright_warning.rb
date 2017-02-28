class TagAddCopyrightWarning < ActiveRecord::Migration

  def self.up
    require 'sane' # yikes rails, yikes...
    add_column :tags, :copyright_warning_message, :string
  end

  def self.down # somewhat lossy :P
    remove_column :tags, :copyright_warning_message
  end
  
end

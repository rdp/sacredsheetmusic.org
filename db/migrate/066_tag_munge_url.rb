class TagMungeUrl < ActiveRecord::Migration

  def self.up
    require 'sane' # yikes rails, yikes...
    rename_column :tags, :composer_contact, :composer_contact_url
    add_column :tags, :composer_email_if_contacted, :string
    for t2 in Tag.find_by_name("composers").children
      if t2.composer_contact_url.andand.include?('@')
        t2.composer_email_if_contacted = t2.composer_contact_url
        t2.composer_contact_url = nil
        t2.save
      end
    end
  end

  def self.down # somewhat lossy :P
    rename_column :tags, :composer_contact_url, :composer_contact
    remove_column :tags, :composer_email_if_contacted
  end
  
end

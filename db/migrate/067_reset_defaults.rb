class ResetDefaults < ActiveRecord::Migration

  def self.up
    change_column :user_uploads, :count, :int, :default => 0
    change_column :items, :view_count, :int, :default => 0
    UserUpload.all.each{|uu| uu.update_attribute(:count, uu.count-1)} # avoid redoing mogrify's with a full save...
    Item.all.each{|i| Item.update_all({:view_count, i.view_count-1}, :id => i.id)} # avoid needing sane gem for full save
  end

  def self.down
    #raise 'huh'
  end
  
end

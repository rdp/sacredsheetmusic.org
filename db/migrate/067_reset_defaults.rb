class ResetDefaults < ActiveRecord::Migration

  def self.up
    change_column :user_uploads, :count, :int, :default => 0
    change_column :items, :view_count, :int, :default => 0
    UserUploads.all.each{|uu| uu.count = uu.count-1; uu.save}
    Items.all.each{|i| i.count = i.count -1; i.save}
  end

  def self.down
  end
  
end

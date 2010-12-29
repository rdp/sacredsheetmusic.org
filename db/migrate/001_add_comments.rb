class AddComments < ActiveRecord::Migration
def self.up
    create_table :comments do |t|
      t.column :product_id, :int
      t.column :comment, :string
    end
    add_index "comments", ["product_id"], :name => "pid" # why not?
  end
  
  def self.down
    drop_table :comments
  end
end

class AddCommentsCompetition < ActiveRecord::Migration

  def self.up
    add_column :comments, :is_competition, :boolean, :default => false
    add_column :comments, :created_at, :datetime
    add_column :comments, :created_ip, :string
  end

  def self.down
    remove_column :comments, :is_competition
    remove_column :comments, :created_at
    remove_column :comments, :created_ip
  end
  
end

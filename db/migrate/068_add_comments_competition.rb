class AddCommentsCompetition < ActiveRecord::Migration

  def self.up
    add_column :comments, :is_competition, :boolean, :default => false
  end

  def self.down
    remove_column :comments, :is_competition
  end
  
end

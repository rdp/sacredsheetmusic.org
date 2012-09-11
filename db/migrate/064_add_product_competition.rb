class AddProductCompetition < ActiveRecord::Migration

  def self.up
    add_column :items, :is_competition, :boolean, :default => false
  end

  def self.down
    remove_column :items, :is_competition
  end
  
end

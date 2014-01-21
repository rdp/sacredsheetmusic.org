class ProductAddCompetitionWinner < ActiveRecord::Migration

  def self.up
    add_column :items, :is_competition_winner, :boolean, :default => false
  end

  def self.down
    remove_column :items, :is_competition_winner
  end
  
end

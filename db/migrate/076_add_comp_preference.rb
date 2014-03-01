# Adds preferences table, for values that we can set via the UI.
#
class AddCompPreference < ActiveRecord::Migration
  def self.up
    Preference.create([
      { :name => 'competition_end_date', :value => "Mar 07 00:00:00 -0700 2013" },
    ])
  end
  
  def self.down
    raise "unimplemented"
  end
end

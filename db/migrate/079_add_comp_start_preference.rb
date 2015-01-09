# Adds preferences table, for values that we can set via the UI.
#
class AddCompStartPreference < ActiveRecord::Migration
  def self.up
    Preference.create([
      { :name => 'competition_start_date', :value => "Mar 07 00:00:00 -0700 2013" },
    ])
  end
  
  def self.down
    raise "unimplemented"
  end
end

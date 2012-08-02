class ProductDisplayPreferences < ActiveRecord::Migration
  def self.up
		# Add preferences for order payment delay & revenue percentage
    Preference.create(:name => 'product_is_new_week_range', :value => '2')
  end

  def self.down
    Preference.destroy_all("name = 'product_is_new_week_range'")
  end
end
require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class PreferenceTest < ActiveSupport::TestCase
  fixtures :preferences

  # TODO: Should this method be here?
  # The responsability of initialize preferences shouldn't be of other module?
  def test_should_init_mail_settings
    assert Preference.init_mail_settings
  end
  
  
  # TODO: Should this method be here?
  # The responsability of saving preferences isn't of the controller?
  # A preference should just represent one instance of preferences?
  def test_save_settings_success
    prefs = {
      "store_name" => "Substruct",
      "store_handling_fee" => "0.00",
      "store_use_inventory_control"=>"1"
    }
    assert Preference.save_settings(prefs)
  end


  # Here we verify if a preference is true.
  def test_is_true
    a_preference = preferences(:store_use_inventory_control)
    assert a_preference.is_true?

    a_preference = preferences(:store_require_login)
    assert !a_preference.is_true?
  end
  
  def test_get_value_success
    v = Preference.get_value('store_use_inventory_control')
    assert_equal(preferences(:store_use_inventory_control).value, v)
  end
  
  def test_get_value_with_bad_key
    assert_equal nil, Preference.get_value('bad_key')
  end
  
  def test_get_value_is_true_success
    assert_equal true, Preference.get_value_is_true?('store_use_inventory_control')
  end
  
  def test_get_value_is_true_with_bad_key
    assert_equal false, Preference.get_value_is_true?('bad_key')
  end


end
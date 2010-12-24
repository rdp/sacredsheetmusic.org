require 'rubygems'
require 'faster_require'
require File.dirname(__FILE__) + '/../test_helper'

# note that before running these, you'll need to propagate the test db, like
# $ rake db:create RAILS_ENV=test
# $ rake substruct:db:bootstrap RAILS_ENV=test
# $ rake db:migration RAILS_ENV=test
# now run like:
# $ ruby test/functional/store_controller_test.rb

class StoreControllerTest < ActionController::TestCase
  
  def test_matthew_is_cool
    assert true
    Product.destroy_all
    p = Product.create! :code => 'code1', :quantity => 1000, :name => 'product name', :price => 10, :date_available => Time.now
    get :show, :id => p.code
    assert_response :success
    assert_template 'show'

  end
  
end
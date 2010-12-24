$: << '.'
#require 'faster_require'
require 'rubygems'
require File.dirname(__FILE__) + '/../test_helper'

# note that before running these, you'll need to propagate the test db, like
# $ rake db:create RAILS_ENV=test
# $ rake substruct:db:bootstrap RAILS_ENV=test
# $ rake db:migratieRAILS_ENV=test
# now run like:
# $ ruby test/functional/store_controller_test.rb
    while(!File.exist?('go_tests'))
      p 'sleeping...'
      sleep 0.2
    end
    File.delete 'go_tests'
    p 'running tests'

class StoreControllerTest < ActionController::TestCase
  
  
  def test_matthew_is_cool
    assert true
    Product.destroy_all
    p = Product.create! :code => 'code1', :quantity => 1000, :name => 'product name', :price => 10, :date_available => Time.now
    get :show, :id => p.code
    assert_response :success
    assert_template 'show'
    p
  end
  
  def test_download_link
    p = test_matthew_is_cool
    p.downloads << Download.new('filename' => 'abcdef.txt', 'content_type' => 'image/jpeg', 'size' => 1024)
    get :show, :id => p.code
    assert_select "body", /abcdef/
  end
  
end
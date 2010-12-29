$: << '.'
#require 'faster_require'
require 'rubygems'
require File.dirname(__FILE__) + '/../test_helper'
require 'fileutils'

# note that before running these, you'll need to propagate the test db, like
# $ rake db:create RAILS_ENV=test
# $ rake substruct:db:bootstrap RAILS_ENV=test
# $ rake db:migratieRAILS_ENV=test
# now run like:
# $ ruby test/functional/store_controller_test.rb
=begin
unless defined?($GO_TEST)
    while(!File.exist?('go_tests'))
      p 'sleeping...'
      sleep 0.2
    end
    File.delete 'go_tests' 
    p 'running tests'
end
=end

class StoreControllerTest < ActionController::TestCase
  
  def test_create_product
    assert true
    Product.destroy_all
    p = Product.create! :code => 'code1', :quantity => 1000, :name => 'product name', :price => 10, :date_available => Time.now
    get :show, :id => p.code
    assert_response :success
    assert_template 'show'
    p
  end
  
  def test_download_link
    p = test_create_product
    p Dir.pwd
    dl = Download.new('filename' => 'abcdef.txt', 'content_type' => 'image/jpeg', 'size' => 1024)
    p.downloads << dl
    # create it
    FileUtils.mkdir_p(File.dirname(dl.full_filename))
    FileUtils.touch dl.full_filename
    get :show, :id => p.code
    assert_select "body", /abcdef/
    # how to test? assert_select "body", /download_file/
    dl
  end
  
  def test_can_download_without_logging_in
    dl = test_download_link
    get :download_file, :download_id => dl.id
    assert_response :success
  end
  
  def test_shows_comments
    p = test_create_product
    p.comments << Comment.new(:comment => "hello there")
    get :show, :id => p.code
    assert_select "body", /comment/i
    assert_select "body", /hello there/
  end
  
end

=begin
unless defined?($GO_TEST)
  $GO_TEST = 1
  load File.expand_path(__FILE__)
end
=end
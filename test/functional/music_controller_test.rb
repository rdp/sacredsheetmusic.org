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
unless defined?($GO_TEST)
  if File.exist?('pause_until_tests')
    while(!File.exist?('go_tests'))
      p 'sleeping...'
      sleep 0.2
    end
    File.delete 'go_tests' 
    p 'continuing on to run tests'
  else
   p 'touch pause_until_tests'
  end
end

class MusicControllerTest < ActionController::TestCase
  
  def test_create_product
    assert true
    Product.destroy_all
    Comment.destroy_all
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
  
  def test_shows_preexisting_comments
    p = test_create_product
    get :show, :id => p.code
  # ??  assert_not_select "body", /comments/i
    p.comments << Comment.new(:comment => "hello there")
    get :show, :id => p.code
    assert_select "body", /comments/i
    assert_select "body", /hello there/
  end
  
  def test_allows_you_to_insert_new_comment_too
    p = test_create_product
    get :show, :id => p.code
    assert_select "body", /add.*comment/i
    post :add_comment, :id => p.id, :comment => 'new comment2', :recaptcha => 'monday'
    assert_redirected_to :action => :show, :controller => :music, :id => p.code
    p
  end
  
  def test_it_should_show_newly_inserted_comment
    p = test_allows_you_to_insert_new_comment_too
    get :show, :id => p.code
    assert_select "body", /new comment2/i
  end
  
  def test_should_allow_for_url_et_al_submission
    p = test_create_product
    get :show, :id => p.code
    assert_select "div", /name/i
    assert_select "div", /url/i
    assert_select "div", /difficulty/i
    assert_select "div", /overall/i
  end
  
  def test_should_allow_for_complex_comment_submission
    p = test_create_product
    count = Comment.count
    post :add_comment, :id => p.id, :comment => 'new comment34', :user_name => 'user name', 
       :user_email => 'a@a.com', :user_url => 'http://fakeurl', :overall_rating => 3, :recaptcha => 'monday' # no difficulty rating
    assert Comment.count == count + 1
    assert_redirected_to :action => :show, :controller => :music, :id => p.code
    get :show, :id => p.code
    assert_select "body", /new comment34/
    assert_select "body", /user name/
    # how to test? assert_select "body", /fakeurl/
  end
  
  def test_without_recaptcha_fails
    p = test_create_product
    count = Comment.count
    post :add_comment, :id => p.id, :comment => 'new comment34'
    assert Comment.count == count
    assert_redirected_to :action => :show, :controller => :music, :id => p.code
    post :add_comment, :id => p.id, :comment => 'new comment34', :recaptcha => 'monday'
    assert Comment.count == count + 1
  end
  
  def test_advanced_search
    get :advanced_search
    assert_layout 'main'
  end
  
end

unless defined?($GO_TEST)
  $GO_TEST = 1
  load File.expand_path(__FILE__)
end

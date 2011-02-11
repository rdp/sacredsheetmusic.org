$: << '.'
#require 'faster_require'
require 'rubygems'
require File.dirname(__FILE__) + '/../test_helper'
require 'fileutils'
require 'substruct/assertions'

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
  include Substruct::Assertions

  def test_create_product
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
    dl = Download.new('filename' => 'abcdef.txt', 'content_type' => 'image/jpeg', 'size' => 1024)
    # some antics to create the thing...
    FileUtils.mkdir_p File.dirname(dl.full_filename)
    File.write dl.full_filename, 'abc' # gotta be size > 0
    p.downloads << dl
    # create it
    FileUtils.mkdir_p(File.dirname(dl.full_filename))
    FileUtils.touch dl.full_filename
    get :show, :id => p.code
    assert_select "body", /txt/
    # how to test? assert_select "body", /download_file/
    dl
  end
  
  def test_can_download_without_logging_in_and_increments_count_on_download
    dl = test_download_link
    assert dl.count == 0
    get :download_file, :download_id => dl.id
    assert_response :success
    assert dl.reload.count == 1
  end
  
  def test_shows_preexisting_comments
    p = test_create_product
    get :show, :id => p.code
    assert_not_match /hello there/i
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
    Tag.destroy_all
    Product.destroy_all
    # use children tags
    t1 = Tag.create!(:name => "t1")
    t1a = Tag.create!(:name => "t1.a", :parent_id => t1.id)
    t2 = Tag.create!(:name => "t2")
    t2a = Tag.create!(:name => "t2.a", :parent_id => t2.id)
    t2b = Tag.create!(:name => "t2.b", :parent_id => t2.id)

    p = Product.create!  :code => 'code1', :quantity => 1000, :name => 'product name1',
      :price => 10, :date_available => Time.now
    p.tag_ids = [t1a.id.to_s, t1.id.to_s]
    
    p2 = Product.create! :code => 'code2', :quantity => 1000, :name => 'product name2', 
      :price => 10, :date_available => Time.now
    p2.tag_ids = [t1a.id.to_s, t1.id.to_s, t2a.id.to_s, t2.id.to_s]
    
    # should work with parents, too...
    for tags in [ [t1a.id.to_s, t2a.id.to_s], [t1.id.to_s, t2.id.to_s]]
      get :advanced_search_post, {:product => {:tag_ids => tags}}
    
      assert_contains /name2/
      assert_not_match /name1/
    end
    
    get :advanced_search_post, {:product => {:tag_ids => [t1a.id.to_s]}}
    assert_contains /name2/
    assert_contains /name1/
    
    get :advanced_search_post, {:product => {:tag_ids => [t2a.id.to_s, t2b.id.to_s]}}
    assert_not_match /name1/
    assert_contains /name2/ # still finds name2, despite t3 and t2 being checked

    # with all 3 still only name2
    get :advanced_search_post, {:product => {:tag_ids => [t1a.id.to_s, t2a.id.to_s, t2b.id.to_s]}}
    assert_not_match /name1/
    assert_contains /name2/
    
  end
  
  def test_normal_search_with_tags
    test_advanced_search
    get :search, {:search_term => "name1"}
    assert assigns['products'].length == 1
    get :search, {:search_term => "t1.a"}
    assert assigns['products'].length == 2
  end
  
  def test_normal_search_with_redundancy
    test_advanced_search
    t2b = Tag.create!(:name => "tag2")
    p = Product.create!  :code => 'tag2', :quantity => 1000, :name => 'product name1',
      :price => 10, :date_available => Time.now
    p.tag_ids = [t2b.id.to_s]
    
    get :search, {:search_term => "tag2"}
    assert assigns['products'].length == 1
  end
  
  
  def assert_contains regex
    raise 'not found ' + regex.to_s unless @response.body =~ regex
  end
  
  def assert_not_match regex
    raise 'bad match' + regex.to_s if @response.body =~ regex
  end
  
end

unless defined?($GO_TEST)
  $GO_TEST = 1
  load File.expand_path(__FILE__)
end

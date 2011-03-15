require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ProductTest < ActiveSupport::TestCase

  def test_can_propogate_all
    # my fixtures shuck!
    Tag.destroy_all
    Product.destroy_all
    
    # if there's a hymns tag
    hymns = Tag.create :name => 'Hymn arrangements'
    # with a child hymn name
    child_hymn = Tag.create :name => "child hymn", :parent => hymns
    # and two products under it:
    prod1 = Product.create :name => 'prod1', :code => 'prod1'
    prod2 = Product.create :name => 'prod2', :code => 'prod2'
  
    # and one product is associated with some topic
    topics = Tag.create :name => "Topics"
    topic1 = Tag.create :name => "coolio topic", :parent => topics
    prod2.topics << topic1
    
    # and you call 
    Tag.sync_topics
    
    # then both products should end up with the topic tags
    assert prod1.refresh.tags.length == 1
    assert prod2.refresh.tags.length == 1
  end


end
require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ProductTest < ActiveSupport::TestCase

  def test_can_propogate_all
    # my fixtures shuck!
    Tag.destroy_all
    Product.destroy_all
    
    # if there's a hymns tag
    hymns = Tag.create :name => 'Hymns'
    # with a child hymn name
    @child_hymn = Tag.create :name => "child hymn", :parent => hymns
    # and two products under it:
    prod1 = Product.create :name => 'prod1', :code => 'prod1'
    prod2 = Product.create :name => 'prod2', :code => 'prod2'
    prod1.tags << @child_hymn
    prod2.tags << @child_hymn
    # and one product is associated with some topic
    @topics = Tag.create :name => "Topics"
    topic1 = Tag.create :name => "coolio topic", :parent => @topics
    prod2.tags << topic1
    
    # and you call 
    Tag.sync_topics
    
    # then both products should end up with the topic tags, and their hymn tag
    correct_lengths = proc {
      assert prod1.reload.tags.length == 2
      assert prod2.reload.tags.length == 2
    }
    correct_lengths.call
    
    # if you call it twice, same thing
    3.times{Tag.sync_topics}
    
    correct_lengths.call
    prod1
  end
  
  def test_can_cross_polinate_tags_by_hymn
    prod1 = test_can_propogate_all
    # now add a third product, with its own topic
    prod3 = Product.create :name => 'prod3', :code => 'prod3'
    topic2 = Tag.create :name => 'coolio topic2', :parent => @topics
    prod3.tags << topic2
    prod3.tags << @child_hymn
    Tag.sync_topics
    assert prod1.reload.tags.length == 3
    assert prod3.reload.tags.length == 3
  end

end
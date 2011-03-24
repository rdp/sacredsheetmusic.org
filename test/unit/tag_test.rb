require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ProductTest < ActiveSupport::TestCase

  def test_can_propagate_all
    # my fixtures shuck!
    Tag.destroy_all
    Product.destroy_all
    
    # if there's a hymns tag
    hymns = Tag.create :name => 'Hymn arrangs'
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
    
    # and an author (author tag is ignored and not copied)
    author = Tag.create :name => "arranger"
    author_instance = Tag.create :name => "a cool person's name", :parent => author
    prod2.tags << author_instance
    
    # and you call 
    Tag.sync_topics_with_warnings
    
    # then both products should end up with the topic tags, and their hymn tag
    correct_lengths = proc {
      assert prod1.reload.tags.length == 2 # does not have the author tag
      assert prod2.reload.tags.length == 3 # has the author tag
    }
    correct_lengths.call
    
    # if you call it twice, same thing
    3.times{Tag.sync_topics_with_warnings}
    
    correct_lengths.call
    prod1
  end
  
  def test_can_cross_polinate_tags_by_hymn
    prod1 = test_can_propagate_all
    # now add a third product, with its own topic
    prod3 = Product.create :name => 'prod3', :code => 'prod3'
    topic2 = Tag.create :name => 'coolio topic2', :parent => @topics
    prod3.tags << topic2
    prod3.tags << @child_hymn
    3.times {
      error_message = Tag.sync_topics_with_warnings
      assert error_message.length == 0
    }
    assert prod1.reload.tags.length == 3 # hymn name, topic1, topic2
    assert prod3.reload.tags.length == 3 # same
  end
  
  def test_gives_warnings
    Tag.destroy_all
    Product.destroy_all
    
    # given a single hymn tag (and topics tag we need too)
    hymns = Tag.create :name => 'Hymns'
    topics = Tag.create :name => "Topics"

    # with a child hymn name
    child_hymn = Tag.create :name => "child hymn", :parent => hymns
    # and a product associated
    prod3 = Product.create :name => 'prod3', :code => 'prod3'
    prod3.tags << child_hymn
    
    # it should yield an error message if you sync, because no topics are associated with that hymn, through any of its children
    assert Tag.sync_topics_with_warnings.length > 0

  end

end

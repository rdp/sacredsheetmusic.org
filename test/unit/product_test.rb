require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ProductTest < ActiveSupport::TestCase

  def test_existent_composer_contact
    composer = existent_composer_contact true
    assert composer == 'a@a.com'
  end
  
  def existent_composer_contact have_composer_contact
    Tag.destroy_all
    Product.destroy_all
    parent = Tag.create :name => 'Composer/arranger'
    if have_composer_contact
      child = Tag.create :name => 'a name', :composer_contact => 'a@a.com', :parent => parent
    else
      child = Tag.create :name => 'a name', :parent => parent
    end
    product = Product.create :name => 'prod1', :code => 'prod1'
    product.tags << child
    product.composer_contact
  end
  
  def test_composer_contact_no_email
    composer = existent_composer_contact false
    assert composer == nil
  end
  
  def test_composer_no_tag
    # unit tests run into this a bunch...
    product = Product.create :name => 'prod1', :code => 'prod2'
    assert product.composer_contact == nil
  end
  
end

require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ProductTest < ActiveSupport::TestCase
  # If the model was inherited from another model, the fixtures must be the
  # base model, as it will be used as the table name.
  fixtures :items, :tags, :preferences


  # Test if the fixtures are of the proper type.
  def test_item_should_be_of_proper_type
    assert_kind_of Product, items(:uranium_portion)
    assert_kind_of Product, items(:lightsaber)
    assert_kind_of Product, items(:holy_grenade)
    assert_kind_of Product, items(:chinchilla_coat)
    assert_kind_of Product, items(:towel)
    assert_kind_of Product, items(:the_stuff)
  end


  # Test if a valid product can be created with success.
  def test_should_create_product
    p = Product.new
    
    p.code = "SHRUBBERY"
    p.name = "Shrubbery"
    p.description = "A shrubbery. One that looks nice, and is not too expensive. Perfect for a knight who say Ni."
    p.price = 90.50
    p.date_available = "2007-12-01 00:00"
    p.quantity = 38
    p.size_width = 24
    p.size_height = 24
    p.size_depth = 12
    p.weight = 21.52
  
    assert p.save
  end


  # Test if a product can be found with success.
  def test_should_find_product
    p_id = items(:chinchilla_coat).id
    assert_nothing_raised {
      Product.find(p_id)
    }
  end


  # Test if a product can be updated with success.
  def test_should_update_product
    p = items(:chinchilla_coat)
    assert p.update_attributes(:description => 'Coat of 21 chichillas.')
  end


  # Test if a product can be destroyed with success.
  def test_should_destroy_product
    p = items(:chinchilla_coat)
    p.destroy
    assert_raise(ActiveRecord::RecordNotFound) {
      Product.find(p.id)
    }
  end


  # Test if an invalid product really will NOT be created.
  def test_should_not_create_invalid_product
    p = Item.new
    assert !p.valid?
    assert p.errors.invalid?(:code)
    assert p.errors.invalid?(:name)
    # A product must have a code and a name.
    assert_equal "can't be blank", p.errors.on(:code)
    assert_equal "can't be blank", p.errors.on(:name)
    p.code = "URANIUM"
    assert !p.valid?
    assert p.errors.invalid?(:code)
    # A product must have an unique code.
    assert_equal "has already been taken", p.errors.on(:code)
    assert !p.save
  end


  # Test if products can be associated and disassociated.
  def test_should_associate_products
    # Load some products and see if they really don't have any related products.
    a_coat = items(:chinchilla_coat)
    a_towel = items(:towel)
    a_stuff = items(:the_stuff)
    assert_equal a_coat.related_products.count, 0
    assert_equal a_towel.related_products.count, 0
    assert_equal a_stuff.related_products.count, 0
    # Associate one with the other and both must know about that.
    a_coat.related_products << a_towel
    a_coat.related_products << a_stuff
    assert_equal a_coat.related_products.count, 2
    assert_equal a_towel.related_products.count, 1
    assert_equal a_stuff.related_products.count, 1
    # Break the association backwards and it should have no related again.
    a_stuff.related_products.delete(a_coat)
    a_towel.related_products.delete(a_coat)
    assert_equal a_coat.related_products.count, 0
    assert_equal a_towel.related_products.count, 0
    assert_equal a_stuff.related_products.count, 0
  end

  # Test if products can be associated and disassociated by ids.
  def test_should_associate_products_by_ids
    # Load some products and see if it really don't have any related products.
    a_coat = items(:chinchilla_coat)
    a_towel = items(:towel)
    a_stuff = items(:the_stuff)
    assert_equal a_coat.related_products.count, 0
    assert_equal a_towel.related_products.count, 0
    assert_equal a_stuff.related_products.count, 0

#    # Associate one with the others and all must know about that.
#    # TODO: a_soap.related_product_ids should receive ids but its not doing that.
#    a_coat.related_product_ids = [ a_towel.id, a_stuff.id ]
#    assert_equal a_coat.related_products.count, 2
#    assert_equal a_towel.related_products.count, 1
#    assert_equal a_stuff.related_products.count, 1

    # Clear all and verify.
    a_coat.related_products.clear
    assert_equal a_coat.related_products.count, 0
    assert_equal a_towel.related_products.count, 0
    assert_equal a_stuff.related_products.count, 0
  end

  # Test if products can be associated by suggestion names given by autocomplete.
  def test_should_associate_products_by_suggestion_name
    # Load some products and see if it really don't have any related products.
    a_coat = items(:chinchilla_coat)
    a_towel = items(:towel)
    a_stuff = items(:the_stuff)
    assert_equal a_coat.related_products.count, 0
    assert_equal a_towel.related_products.count, 0
    assert_equal a_stuff.related_products.count, 0

    # Associate one with the others and all must know about that.
    # TODO: We could create something like #related_product_suggestion_names to receive suggestion names
    # but #related_product_ids is receiving them.
    a_suggested_towel = a_towel.suggestion_name
    a_suggested_stuff = a_stuff.suggestion_name
    # a_coat.related_product_suggestion_names = [ a_suggested_towel, a_suggested_stuff, "", "", "" ]
    a_coat.related_product_suggestion_names = [ a_suggested_towel, a_suggested_stuff, "", "", "" ]
    assert_equal a_coat.related_products.count, 2
    assert_equal a_towel.related_products.count, 1
    assert_equal a_stuff.related_products.count, 1

    # Clear all and verify.
    a_coat.related_products.clear
    assert_equal a_coat.related_products.count, 0
    assert_equal a_towel.related_products.count, 0
    assert_equal a_stuff.related_products.count, 0
  end


  # Test if products will show the quantity of its own or the sum of its
  # variations correctly.
  def test_should_show_different_quantity_if_have_variations
    # Test a product without variations.
    a_grenade = items(:holy_grenade)
    assert_equal a_grenade.variations.count, 0
    assert_equal a_grenade.quantity, a_grenade.attributes['quantity']
    # Test a product with variations.
    a_lightsaber = items(:lightsaber)
    assert_equal a_lightsaber.variations.count, 3
    assert_equal a_lightsaber.quantity, a_lightsaber.variations.sum(:quantity)
  end


  # Test if products will show the price of its own or interval of prices.
  def test_should_show_different_display_price_if_have_variations
    # Test a product without variations.
    a_grenade = items(:holy_grenade)
    assert_equal a_grenade.variations.count, 0
    assert_equal a_grenade.display_price, a_grenade.price
    # Test a product with variations.
    a_lightsaber = items(:lightsaber)
    assert_equal a_lightsaber.variations.count, 3
    assert_equal a_lightsaber.quantity, a_lightsaber.variations.sum(:quantity)
    a_lightsaber_0 = a_lightsaber.variations[0]
    a_lightsaber_1 = a_lightsaber.variations[1]
    a_lightsaber_2 = a_lightsaber.variations[2]
    # Test with different prices.
    assert_not_equal a_lightsaber_0.price, a_lightsaber_1.price
    assert_not_equal a_lightsaber_0.price, a_lightsaber_2.price
    assert_not_equal a_lightsaber_1.price, a_lightsaber_2.price
    assert_equal a_lightsaber.display_price[0], a_lightsaber.variations.min {|a,b| a.price <=> b.price }.price
    assert_equal a_lightsaber.display_price[1], a_lightsaber.variations.max {|a,b| a.price <=> b.price }.price
    # Test with equal prices.
    a_lightsaber_0.price = 10.00
    assert a_lightsaber_0.save
    a_lightsaber_1.price = 10.00
    assert a_lightsaber_1.save
    a_lightsaber_2.price = 10.00
    assert a_lightsaber_2.save
    assert_equal a_lightsaber.display_price, a_lightsaber.variations.min {|a,b| a.price <=> b.price }.price
  end


  # Test if products can be associated with tags.
  def test_should_associate_tags
    # Load some products and see if they really don't have any tags.
    a_stuff = items(:the_stuff)
    assert_equal a_stuff.tags.count, 0
    # Load some tags and see if they really don't have any products.
    weird_tag = tags(:weird)
    weird_counter = weird_tag.products.count
    # Associate one with the other and both must know about that.
    a_stuff.tags << weird_tag
    assert_equal a_stuff.tags.count, 1
    assert_equal weird_tag.products.count, weird_counter + 1

    # Break the association.
    a_stuff.tags.delete(weird_tag)
    assert_equal a_stuff.tags.count, 0
    assert_equal weird_tag.products.count, weird_counter
  end


  def test_should_search
    # It should find products.
    assert_equal [items(:lightsaber)], Product.search("LIGHTSABER")
    # It should NOT find variations.
    assert_equal [], Product.search("Red")
    # Find in description.
    assert_equal [items(:uranium_portion)], Product.search("nuke you always wanted")
    # Find in name.
    assert_equal [items(:uranium_portion)], Product.search("Enriched")
    # Find in name. It should NOT be case sensitive.
    assert_equal [items(:uranium_portion)], Product.search("enriched")
  end


  # Find products that are associated with tags.
  def test_should_find_by_tags
    # One tag.
    assert_same_elements items(:uranium_portion, :holy_grenade, :lightsaber, :towel), Product.find_by_tags([tags(:weapons).id])
    # One tag and one subtag.
    assert_equal [items(:uranium_portion)], Product.find_by_tags([tags(:weapons).id,tags(:mass_destruction).id])
    # One subtag.
    assert_equal [items(:uranium_portion)], Product.find_by_tags([tags(:mass_destruction).id])
    # One tag and one empty tag.
    assert_equal [], Product.find_by_tags([tags(:weapons).id,tags(:books).id])
  end


  # Show if the product is new or on sale.
  def test_is_on_sale
    p = items(:towel)
    assert_kind_of Tag, p.tags.find_by_name('On Sale')
    assert(
      p.is_on_sale?, 
      "Product was not on sale when it should have been"
    )
    
    p.tags.destroy_all
    assert(
      !p.reload.is_on_sale?, 
      "Without the sale tag it shouldn't have been marked on sale"
    )
  end
    
  def test_is_new
    p = items(:lightsaber)

    assert Preference.save_settings({
      "product_is_new_week_range" => 2
    })

    p.date_available = Date.today
    assert p.is_new?
    
    p.date_available = Date.today - (2.weeks + 1.day)
    assert !p.is_new?
    
    assert Preference.save_settings({
      "product_is_new_week_range" => 3
    })
    assert p.is_new?
  end
  
  # Ensure nothing is thrown if the pref doesn't exist.
  def test_is_new_no_date_preference
    p = items(:lightsaber)
    Preference.destroy_all("name = 'product_is_new_week_range'")
    assert p.is_new?
  end
  
  def test_is_out_of_stock
    p = items(:lightsaber)
    p.expects(:quantity).times(3).returns(1, 0, -1)
    
    assert p.in_stock?
    assert !p.in_stock?
    assert !p.in_stock?
  end
  
  def test_is_published
    p = items(:lightsaber)
    
    assert p.is_published?
    
    p.date_available = Date.today + 1.week
    assert !p.is_published?
    
    p.date_available = Date.today
    p.is_discontinued = true
    assert !p.is_published?
    
    p.is_discontinued = false
    assert p.is_published?
  end

  def test_clean_code
    p = Product.new(
      :name => 'My new product',
      :price => 20
    )
    assert p.save!
    assert_equal 'MY-NEW-PRODUCT', p.code
  end
  
  def test_doesnt_replace_existing_code
    p = Product.new(
      :name => 'My new product',
      :code => 'spaces will be replaced',
      :price => 20
    )
    assert p.save!
    assert_equal 'SPACES-WILL-BE-REPLACED', p.code
  end
  
  def test_clean_code_handles_numbers
    p = Product.new(
      :name => 'Hat 7-1/8',
      :price => 20
    )
    assert p.save!
    assert_equal 'HAT-7-1-8', p.code
  end

end

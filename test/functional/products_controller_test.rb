$: << '.' if RUBY_VERSION >= '1.9.0'
require File.dirname(__FILE__) + '/../test_helper'

class Admin::ProductsControllerTest < ActionController::TestCase


  def test_can_upload_with_mp3_link
    a_product = can_upload_with_mp3_link :download_mp3_url => 'http://freemusicformormons.com/examples_for_unit_testing/sound.mp3'
    
    assert_not_nil a_product
    assert_equal a_product.images.count, 1
    assert_equal a_product.downloads.count, 1
    
    download = a_product.downloads[0]
    assert download.size == 36429 # should be 30K'ish...
    assert download.name == 'sound.mp3'
  end


  # these tests take forever...
  def test_can_upload_with_pdf_link
    a_product = can_upload_with_mp3_link :download_pdf_url => 'http://freemusicformormons.com/examples_for_unit_testing/17.pdf'
    assert_equal 5, a_product.images.count # 4 pages + 1 image
    assert_equal 1, a_product.downloads.count # 1 pdf
    image = a_product.images[0]
    assert image.size > 0
  end
  
  def test_can_upload_with_both_pdf_and_mp3_link
    a_product = can_upload_with_mp3_link :download_pdf_url => 'http://freemusicformormons.com/examples_for_unit_testing/17.pdf', 
      :download_mp3_url => 'http://freemusicformormons.com/examples_for_unit_testing/sound.mp3'
    assert_equal 5, a_product.images.count # 4 pages + 1 image
    assert_equal 2, a_product.downloads.count # 1 pdf + 1 mp3
    download = a_product.downloads[0]
    assert download.name == 'sound.mp3'
    assert_equal 36429, download.size
  end

  def test_if_has_hymn_tag_auto_propagates
   raise 'unimplemented'
  end

  def test_if_has_some_tags_no_hymn_tag_does_not_save
   raise 'unimplemented'
  end

private
  
  def can_upload_with_mp3_link incoming
    Product.destroy_all
    Admin::ProductsController.density=10
    login_as_admin

    # In turn of an image, try to upload a text file in its place.
    text_asset = fixture_file_upload("/files/towel.jpg", 'image/jpeg')

    # Call the new form.
    get :new
    assert_response :success
    assert_template 'new'
    
    # Post to it a product and an empty image.
    post :save, {
    :product => {
      :code => "SHRUBBERY",
      :name => "Shrubbery",
      :description => "A shrubbery. One that looks nice, and is not too expensive. Perfect for a knight who say Ni.",
      :price => 90.50,
      :date_available => "2007-12-01 00:00",
      :quantity => 38,
      :size_width => 24,
      :size_height => 24,
      :size_depth => 12,
      :weight => 21.52,
      :related_product_suggestion_names => ["", "", "", "", ""],
      :tag_ids => [""]
    },
    :image => [ {
      :image_data_temp => "",
      :image_data => text_asset
      }, {
      :image_data_temp => "",
      :image_data => ""
    } ],
    :download => []}.merge(incoming)
    
    # If saved we should be redirected to edit form. 
    assert_response :redirect
    assert_redirected_to :action => :edit, :id => assigns(:product).id
    
    # Verify that the product really is there and it doesn't have images.
    a_product = Product.find_by_code('SHRUBBERY')
    
    # The signal that the image has problems is a flash message
    assert !flash[:notice].blank?
    a_product
  end
  
end

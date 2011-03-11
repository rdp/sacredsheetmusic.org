$: << '.' if RUBY_VERSION >= '1.9.0'
require File.dirname(__FILE__) + '/../test_helper'

class Admin::ProductsControllerTest < ActionController::TestCase


  def test_can_upload_with_mp3_link
    can_upload_with_mp3_link  :download_mp3 => 'http://freemusicformormons.com/sounds/sound.mp3'
  end

  def test_can_upload_with_mp3_link
    can_upload_with_mp3_link  :download_pdf => 'http://freemusicformormons.com/sounds/sound.mp3'
  end


  private
  
  def can_upload_with_mp3_link incoming
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
    assert_not_nil a_product 
    assert_equal a_product.images.count, 1
    assert_equal a_product.downloads.count, 1
    
    download = a_product.downloads[0]
    assert download.size > 1000 # should be 30K'ish...
    assert download.name == 'sound.mp3'
    
    # The signal that the image has problems is a flash message
    assert !flash[:notice].blank?
  end
  
end
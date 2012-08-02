require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class BuyerTest < ActionController::IntegrationTest
  fixtures :all
  
  def setup
    @santa_address = OrderAddress.find(order_addresses(:santa_address).id)
  end
  
  def test_buy_something_authorize
    # Set store to use authorize.net
    Preference.save_setting('cc_processor' => Preference::CC_PROCESSORS[0])
    Order.any_instance.expects(:run_transaction_authorize).once.returns(true)
    assert_checkout_process_works
    assert_download_available
    assert_finished_order_has_item(items(:towel), 2)
  end
  
  def test_buy_something_paypal
    # Set store to use paypal ipn
    Preference.save_setting('cc_processor' => Preference::CC_PROCESSORS[1])
    Order.any_instance.expects(:run_transaction_paypal_ipn).once.returns(true)
    assert_checkout_process_works
    assert_download_available
    assert_finished_order_has_item(items(:towel), 2)
  end
  
  # This simulates the process where a buyer places an order, but
  # PayPal's IPN process updates the order before they're redirected to the
  # receipt (finish_order) screen.
  #
  # Was running into issues where the cart gets invalidated in
  # our before_filter when "sanitize!" is called, and the customer is redirected
  # back to the store with an error message.
  def test_buy_something_paypal_ipn
    # Setup
    Preference.save_setting('cc_processor' => Preference::CC_PROCESSORS[1])
    assert Preference.save_settings({ "store_show_confirmation" => "1" })
    
    # Exercise
    assert_log_customer_in
    assert_add_product_to_cart(items(:towel))
    assert_get_checkout
    assert_post_valid_order
    assert_checkout_shows_shipping_method
    assert_set_shipping_method
    assert_confirms_order_from_shipping

    # Mock paypal notification based on our order
    last_order = Order.last
    n = mock()
    n.stubs(:invoice).returns(last_order.order_number)
    n.stubs(:acknowledge).returns(true)
    n.stubs(:complete?).returns(true)
    ActiveMerchant::Billing::Integrations::Paypal::Notification.expects(
      :new).returns(n)
    Order.any_instance.expects(:matches_ipn?).returns(true)

    # Simulate paypal ipn calling back the server
    assert_not_equal 5, last_order.reload.order_status_code_id
    post '/paypal/ipn'
    assert_response :success
    assert_equal 5, last_order.reload.order_status_code_id
    
    # Now try to get the receipt screen
    assert_finish_order
    assert_finished_order_has_item(items(:towel))
    
    # Now go back to store and ensure order is intact,
    # and that accessing anything but finish_order initializes
    # a new cart.
    get '/store'
    assert_response :success
    assert_finished_order_has_item(items(:towel))
    assert assigns(:order).new_record?
  end
    
  def test_cart_and_order_in_sync
    Order.delete_all
    
    # Add two different products to the cart.
    @cart = nil
    [:holy_grenade, :uranium_portion].each do |sym|
      post '/store/add_to_cart_ajax', :id => items(sym).id
      assert_response :redirect
      @cart = assigns(:order)
    end
    assert_equal @cart.items.length, 2
    
    # Checkout & go to shipping page
    assert_post_valid_order

    order = assigns(:order)    

    # Delete one item from the cart
    xml_http_request(:post, '/store/remove_from_cart_ajax', :id => items(:holy_grenade).id)
    assert_response :success
    
    # ...It should update the order object.
    order = Order.find(:first)
    assert_equal order.order_line_items.count, 1, "Order items not updated after one was deleted from the cart."    
  end
  
  def test_cart_only_written_to_db_when_product_added
    lightsaber = items(:lightsaber)
    
    assert_no_difference "Order.count" do
      get "/store"
      assert_response :success
      
      get "/store/show", :id => lightsaber.code
      assert_response :success
      
      assert_equal assigns(:product), lightsaber
      assert assigns(:order).new_record?
    end
    
    # Add to cart action saves order to database
    assert_difference "Order.count" do
      xhr :post, '/store/add_to_cart', :id => lightsaber.id
      assert_response :success
      
      assert !assigns(:order).new_record?
    end
  end

  private
    def assert_checkout_process_works
      # Ensure the show confirmation page is shown
      assert Preference.save_settings({ "store_show_confirmation" => "1" })
      towel = items(:towel)

      assert_log_customer_in
      assert_add_product_to_cart(towel)
      assert_equal @cart.items.length, 1

      assert_get_checkout
      assert_equal(
        @cart.items.first.quantity, 1, 
        "UNEXPECTED FIRST CART ITEM QUANTITY"
      )

      assert_post_valid_order
      assert_equal(
        @cart.items.first.quantity, 1, 
        "UNEXPECTED FIRST ORDER ITEM QUANTITY AFTER CHECKOUT"
      )

      assert_checkout_shows_shipping_method

      assert_set_shipping_method
      assert_equal(
        @cart.items.first.quantity, 1, 
        "UNEXPECTED FIRST ORDER ITEM QUANTITY AFTER SHIPPING"
      )

      assert_confirms_order_from_shipping

      # SECOND INTERACTION
      # Add same item to the cart, making quantity 2
      assert_add_product_to_cart(towel)
      assert_equal @cart.items.length, 1
      assert_equal(
        @cart.items.first.quantity, 2, 
        "UNEXPECTED SECOND CART ITEM QUANTITY"
      )

      assert_get_checkout
      assert_post_valid_order
      assert_equal(
        @cart.items.first.quantity, 2, 
        "UNEXPECTED SECOND CART ITEM QUANTITY AFTER CHECKOUT"
      )

      assert_checkout_shows_shipping_method

      assert_set_shipping_method
      assert_confirms_order_from_shipping

      # Purchase
      assert_finish_order
    end
  
    def assert_log_customer_in
      # LOGIN TO THE SYSTEM
      a_customer = order_users(:santa)

      get 'customers/login'
      assert_response :success
      assert_equal assigns(:title), "Customer Login"
      assert_template 'login'

      post 'customers/login', :modal => "", 
        :login => "santa.claus@whoknowswhere.com", 
        :password => "santa"
      assert_redirected_to :action => :orders

      # We need to follow the redirect.
      follow_redirect!
      assert_select "p", :text => /Login successful/

      # Ensure customer id is in the session.
      assert_equal session[:customer], a_customer.id
    end
    
    def assert_add_product_to_cart(product)  
      # ADD 1 PRODUCT TO THE CART
      post 'store/add_to_cart_ajax', :id => product.id
      # Here nothing is rendered directly, 
      # but a SUBMODAL.show() javascript function is executed.
      @cart = assigns(:order)
      # Products get added as OrderLineItems, not 'products'
      has_product_in_cart = false
      @cart.items.each do |oli|
        if oli.item == product
          has_product_in_cart = true
          break
        end
      end
      assert has_product_in_cart, @cart.items.inspect
    end
    
    def assert_get_checkout
      get 'store/checkout'
      assert_response :success
      assert_template 'checkout'
      assert_equal assigns(:title), "Please enter your information to continue this purchase."
      assert_not_nil assigns(:cc_processor)

      @cart = assigns(:order)
    end
    
    def assert_set_shipping_method
      post(
        'store/set_shipping_method', 
        :ship_type_id => order_shipping_types(:ups_ground).id
      )
      assert_redirected_to :action => :confirm_order
      @cart = assigns(:order)
    end
  
    # Posts good order information
    def assert_post_valid_order
      post(
        'store/checkout',
        :order_account => {
          :cc_number => "4007000000027",
          :expiration_year => 4.years.from_now.year,
          :expiration_month => "1"
        },
        :shipping_address => @santa_address.attributes,
        :billing_address => @santa_address.attributes,
        :order_user => {
          :email_address => "uncle.scrooge@whoknowswhere.com"
        },
        :use_separate_shipping_address => "false"
      )
      assert_response :redirect
      assert_redirected_to :action => :select_shipping_method
      @cart = assigns(:order)
    end
    
    def assert_checkout_shows_shipping_method
      follow_redirect! # from posting checkout
      assert_response :success
      assert_template 'select_shipping_method'
      assert_equal assigns(:title), "Select Your Shipping Method - Step 2 of 3"
      assert_not_nil assigns(:default_price)
    end
    
    def assert_confirms_order_from_shipping
      follow_redirect! # from setting shipping method
      assert_template 'confirm_order'
      assert_equal assigns(:title), "Please confirm your order. - Step 3 of 3"
    end
    
    def assert_finish_order
      post 'store/finish_order'
      assert_response :success
      assert_template 'finish_order'
      assert_layout 'receipt'
      assert_select "p", :text => /processed successfully/
    end
    
    def assert_finished_order_has_item(item, quantity=1)
      has_product_in_order = false
      last_order = Order.last
      last_order.items.each do |oli|
        if oli.item == item && quantity == oli.quantity
          has_product_in_order = true
          break
        end
      end
      assert has_product_in_order, last_order.inspect
    end
    
    def assert_download_available
      # Ensure download available to customer
      assert_select "h2", :text => /Product Downloads/
      url_for_download = url_for(
        :controller => 'customers',
        :action => 'download_for_order',
        :params => {
          :order_number => assigns(:order).order_number,
          :download_id => assigns(:order).downloads.first.id
        },
        :only_path => true
      )
      assert_tag :tag => "a", 
        :attributes => { 
          :href => ERB::Util::html_escape(url_for_download)
        }

      # Download file
      get url_for_download
      assert_response :success, "File wasn't downloaded after purchase."
    end

end

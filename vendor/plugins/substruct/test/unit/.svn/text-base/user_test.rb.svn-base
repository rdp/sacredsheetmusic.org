require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class UserTest < ActiveSupport::TestCase
  fixtures :users


  # Test if a valid user can be created with success.
  def test_should_create_user
    @user = User.new(
      :login => "root",
      :password => "password",
      :password_confirmation => "password"
    )
  
    assert @user.save
  end


  # Test if a user can be found with success.
  def test_should_find_user
    @user_id = users(:admin).id
    assert_nothing_raised {
      User.find(@user_id)
    }
  end


  # Test if an user can be updated with success.
  def test_should_update_user
    @user = users(:admin)
    
    @user.login = 'administrator'
    @user.password = ""
    @user.password_confirmation = ""
    
    assert @user.save
  end


  # Test if an user password can be updated with success.
  def test_should_update_user
    @user = users(:admin)
    
    @user.password = "another_password"
    @user.password_confirmation = "another_password"
    
    assert @user.save
  end
  
  
  # Test if a user can be destroyed with success.
  def test_should_destroy_user
    @user = users(:admin)
    @user.destroy
    assert_raise(ActiveRecord::RecordNotFound) {
      User.find(@user.id)
    }
  end


  # Test if an invalid user really will NOT be created.
  def test_valid_login_length
    @user = User.new(
      :login => "",
      :password => "",
      :password_confirmation => ""
    )
    
    # A user must have a login, and it must be long enough.
    assert !@user.valid?
    assert @user.errors.invalid?(:login)
    assert_error_on :login, @user

    # A user must have a not so long login.
    @user.login = "my_very_very_very_very_very_very_long_login"
    assert !@user.valid?
    assert_error_on :login, @user
  end
  
  
  def test_unique_login
    @user = User.new(
      :login => users(:admin).login,
      :password => "",
      :password_confirmation => ""
    )
    assert !@user.valid?
    assert_error_on :login, @user
  end

  def test_password_length
    @user = User.new(
      :login => "unique_login",
      :password => "",
      :password_confirmation => ""
    )
    assert !@user.valid?
    assert_error_on :password, @user

    too_long_pass = "my_very_very_very_very_very_long_password"
    @user.password = too_long_pass
    @user.password_confirmation = too_long_pass
    assert_error_on :password, @user
  end
  
  def test_password_and_confirmation_match
    @user = User.new(
      :login => "unique_login",
      :password => "passwords",
      :password_confirmation => "dontmatch"
    )
    # A user must have a password confirmation that matches the password.
    assert !@user.valid?
    assert @user.errors.invalid?(:password)
    assert_equal " and confirmation don't match.", @user.errors.on(:password)
    
    @user.password_confirmation = "passwords"
    assert @user.save
  end


  # Test if a user can be authenticated.
  def test_should_authenticate_user
    @user = users(:admin)
    
    assert_equal @user, User.authenticate("admin", "admin")
    assert User.authenticate?("admin", "admin")
  end
  
  
  # Test if a user will be authenticated.
  def test_should_authenticate_user
    assert_equal User.find_by_login("admin"), User.authenticate("admin", "admin")
    assert User.authenticate?("admin", "admin")
  end
  
  
  # Test if a user with a wrong password will NOT be authenticated.
  def test_should_not_authenticate_user
    assert_equal nil, User.authenticate("admin", "wrongpassword")
    assert !User.authenticate?("admin", "wrongpassword")
  end
  
  
end
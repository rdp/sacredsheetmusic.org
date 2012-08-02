class OrdersMailer < ActionMailer::Base
  helper :application
  
  def inquiry(addy_from, email_text)
    setup_defaults
    
    subject      "Inquiry from the site"
    body         :from => addy_from, :email_text => email_text
    recipients   Preference.get_value('mail_copy_to').split(',')
    from         addy_from
  end

  def receipt(order, email_text)
    setup_defaults

    recipients   order.order_user.email_address    
    subject      "Thank you for your order! (\##{order.order_number})"
    content_type "multipart/alternative"

    @body = { :order => order, :email_text => email_text }

    part "text/plain" do |p|
      p.body = render_message(
        "receipt.text.plain", 
        @body
      )
      p.transfer_encoding = "base64"
    end
    part "text/html" do |p|
      p.body = render_inline_css(
        "receipt.text.html", 
        @body
      )
    end
  end

  def failed(order)
    setup_defaults
    
    recipients   Preference.get_value('mail_copy_to').split(',')
    subject      "An order has failed on the site"
    body         :order => order
  end

  def reset_password(customer)
    setup_defaults
    
    recipients   customer.email_address
    subject      "Password reset for #{Preference.get_value('store_name')}"
    body         :customer => customer
  end

  def testing(array_email_addresses)
    setup_defaults
    
    subject      "Test from #{Preference.get_value('store_name')}"
    recipients   array_email_addresses
  end
  
  private
    def setup_defaults
      @bcc        = Preference.get_value('mail_copy_to').split(',')
      @from       = Preference.get_value('mail_username')
      @sent_on    = Time.now
      @headers    = {}
    end

  protected

    def render_inline_css(template, params)
      Premailer.new(
        render_message(template, params), 
        :in_memory => true
      ).to_inline_css
    end
  
end

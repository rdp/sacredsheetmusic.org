require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/orders_mailer"
class OrdersMailer
  
  def inquiry(addy_from, email_text)
    setup_defaults
    subject      "Thanks for song"
    body         :from => addy_from, :email_text => email_text
    recipients   Preference.get_value('mail_copy_to').split(',')
    from         addy_from
  end

end

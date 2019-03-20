require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/orders_mailer"

class OrdersMailer
 
  def composer_stats composer_object
    email_addy_from=Preference.get_value('mail_username')
    setup_defaults
#    @bcc = nil # uncomment if I don't want extra copies to me...
    subject "freeldssheetmusic.org composer individual song stats"
    # renders a .rhtml file...
    body         :composer => composer_object
    recipients   composer_object.composer_email_if_contacted
    from         email_addy_from
  end

  def spam_composer composer_object
    email_addy_from=Preference.get_value('mail_username')
    setup_defaults
#    @bcc = nil # uncomment if I don't want extra copies to me...leave commented to *yes receive* extra copies...
    # hard to believe subject isn't with the .rhtml file...
    subject "Your yearly freeldssheetmusic.org stats, and a #{Time.now.year} competition announcement"

    # renders a .rhtml file...
    body         :composer => composer_object
    recipients   composer_object.composer_email_if_contacted
    from         email_addy_from
  end

  def setup_defaults
    @bcc        = Preference.get_value('mail_copy_to').split(',')
    @from       = Preference.get_value('mail_username')
    @sent_on    = Time.now
    @headers    = {}
  end

  # called like... deliver_inquiry(...)...I guess... 
  # email_addy_from is "their submitted form email addy" for questions...
  def inquiry(subjectt, email_text, email_addy_from, extra_email_to=nil, send_copy_to_me = true)
    setup_defaults
    @email_addy_from = email_addy_from
    if !send_copy_to_me
      @bcc = nil
    end
    subject(subjectt)
    # renders a .rhtml file...
    body :from => email_addy_from, :email_text => email_text
    if extra_email_to.present?
      recipients [extra_email_to] # send it typically "to them" instead of just bcc'ing it "to me"
    end
    from email_addy_from # gmail doesn't care what you say here anyway iirc...
  end

end

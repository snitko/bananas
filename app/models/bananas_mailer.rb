class BananasMailer < ActionMailer::Base
  
  def new_report(report, emails)
    subject       "New Bananas Report"
    from          "bananas@#{default_url_options[:host]}"
    recipients    emails
    sent_on       Time.now
    body          :report => report
  end

end

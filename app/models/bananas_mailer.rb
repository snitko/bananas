class BananasMailer < ActionMailer::Base
  
  def new_report(report, emails)
    subject       "New Bananas Report"
    recipients    emails
    sent_on       Time.now
    body          :report => report
  end

end

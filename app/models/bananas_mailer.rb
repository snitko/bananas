class BananasMailer < ActionMailer::Base
  
  default :from => "bananas@#{default_url_options[:host]}"

  def new_report(report, emails)
    @report = report
    mail :to => emails,
         :subject => "New Bananas Report"
  end

end

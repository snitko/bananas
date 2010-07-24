require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class ApplicationController < ActionController::Base
  include Bananas
  bananas "SpamReport"
end

class SomeController < ApplicationController
  def action_that_checks_reports
    check_spam_report
  end
  def action_that_casts_reports
    u = BananasUser.create(:login => "user", :bananas_attempts => 10)
    cast_spam_report(u.id)
  end
end

describe SomeController, :type => :controller do

  before(:each) do
    request.env['REMOTE_ADDR'] = "127.0.0.1"
  end

  describe "bananas report checks" do
    
    after(:each) do
      SpamReport.find(:all).each { |r| r.destroy }
    end
    
    it "renders 403 page if the report exists" do
      SpamReport.create(:ip_address => "127.0.0.1")
      get :action_that_checks_reports
      response.should render_403
    end

    it "renders whatever the controller wants to if report does not exist" do
      get :action_that_checks_reports
      response.should render_template("action_that_checks_reports")
    end

  end

  it "casts a new banana report" do
    get :action_that_casts_reports
    report = SpamReport.find_by_ip_address("127.0.0.1")
    report.should_not be_nil
    report.destroy #cleaning up
  end

end
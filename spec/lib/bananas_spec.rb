require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class SomeController < ApplicationController
  include Bananas
  bananas :my_spam_report

  def action_that_checks_reports
    check_my_spam_report
  end

  def action_that_casts_reports
    u = BananasUser.create(:login => "user", :bananas_attempts => [30.seconds.ago]*11)
    cast_my_spam_report(u.id)
  end

end

describe SomeController, :type => :controller do

  after(:all) do
    `rm -rf #{File.dirname(__FILE__)}/../../app/views/some`
  end
  
  # We need this line because, apprently, rspec2 ignores the :type option
  include RSpec::Rails::ControllerExampleGroup

  before(:all) do
    views_path = "#{File.dirname(__FILE__)}/../../app/views/some"
    `mkdir #{views_path}`
    `touch #{views_path}/action_that_casts_reports.html.erb`
    `touch #{views_path}/action_that_checks_reports.html.erb`
    `touch #{views_path}/check_another_spam_report.html.erb`
    `touch #{views_path}/cast_another_spam_report.html.erb`
  end
  

  before(:each) do
    request.env['REMOTE_ADDR'] = "127.0.0.1"
  end

  describe "bananas report checks" do

    after(:each) do
      MySpamReport.find(:all).each { |r| r.destroy }
    end

    it "renders 403 page if the report exists" do
      MySpamReport.create(:ip_address => "127.0.0.1")
      get :action_that_checks_reports
    end

    it "renders whatever the controller wants to if report does not exist" do
      get :action_that_checks_reports
      response.should render_template("action_that_checks_reports")
    end

  end

  it "casts a new banana report" do
    get :action_that_casts_reports
    report = MySpamReport.find_by_ip_address("127.0.0.1")
    report.should_not be_nil
    report.destroy #cleaning up
  end

end

class AnotherController < ApplicationController
  include Bananas
  bananas :another_spam_report

  def action_that_checks_reports
    check_another_spam_report
  end

  def action_that_casts_reports
    u = AnotherUser.create(:login => "user")
    CustomCacheStore.write("bananas/attempts/127.0.0.1", [30.seconds.ago]*11)
    cast_another_spam_report(u.id)
  end

end

describe AnotherController, :type => :controller do

  after(:all) do
    `rm -rf #{File.dirname(__FILE__)}/../../app/views/another`
  end

  # We need this line because, apprently, rspec2 ignores the :type option
  include RSpec::Rails::ControllerExampleGroup

  before(:all) do
    views_path = "#{File.dirname(__FILE__)}/../../app/views/another"
    `mkdir #{views_path}`
    `touch #{views_path}/action_that_checks_reports.html.erb`
    `touch #{views_path}/check_another_spam_report.html.erb`
    `touch #{views_path}/cast_another_spam_report.html.erb`
    `touch #{views_path}/action_that_casts_reports.html.erb`
    `touch #{views_path}/another_action_that_casts_reports.html.erb`
  end

  before(:each) do
    request.env['REMOTE_ADDR'] = "127.0.0.1"
  end

  describe "bananas report checks" do

    after(:each) do
      AnotherSpamReport.find(:all).each { |r| r.destroy }
    end

    it "renders 403 page if the report exists" do
      AnotherSpamReport.create(:ip_address => "127.0.0.1")
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
    report = AnotherSpamReport.find_by_ip_address("127.0.0.1")
    report.should_not be_nil
    report.destroy #cleaning up
  end

end


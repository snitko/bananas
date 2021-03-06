require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class ApplicationController < ActionController::Base
end

class MySpamReportsController < ApplicationController
  include Bananas::ReportsController
  access           :login => "login", :password => "password"
  report_class :my_spam_report
end

describe MySpamReportsController, :type => :controller do

  # We need this line because, apprently, rspec2 ignores the :type option
  include RSpec::Rails::ControllerExampleGroup

  before(:all) do
    views_path = "#{File.dirname(__FILE__)}/../../app/views/my_spam_reports"
    `mkdir #{views_path}`
    `touch #{views_path}/show.html.erb`
  end

  after(:all) do
    `rm -rf #{File.dirname(__FILE__)}/../../app/views/my_spam_reports`
  end

  describe "index action" do

    it "shows reports if the user is authorized" do
      get 'index', :access => { :login => "login", :password => "password" }
      response.should render_template("index")
      assigns(:reports).should_not be_nil
    end
    it "renders new session form if the user is not authorized to access bananas manager" do
      get 'index'
      response.should render_template("bananas_reports/new_session")
    end

  end

  describe "show action" do

    before(:each) do
      session[:bananas_manager_access] = Digest::MD5.hexdigest("loginpassword")
    end

    it "finds report by ip_address and renders report page" do
      MySpamReport.create(:ip_address => "127.0.0.1")
      get "show", :id => "127.0.0.1"
      response.should render_template("show")
    end
    it "renders 404 page if the report with this ip_address was not found" do
      get "show", :id => "0.0.0.0"
      response.should render_404
    end
  end

  describe "delete action" do

    it "deletes the report if the user is authorized" do
      report = MySpamReport.create(:ip_address => "127.0.0.1")
      delete "destroy", :id => report.id, :access => { :login => "login", :password => "password" }
      flash[:success].should_not be_nil
      response.should redirect_to(:action => "index")
    end

  end

end

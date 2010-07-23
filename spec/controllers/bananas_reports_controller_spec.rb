require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require "bananas_reports_controller"

class ApplicationController < ActionController::Base
end

class SpamReportsController < BananasReportsController
  access           :login => "login", :password => "password"
  set_report_class "BananasReport"
end

describe SpamReportsController do


  describe "index action" do

    it "shows paginated reports if the user is authorized" do
      get 'index', :access => { :login => "login", :password => "password" }
      response.should render_template("index")
      assigns(:reports).should_not be_nil
    end
    it "renders new session form if the user is not authorized to access bananas manager" do
      get 'index'
      response.should render_template("new_session")
    end

  end

  describe "show action" do

    before(:each) do
      session[:bananas_manager_access] = Digest::MD5.hexdigest("loginpassword")
    end

    it "finds report by ip_address and renders report page" do
      BananasReport.create(:ip_address => "127.0.0.1")
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
      report = BananasReport.create(:ip_address => "127.0.0.1")
      delete "destroy", :id => report.id, :access => { :login => "login", :password => "password" }
      flash[:success].should_not be_nil
      response.should redirect_to(:action => "index")
    end

  end

end

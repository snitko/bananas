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
    it "renders 403 if user is not allowed to access the manager" do
      get 'index'
      response.should render_403
    end

  end

  describe "show action" do
    it "finds report by ip_address and renders report page" do
      BananasReport.create(:ip_address => "127.0.0.1")
      get "show", :id => "127.0.0.1", :access => { :login => "login", :password => "password" }
      response.should render_template("show")
    end
    it "renders 404 page of the report was not found by ip_address" do
      get "show", :id => "0.0.0.0", :access => { :login => "login", :password => "password" }
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

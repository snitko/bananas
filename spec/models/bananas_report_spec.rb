require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class BananasUser < ActiveRecord::Base; end
BananasReport.belongs_to_abuser :bananas_user
BananasReport.admin_emails      ["admin@bananas"]

describe BananasReport do

  before(:each) do
    BananasReport.find(:all).each { |r| r.destroy }
    BananasUser.find(:all).each   { |u| u.destroy }
    @abuser = BananasUser.create(:bananas_attempts => 11)
  end

  it "creates a new record if the report conditions are true" do
    BananasReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).id.should_not be_nil
  end

  it "does not create a new record if the report conditions are false" do
    abuser = BananasUser.create(:bananas_attempts => 9)
    BananasReport.cast(:ip_address => "127.0.0.1", :abuser_id => abuser.id).id.should be_nil
  end

  it "sends an email to admin when a new report is added" do
    BananasMailer.should_receive(:deliver_new_report).once
    BananasReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id)
  end

  it "counts the number of times a report has been added for the same ip" do
    BananasReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).counter.should be(1)
    BananasReport.cast(:ip_address => "127.0.0.1").counter.should be(2)
  end
  
  it "updates abuser's bananas_attempts" do
    BananasReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).counter.should
    @abuser.reload.bananas_attempts.should be(0)
    BananasReport.cast(:ip_address => "127.0.0.1")
    @abuser.reload.bananas_attempts.should be(1)
  end

end

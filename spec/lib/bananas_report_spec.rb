require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SpamReport do

  before(:each) do
    SpamReport.find(:all).each { |r| r.destroy }
    BananasUser.find(:all).each   { |u| u.destroy }
    bananas_attempts = []
    11.times { bananas_attempts << 30.seconds.ago }
    @abuser = BananasUser.create(:bananas_attempts => bananas_attempts)
  end

  it "creates a new record if the report conditions are true" do
    SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).id.should_not be_nil
  end

  it "does not create a new record if the report conditions are false" do
    abuser = BananasUser.create(:bananas_attempts => [30.seconds.ago, 50.seconds.ago])
    SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => abuser.id).id.should be_nil
  end

  it "sends an email to admin when a new report is added" do
    BananasMailer.should_receive(:deliver_new_report).once
    SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id)
  end

  it "counts the number of times a report has been added for the same ip" do
    SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).counter.should be(1)
    SpamReport.cast(:ip_address => "127.0.0.1").counter.should be(2)
  end
  
  it "updates abuser's bananas_attempts" do
    SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).counter.should
    @abuser.reload.bananas_attempts.size.should be(0)
    SpamReport.cast(:ip_address => "127.0.0.1")
    @abuser.reload.bananas_attempts.size.should be(1)
  end

end

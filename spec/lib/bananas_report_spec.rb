require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

shared_examples_for("spam_report") do

  it "creates a new record if the report conditions are true" do
    @_SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).id.should_not be_nil
  end


  it "sends an email to admin when a new report is added" do
    allow_message_expectations_on_nil
    BananasMailer.stub!(:new_report)
    BananasMailer.new_report.should_receive(:deliver).once
    @_SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id)
  end

  it "counts the number of times a report has been added for the same ip" do
    @_SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id)
    11.times { @_SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id) }
    @_SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).counter.should be(2)
  end

end

describe MySpamReport do

  before(:all) do
    @_User = BananasUser
    @_SpamReport = MySpamReport
  end

  before(:each) do
    MySpamReport.find(:all).each { |r| r.destroy }
    BananasUser.find(:all).each { |u| u.destroy }
    @abuser = BananasUser.create(:bananas_attempts => [30.seconds.ago]*11)
  end

  it_should_behave_like "spam_report"

  it "updates abuser's bananas_attempts" do
    11.times { MySpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id) }
    @abuser.reload.bananas_attempts.size.should be(10)
  end

  it "does not create a new record if the report conditions are false" do
    abuser = @_User.create(:bananas_attempts => [30.seconds.ago, 50.seconds.ago])
    @_SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => abuser.id).id.should be_nil
  end

end

describe AnotherSpamReport, "with cache storage" do

  before(:all) do
    @_User = AnotherUser
    @_SpamReport = AnotherSpamReport
  end

  before(:each) do
    AnotherSpamReport.find(:all).each { |r| r.destroy }
    AnotherUser.find(:all).each { |u| u.destroy }
    @abuser = AnotherUser.create
    CustomCacheStore.write("bananas/attempts/127.0.0.1", [30.seconds.ago]*11)
  end

  it_should_behave_like "spam_report"

  it "does not create a new record if the report conditions are false" do
    CustomCacheStore.write("bananas/attempts/127.0.0.1", [30.seconds.ago])
    @_SpamReport.cast(:ip_address => "127.0.0.1").id.should be_nil
  end

end

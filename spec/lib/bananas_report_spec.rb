require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

shared_examples_for("spam_report") do

  it "creates a new record if the report conditions are true" do
    @_SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).id.should_not be_nil
  end

  it "does not create a new record if the report conditions are false" do
    abuser = @_User.create(:bananas_attempts => [30.seconds.ago, 50.seconds.ago])
    @_SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => abuser.id).id.should be_nil
  end

  it "sends an email to admin when a new report is added" do
    BananasMailer.should_receive(:deliver_new_report).once
    @_SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id)
  end

  it "counts the number of times a report has been added for the same ip" do
    @_SpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).counter.should be(1)
    @_SpamReport.cast(:ip_address => "127.0.0.1").counter.should be(2)
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
    MySpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).counter.should
    @abuser.reload.bananas_attempts.size.should be(0)
    MySpamReport.cast(:ip_address => "127.0.0.1")
    @abuser.reload.bananas_attempts.size.should be(1)
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
    CustomCacheStore.write("bananas/attempts/#{@abuser.id}", [30.seconds.ago]*11)
  end

  it_should_behave_like "spam_report"

end

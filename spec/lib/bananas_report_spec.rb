require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

shared_examples_for("spam_report") do

  it "creates a new record if the report conditions are true" do
    MySpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).id.should_not be_nil
  end

  it "does not create a new record if the report conditions are false" do
    abuser = BananasUser.create(:bananas_attempts => [30.seconds.ago, 50.seconds.ago])
    MySpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => abuser.id).id.should be_nil
  end

  it "sends an email to admin when a new report is added" do
    BananasMailer.should_receive(:deliver_new_report).once
    MySpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id)
  end

  it "counts the number of times a report has been added for the same ip" do
    MySpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).counter.should be(1)
    MySpamReport.cast(:ip_address => "127.0.0.1").counter.should be(2)
  end

end

describe MySpamReport do

  before(:all) do
    MySpamReport.send(:attempts_storage, :active_record)
  end

  before(:each) do
    MySpamReport.find(:all).each { |r| r.destroy }
    BananasUser.find(:all).each { |u| u.destroy }
    bananas_attempts = []
    11.times { bananas_attempts << 30.seconds.ago }
    @abuser = BananasUser.create(:bananas_attempts => bananas_attempts)
  end

  it_should_behave_like "spam_report"

  it "updates abuser's bananas_attempts" do
    MySpamReport.cast(:ip_address => "127.0.0.1", :abuser_id => @abuser.id).counter.should
    @abuser.reload.bananas_attempts.size.should be(0)
    MySpamReport.cast(:ip_address => "127.0.0.1")
    @abuser.reload.bananas_attempts.size.should be(1)
  end

end

describe MySpamReport, "with cache storage" do

  class CustomCacheStore

    def initialize
      @values = {}
    end

    def fetch(key)
      @values[key]
    end

    def write(key, value, *options)
      @values[key] = value
    end

  end

  before(:all) do
    @_Cache = CustomCacheStore.new
    MySpamReport.send(:attempts_storage, :cache, @_Cache)
  end

  after(:all) do
    MySpamReport.send(:attempts_storage, :active_record)
  end

  before(:each) do
    MySpamReport.find(:all).each { |r| r.destroy }
    BananasUser.find(:all).each { |u| u.destroy }
    bananas_attempts = []
    11.times { bananas_attempts << 30.seconds.ago }
    @abuser = BananasUser.create
    @_Cache.write("bananas/attempts/#{@abuser.id}", bananas_attempts)
  end

  it_should_behave_like "spam_report"

end

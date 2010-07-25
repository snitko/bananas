require File.dirname(__FILE__) + '/../init.rb'

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'spec/spec_helper.rb'))

ActionController::Routing::Routes.draw do |map|
  map.resources :my_spam_reports
end

class BananasUser < ActiveRecord::Base; end
class AnotherUser < ActiveRecord::Base; end

module CustomCacheStore

  def self.fetch(key)
    @values ||= {}
    @values[key]
  end

  def self.write(key, value, *options)
    @values ||= {}
    @values[key] = value
  end

end

class MySpamReport < ActiveRecord::Base
  include Bananas::Report
  belongs_to_abuser :bananas_user
  attempts_storage  :active_record
  admin_emails      ["admin@bananas"]
end

class AnotherSpamReport < ActiveRecord::Base
  include Bananas::Report
  belongs_to_abuser :another_user
  attempts_storage  :cache, CustomCacheStore
  admin_emails      ["admin@bananas"]
end

def load_schema
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
  ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
  db_adapter = 'sqlite3'
  ActiveRecord::Base.establish_connection(config[db_adapter])
  load(File.dirname(__FILE__) + "/schema.rb")
  require File.dirname(__FILE__) + '/../init.rb'
end

load_schema

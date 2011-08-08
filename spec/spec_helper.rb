require File.dirname(__FILE__) + '/../init.rb'
require 'sqlite3'

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'spec/spec_helper.rb'))
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}


begin
  _routes = Rails.application.routes
  _routes.disable_clear_and_finalize = true
  _routes.clear!
  Rails.application.routes_reloader.paths.each{ |path| load(path) }
  _routes.draw do
    resources :my_spam_reports
    resources :another_spam_reports
    match '/:controller(/:action(/:id))'
  end
  ActiveSupport.on_load(:action_controller) { _routes.finalize! }
ensure
  _routes.disable_clear_and_finalize = false
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

require File.dirname(__FILE__) + '/../init.rb'

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'spec/spec_helper.rb'))

ActionController::Routing::Routes.draw do |map|
  map.resources :spam_reports
end

class BananasUser < ActiveRecord::Base; end
class SpamReport < ActiveRecord::Base
  include Bananas::Report
  belongs_to_abuser :bananas_user
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

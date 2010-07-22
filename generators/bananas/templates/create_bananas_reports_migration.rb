class CreateBananasReports < ActiveRecord::Migration
  def self.up
    create_table :bananas_reports do |t|
      t.string "ip_address", :unique => true
      t.integer, :counter,   :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :bananas_reports
  end
end

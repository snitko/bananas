ActiveRecord::Schema.define(:version => 0) do

  create_table :spam_reports, :force => true do |t|
    t.string      :ip_address, :unique  => true
    t.belongs_to  :abuser
    t.integer     :counter,    :default => 0
    t.timestamps
  end

  create_table :bananas_users, :force => true do |t|
    t.string    :login
    t.string    :ip_address
    t.text      :bananas_attempts
  end

end

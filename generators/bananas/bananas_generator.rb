class BananasGenerator < Rails::Generator::Base

  def manifest

    record do |m|
      m.migration_template 'create_bananas_reports_migration.rb', "db/migrate", { :migration_file_name => "create_bananas_reports" }
    end

  end

end

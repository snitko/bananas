class BananasGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      bananas_options = {:report_model_name => args[0], :abuser_model_name => args[1] }
      if bananas_options[:report_model_name].blank?
        puts "Error: please provide report model name" 
      else
        m.migration_template 'create_bananas_reports_migration.rb.erb', "db/migrate",
          { :assigns => { :args => bananas_options }, :migration_file_name => "create_#{bananas_options[:report_model_name].pluralize}.rb" }
        m.template 'model.rb.erb',      "app/models/#{bananas_options[:report_model_name]}.rb", { :assigns => { :args => bananas_options } }
        m.template 'controller.rb.erb', "app/controllers/#{bananas_options[:report_model_name].pluralize}_controller.rb", { :assigns => { :args => bananas_options } }
      end
    end

  end

end

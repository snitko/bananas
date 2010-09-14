class BananasGenerator < Rails::Generators::Base

  source_root File.expand_path('../templates', __FILE__) 

  argument :report_model_name, :type => :string
  argument :abuser_model_name, :type => :string, :default => "user"

  def create_model
    template 'model.rb.erb', "app/models/#{report_model_name}.rb"
  end

  def create_controller
    template 'controller.rb.erb', "app/controllers/#{report_model_name.pluralize}_controller.rb"
  end

  def create_route
    route "resources :#{report_model_name.pluralize}"
  end

  def create_migration
    template 'create_bananas_reports_migration.rb.erb', "db/migrate/create_bananas_reports.rb"
  end


end

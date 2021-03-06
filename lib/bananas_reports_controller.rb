module Bananas
  module ReportsController

    def self.included(c)
      class <<c

        attr_reader :access_data

        def access(attrs)
          @access_data = attrs
        end

        def report_class(class_name)
          @report_class = const_get(class_name.to_s.camelcase) 
        end
        def get_report_class
          throw "Please set report class name" unless @report_class
          @report_class
        end

      end

      c.class_eval do
        before_filter :authorize, :set_environment
        layout nil
        # This method is called to prevent
        # "A copy of ApplicationController has been removed from the module tree but is still active!"
        # exception.
        unloadable
      end

    end




    def index
      @reports = self.class.get_report_class.find(:all, :order => "created_at DESC")
      render_template "index"
    end

    def create
      redirect_to :action => "index"
    end

    def show
      @report = self.class.get_report_class.find_by_ip_address(params[:id])
      render :file => "#{Rails.root}/public/404.html", :status => 404 unless @report
    end

    def destroy
      if report = self.class.get_report_class.find(params[:id])
        report.destroy
        flash[:success] = "Report successfully deleted."
        redirect_to :action => "index"
      end
    end

    private

      def authorized?
        authorized_by_session? or authorized_by_password?
      end

      def authorized_by_session?
        Digest::MD5.hexdigest(self.class.access_data[:login] + self.class.access_data[:password]) == session[:bananas_manager_access]
      end

      def authorized_by_password?
        if params[:access]                                              &&
        params[:access][:login]    == self.class.access_data[:login]    &&
        params[:access][:password] == self.class.access_data[:password]
          session[:bananas_manager_access] = Digest::MD5.hexdigest(params[:access][:login] + params[:access][:password])
          return true
        end
      end

      def authorize
        render :template => "bananas_reports/new_session" unless authorized?
      end

      # Renders bananas_reports default templates
      # if application's custom templates are not found.
      def render_template(template_name)
        begin
          render "#{template_name}"
        rescue(ActionView::MissingTemplate)
          render :template => "bananas_reports/#{template_name}"
        end
      end

      def set_environment
        @report_class = self.class.get_report_class.snake_name
      end

  end
end

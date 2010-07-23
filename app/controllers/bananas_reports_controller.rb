class BananasReportsController < ApplicationController

  class <<self
    attr_reader :access_data, :report_class

    def access(attrs)
      @access_data = attrs
    end

    def set_report_class(class_name)
      @report_class = const_get(class_name)    
    end

  end

  before_filter :authorize

  def index
    @reports = self.class.report_class.find(:all)
  end

  def show
    @report = self.class.report_class.find_by_ip_address(params[:id])
    render :file => "#{RAILS_ROOT}/public/404.html" unless @report
  end

  def destroy
    if report = self.class.report_class.find(params[:id])
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
      render :template => "new_session" unless authorized?
    end

end

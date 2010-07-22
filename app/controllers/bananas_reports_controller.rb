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

  private

    def authorized?
      params[:access]                                                 &&
      params[:access][:login]    == self.class.access_data[:login]    &&
      params[:access][:password] == self.class.access_data[:password]
    end

    def authorize
      render_403 unless authorized?
    end

end

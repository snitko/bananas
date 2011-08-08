require 'bananas_report'
require 'bananas_reports_controller'

module Bananas

  def self.included(c)
    class<<c
      def bananas(report_class_name)
        
        report_class = const_get(report_class_name.to_s.camelcase)

        self.send(:define_method, "check_#{report_class.snake_name}") do
          render :file => "#{Rails.root}/public/403.html", :status => 403 if report_class.find_by_ip_address(request.remote_ip)
        end
        
        self.send(:define_method, "cast_#{report_class.snake_name}") do |abuser|
          if abuser.kind_of?(Integer)
            abuser_id = abuser
          elsif !abuser.nil?
            abuser_id = abuser.id
          else
            abuser_id = nil
          end
          abuser_id = abuser if abuser.kind_of?(Integer)
          report_class.cast(:ip_address => request.remote_ip, :abuser_id => abuser_id)
        end

      end
    end
  end

end

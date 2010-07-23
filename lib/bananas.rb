module Bananas

  def self.included(c)
    class<<c
      def bananas(report_class_name)
        
        report_class = const_get(report_class_name)

        self.send(:define_method, "check_#{report_class.snake_name}") do
          render :file => "#{RAILS_ROOT}/public/403.html" if report_class.find_by_ip_address(request.env['REMOTE_ADDR'])
        end
        
        self.send(:define_method, "cast_#{report_class.snake_name}") do |abuser_id|
          report_class.cast(:ip_address => request.env['REMOTE_ADDR'], :abuser_id => abuser_id)
        end

      end
    end
  end

end

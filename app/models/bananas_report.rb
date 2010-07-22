class BananasReport < ActiveRecord::Base

  class<<self

    attr_accessor :abuser, :create_conditions
    
    def belongs_to_abuser(model)
      @abuser = model
      belongs_to @abuser, :foreign_key => "abuser_id"
    end

    def admin_emails(emails)
      @admin_emails = emails
    end

    def cast(attrs)
      @create_conditions ||= [:check_number_of_bananas_attempts]
      if !(report = self.find_by_ip_address(attrs[:ip_address]))
        report = self.new(attrs)
      end
      report.abuser_id = attrs[:abuser_id] if attrs[:abuser_id]
      report.check_create_conditions
      report.counter += 1
      if report.errors.empty? && report.save
        BananasMailer.deliver_new_report(self, @admin_emails)
      end
      return report
    end

    private

      def create_condition(c)
        @create_conditions << c if c.kind_of?(Symbol)
        @create_conditions += c if c.kind_of?(Array)
      end

  end

  def check_create_conditions
    self.class.create_conditions.all? { |c| self.send(c) }
  end


  private
    
    def check_number_of_bananas_attempts
      return true if self.class.abuser.nil?
      abuser = self.send(self.class.abuser)
      if abuser && abuser.bananas_attempts < 10
        abuser.bananas_attempts += 1
        abuser.save
        errors.add(:base, "Not enough attempts to consider this a spam")
        return false
      else
        abuser.update_attributes(:bananas_attempts => 0)
        return true
      end
    end

end

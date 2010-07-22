class BananasReport < ActiveRecord::Base

  @@report_conditions = [:check_number_of_bananas_attempts]

  class<<self
    
    def belongs_to_abuser(model)
      @@abuser = model
      belongs_to @@abuser, :foreign_key => "abuser_id"
    end

    def cast(attrs)
      if !(report = self.find_by_ip_address(attrs[:ip_address]))
        report = self.new(attrs)
      end
      report.abuser_id = attrs[:abuser_id] if attrs[:abuser_id]
      report.check_conditions
      report.counter += 1
      if report.errors.empty? && report.save
        BananasMailer.deliver_new_report(self, ADMIN_EMAILS)
      end
      return report
    end

    private

      def report_condition(c)
        @@report_conditions << c
      end

  end

  def check_conditions
    @@report_conditions.each { |c| break if !self.send(c) }
  end


  private
    
    def check_number_of_bananas_attempts
      abuser = self.send(@@abuser)
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


    def increment_counter
      self.counter += 1
    end

end

module Bananas
  module Report

    def self.included(c)

      class<<c

        attr_accessor :abuser, :create_conditions
        
        def belongs_to_abuser(model)
          @abuser = model
          belongs_to @abuser, :foreign_key => "abuser_id"
        end

        def admin_emails(emails)
          @admin_emails = emails
        end

        def set_allowed_attempts(number)
          @allowed_attempts = number
        end
        def allowed_attempts
          @allowed_attempts ||= 10
        end

        def attempts_storage(type)
          include AttemptsStorage::const_get(type.to_s.camelcase)
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
            BananasMailer.deliver_new_report(report, @admin_emails)
          end
          return report
        end

        def snake_name(options = {})
          name = self.to_s
          name = name.pluralize if options[:plural]
          return name.downcase if self =~ /^[A-Z]+$/
          name.gsub(/([A-Z]+)(?=[A-Z][a-z]?)|\B[A-Z]/, '_\&') =~ /_*(.*)/
            return $+.downcase
        end

        private

          def create_condition(c)
            @create_conditions << c if c.kind_of?(Symbol)
            @create_conditions += c if c.kind_of?(Array)
          end

      end

    end

    def abuser
      self.send(self.class.abuser)
    end

    def check_create_conditions
      self.class.create_conditions.all? { |c| self.send(c) }
    end

    module AttemptsStorage

      module ActiveRecord
        private
        def check_number_of_bananas_attempts
          return true if abuser.nil?
          if abuser && abuser.bananas_attempts < self.class.allowed_attempts
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

      module Cache
        private
        def check_number_of_bananas_attempts
          throw "Nothing here yet"
        end
      end

    end

  end
end

module Bananas
  module Report

    def self.included(c)

      class<<c

        attr_reader :abuser, :create_conditions
        
        def belongs_to_abuser(model)
          @abuser = model
          belongs_to @abuser, :foreign_key => "abuser_id"
        end

        def admin_emails(emails)
          @admin_emails = emails
        end

        def allowed_attempts(number)
          @allowed_attempts = number
        end
        def get_allowed_attempts
          @allowed_attempts ||= 10
        end

        def attempts_expire_in(time)
          @attempts_expire_in = time
        end
        def get_attempts_expire_in
          @attempts_expire_in ||= 10.minutes
        end

        def attempts_storage(type)
          include AttemptsStorage::const_get(type.to_s.camelcase)
        end

        def cast(attrs)
          @create_conditions ||= [:check_number_of_attempts]
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

        def self.included(base)
          const_get(base.abuser.to_s.camelcase).class_eval { serialize :bananas_attempts }
        end

        private
        def check_number_of_attempts
          return true if abuser.nil?
          fresh_attempts = abuser.bananas_attempts.delete_if { |a| a < self.class.get_attempts_expire_in.ago }
          fresh_attempts << Time.now
          if fresh_attempts.size > self.class.get_allowed_attempts
            abuser.update_attributes(:bananas_attempts => [])
          else
            abuser.update_attributes(:bananas_attempts => fresh_attempts)
            errors.add("Not enough bananas attempts to file a report")
          end
        end
      end

      module Cache
        private
        def check_number_of_attempts
          throw "Nothing here yet"
        end
      end

    end

  end
end

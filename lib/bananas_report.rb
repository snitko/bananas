module Bananas
  module Report

    def self.included(c)

      class << c

        attr_reader :abuser

        def create_conditions
          @create_conditions ||= [:check_number_of_attempts]
        end

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

        def attempts_storage(kind, storage = nil)
          if 'Cache' == (mod = kind.to_s.camelcase)
            raise unless storage
            include AttemptsStorage::const_get(mod)
            self.bananas_attempts_cache = storage
          else
            include AttemptsStorage::const_get(mod)
          end
        end

        def cast(attrs)
          report = self.find_or_initialize_by_ip_address(attrs[:ip_address])
          report.abuser_id = attrs[:abuser_id] if attrs[:abuser_id]
          report.check_create_conditions
          report.counter += 1
          if report.errors.empty? && report.save
            BananasMailer.deliver_new_report(report, @admin_emails) unless @admin_emails.blank?
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
          create_conditions
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

      module Common

        def bananas_attempts_for(abuser)
          raise NotImplementedError
        end

        def set_bananas_attempts_for(abuser)
          raise NotImplementedError
        end

        def check_number_of_attempts
          return true if abuser.nil?
          attempts = bananas_attempts_for(abuser)
          if attempts.blank?
            fresh_attempts = []
          else
            fresh_attempts = attempts.delete_if { |a| a < self.class.get_attempts_expire_in.ago }
          end
          if fresh_attempts.size >= self.class.get_allowed_attempts
            set_bananas_attempts(abuser, [])
          else
            fresh_attempts << Time.now
            set_bananas_attempts(abuser, fresh_attempts)
            errors.add("Not enough bananas attempts to file a report")
          end
        end

      end

      module ActiveRecord

        include Common

        def self.included(base)
          const_get(base.abuser.to_s.camelcase).class_eval { serialize :bananas_attempts }
        end

        private

        def bananas_attempts_for(abuser)
          abuser.bananas_attempts
        end

        def set_bananas_attempts_for(abuser, value)
          abuser.update_attributes(:bananas_attempts => value)
        end

      end

      module Cache

        include Common

        def self.included(base)
          class << base
            attr_accessor :bananas_attempts_cache
          end
        end

        private

        def bananas_attempts_cache_key_for(abuser)
          "bananas/attempts/#{abuser.id}" # FIXME: serialize into session
        end

        def bananas_attempts_for(abuser)
          key = bananas_attempts_cache_key_for(abuser)
          self.class.bananas_attempts_cache.fetch(key)
        end

        def set_bananas_attempts_for(abuser, value)
          key = bananas_attempts_cache_key_for(abuser)
          self.class.bananas_attempts_cache.write(key, value, :expires_in => self.class.get_attempts_expire_in)
        end

      end

    end

  end
end

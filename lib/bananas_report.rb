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
          @attempts_storage = kind
        end
        def get_attempts_storage
          @attempts_storage
        end

        def cast(attrs)
          report = self.find_or_initialize_by_ip_address(attrs[:ip_address])
          report.abuser_id = attrs[:abuser_id] if attrs[:abuser_id]
          report.check_create_conditions 
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
          attempts = bananas_attempts || []
          attempts.reject! { |a| a < self.class.get_attempts_expire_in.ago } unless attempts.empty?
          if attempts.size >= self.class.get_allowed_attempts
            self.counter += 1
            set_bananas_attempts([])
          else
            attempts << Time.now.utc
            set_bananas_attempts(attempts)
            errors.add("Not enough bananas attempts to file a report")
          end
        end

      end

      module ActiveRecord

        include Common

        def self.included(base)
          const_get(base.abuser.to_s.camelcase).class_eval { serialize :bananas_attempts }
        end

        def check_number_of_attempts
          return true unless abuser_id
          super
        end

        private

        def bananas_attempts
          abuser.bananas_attempts
        end

        def set_bananas_attempts(value)
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

        def bananas_attempts_cache_key
          # Using ip_address as a key instead of abuser_id -
          # No abuser_id dependency when storing attempts in cache!
          "bananas/attempts/#{ip_address}" # FIXME: serialize into session
        end

        def bananas_attempts
          key = bananas_attempts_cache_key
          self.class.bananas_attempts_cache.fetch(key)
        end

        def set_bananas_attempts(value)
          key = bananas_attempts_cache_key
          self.class.bananas_attempts_cache.write(key, value, :expires_in => self.class.get_attempts_expire_in)
        end

      end

    end

  end
end

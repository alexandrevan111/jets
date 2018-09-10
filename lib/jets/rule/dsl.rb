# Jets::Rule::Base < Jets::Lambda::Functions
# Both Jets::Rule::Base and Jets::Lambda::Functions have Dsl modules included.
# So the Jets::Rule::Dsl overrides some of the Jets::Lambda::Functions behavior.
#
# Implements:
#   default_associated_resource: must return @resources
module Jets::Rule::Dsl
  extend ActiveSupport::Concern

  included do
    class << self
      # Allows for different types of values. Examples:
      #
      # String: scope "AWS::EC2::SecurityGroup"
      # Array:  scope ["AWS::EC2::SecurityGroup"]
      # Hash:   scope {"ComplianceResourceTypes" => ["AWS::EC2::SecurityGroup"]}
      def scope(value)
        scope = case value
          when String
            {compliance_resource_types: [value]}
          when Array
            {compliance_resource_types: value}
          else # default to hash
            value
          end
        update_properties(scope: scope)
      end

      # Convenience method that set properties. List based on https://amzn.to/2oSph1P
      # Not all properites are included because some properties are not meant to be set
      # directly. For example, function_name is a calculated setting by Jets.
      PROPERTIES = %W[
        config_rule_name
        description
        input_parameters
        maximum_execution_frequency
      ]
      PROPERTIES.each do |property|
        # Example:
        #   def config_rule_name(value)
        #     update_properties(config_rule_name: value)
        #   end
        class_eval <<~CODE
          def #{property}(value)
            update_properties(#{property}: value)
          end
        CODE
      end
      # Note: desc and description override the lambda description but think it makes sense.
      alias_method :desc, :description

      def default_associated_resource
        config_rule
      end

      def config_rule(props={})
        config_rule = Jets::Resource::Config::ConfigRule.new(props)
        resource(config_rule.definition) # Sets @resources
        @resources.last
      end

      def managed_rule(name, props={})
        name = name.to_s

        # Similar logic in Replacer::ConfigRule#config_rule_name
        name_without_rule = self.name.underscore.gsub(/_rule$/,'')
        config_rule_name = "#{name_without_rule}_#{name}".dasherize
        source_identifier = name.upcase

        default_props = {
          config_rule_name: config_rule_name,
          source: {
            owner: "AWS",
            source_identifier: source_identifier,
          }
        }
        properties = default_props.deep_merge(props)
        # The key is to use update_properties to update the current resource and maintain
        # the added properties from the convenience methods like scope and description.
        # At the same time, we do not register the task to all_tasks to avoid creating a Lambda function.
        # Instead we store it in all_managed_rules.
        update_properties(properties)
        definition = @resources.first # assume first resource

        register_managed_rule(name, definition)
      end

      # Creates a task but registers it to all_managed_rules instead of all_tasks
      # because we do not want Lambda functions to be created.
      def register_managed_rule(name, definition)

        # Mimic task to grab base_replacements, namely namespace.
        # Do not actually use the task to create a Lambda function for managed rules.
        # Only using the task for base_replacements.
        resources = [definition]
        meth = name
        task = Jets::Lambda::Task.new(self.name, meth,
                 resources: resources,
                 replacements: replacements(meth))
        all_managed_rules[name] = { definition: definition, replacements: task.replacements }
        clear_properties
      end

      # Override lambda/dsl.rb to add config_rule_name also
      def replacements(meth)
        name_without_rule = self.name.underscore.gsub(/_rule$/,'')
        config_rule_name = "#{name_without_rule}_#{meth}".dasherize
        {
          config_rule_name: config_rule_name
        }
      end

      # AWS managed rules are not actual Lambda functions and require their own storage.
      def all_managed_rules
        @all_managed_rules ||= ActiveSupport::OrderedHash.new
      end

      def managed_rules
        all_managed_rules.values
      end

      # Override Lambda::Dsl.build? to account for possible managed_rules
      def build?
        !tasks.empty? || !managed_rules.empty?
      end
    end
  end
end

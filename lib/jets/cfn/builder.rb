require 'active_support/core_ext/hash'
require 'yaml'

class Jets::Cfn
  class Builder < Base
    def initialize(controller_class)
      @controller_class = controller_class
      @template = ActiveSupport::HashWithIndifferentAccess.new(Resources: {})
    end

    def compose!
      add_iam
      add_functions
    end

    # Adds LambdaIamRole as a parameter
    def add_iam
      add_parameter("LambdaIamRole", Description: "Iam Role that Lambda function uses.")
    end

    def add_functions
      @controller_class.lambda_functions.each do |name|
        add_function(name)
      end
    end

    def add_function(name)
      namer = Namer.new(@controller_class, name)

      add_resource(namer.logical_id, "AWS::Lambda::Function",
        Code: {
          S3Bucket: {Ref: "S3Bucket"}, # from child stack
          S3Key: namer.s3_key
        },
        FunctionName: namer.function_name,
        Handler: namer.handler,
        Role: { Ref: "LambdaIamRole" },
        MemorySize: Jets::Project.memory_size,
        Runtime: Jets::Project.runtime,
        Timeout: Jets::Project.timeout
      )
    end

    def template
      @template
    end

    def text
      YAML.dump(@template.to_hash)
    end
  end
end

require 'erb'

class Jets::Cfn::TemplateBuilders
  class ParentBuilder
    include Interface
    include Jets::AwsServices

    def initialize(options={})
      @options = options
      @template = ActiveSupport::HashWithIndifferentAccess.new(Resources: {})
    end

    # compose is an interface method
    def compose
      puts "Building parent template."

      add_minimal_resources
      add_child_resources unless @options[:stack_type] == :minimal
    end

    # template_path is an interface method
    def template_path
      Jets::Naming.parent_template_path
    end

    def add_minimal_resources
      # Initial s3 bucket, used to store code zipfile and templates Jets generates
      resource = Jets::Resource::S3.new
      add_resource(resource)
      add_outputs(resource.outputs)

      # Add application-wide IAM policy from Jets.config.iam_role
      resource = Jets::Resource::Iam::ApplicationRole.new
      add_resource(resource)
      add_outputs(resource.outputs)
    end

    def add_child_resources
      expression = "#{Jets::Naming.template_path_prefix}-*"
      # IE: path: #{Jets.build_root}/templates/demo-dev-2-comments_controller.yml
      Dir.glob(expression).each do |path|
        next unless File.file?(path)
        next if path =~ /api-gateway/ # specially treated

        add_app_class_stack(path)
      end

      if @options[:stack_type] == :full and !Jets::Router.routes.empty?
        add_api_gateway
        add_api_deployment
      end
    end

    def add_app_class_stack(path)
      resource = Jets::Resource::ChildStack::AppClass.new(path, @options[:s3_bucket])
      build_child_resources(resource)
    end

    def add_api_gateway
      resource = Jets::Resource::ChildStack::ApiGateway.new(@options[:s3_bucket])
      build_child_resources(resource)
    end

    def add_api_deployment
      resource = Jets::Resource::ChildStack::ApiDeployment.new(@options[:s3_bucket])
      build_child_resources(resource)
    end

    def build_child_resources(resource)
      add_resource(resource)
      add_outputs(resource.outputs)
    end
  end
end

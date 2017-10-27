class Jets::Cfn::Builder
  class Parent
    include Helpers

    def initialize
      @template = ActiveSupport::HashWithIndifferentAccess.new(Resources: {})
    end

    def compose
      puts "Building parent template"
      add_output("S3Bucket")
      add_output("IamRole")
      add_child_resources
    end

    def add_child_resources
      expression = "#{Jets::Cfn::Namer.template_prefix}-*"
      puts "expression #{expression.inspect}"
      Dir.glob(expression).each do |path|
        # next unless File.file?(path)
        puts "path #{path}".colorize(:red)

        # Child app stacks
        app = AppInfo.new(path)
        # app.logical_id - PostsController
        add_resource(app.logical_id, "AWS::CloudFormation::Stack",
          TemplateURL: app.template_url,
          Parameters: app.parameters,
          DependsOn: ["Base"]
        )
      end

      base = BaseInfo.new
      add_resource(base.logical_id, "AWS::CloudFormation::Stack",
          TemplateURL: base.template_url,
          Parameters: base.parameters
        )
    end

    def write
      template_path = Jets::Cfn::Namer.parent_template_path
      puts "writing parent stack template #{template_path}"
      FileUtils.mkdir_p(File.dirname(template_path))
      IO.write(template_path, text)
    end
  end
end
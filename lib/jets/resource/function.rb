class Jets::Resource
  class Function < Jets::Resource::Base
    def initialize(task)
      @task = task
      @app_class = task.class_name.to_s
    end

    def definition
      {
        function_logical_id => {
          type: "AWS::Lambda::Function",
          properties: combined_properties
        }
      }
    end

    def function_logical_id
      "{namespace}_lambda_function".underscore
    end

    def replacements
      @task.replacements # has namespace replacement
    end

    def combined_properties
      props = env_file_properties
        .deep_merge(global_properties)
        .deep_merge(class_properties)
        .deep_merge(function_properties)
      finalize_properties!(props)
    end

    def env_file_properties
      env_vars = Jets::Dotenv.load!(true)
      {environment: { variables: env_vars }}
    end

    # Global properties example:
    # jets defaults are in jets/default/application.rb.
    # Your application's default config/application.rb then get used. Example:
    #
    #   Jets.application.configure do
    #     config.function = ActiveSupport::OrderedOptions.new
    #     config.function.timeout = 10
    #     config.function.runtime = "nodejs8.10"
    #     config.function.memory_size = 1536
    #   end
    def global_properties
      baseline = {
        code: {
          s3_bucket: "!Ref S3Bucket",
          s3_key: code_s3_key
        },
        role: "!Ref IamRole",
        environment: { variables: environment },
      }

      appplication_config = Jets.application.config.function.to_h
      baseline.merge(appplication_config)
    end

    # Class properties example:
    #
    #   class PostsController < ApplicationController
    #     class_timeout 22
    #     ...
    #   end
    #
    # Also handles iam policy override at the class level. Example:
    #
    #   class_iam_policy("logs:*")
    #
    def class_properties
      # klass is PostsController, HardJob, GameRule, Hello or HelloFunction
      klass = Jets::Klass.from_task(@task)
      class_properties = klass.class_properties
      if klass.build_class_iam?
        iam_policy = Jets::Resource::Iam::ClassRole.new(klass)
        class_properties[:role] = "!GetAtt #{iam_policy.logical_id}.Arn"
      end
      class_properties
    end

    # Function properties example:
    #
    # class PostsController < ApplicationController
    #   timeout 18
    #   def index
    #     ...
    #   end
    #
    # Also handles iam policy override at the function level. Example:
    #
    #   iam_policy("ec2:*")
    #   def new
    #     render json: params.merge(action: "new")
    #   end
    #
    def function_properties
      properties = @task.properties
      if @task.build_function_iam?
        iam_policy = Jets::Resource::Iam::FunctionRole.new(@task)
        properties[:role] = "!GetAtt #{iam_policy.logical_id}.Arn"
      end
      properties
    end

    # Properties managed by Jets with more finality.
    def finalize_properties!(props)
      handler = full_handler(props)
      runtime = get_runtime(props)
      props.merge!(
        function_name: function_name,
        handler: handler,
        runtime: runtime,
      )
    end

    def get_runtime(props)
      props[:runtime] || default_runtime
    end

    def default_runtime
      map = {
        node: "nodejs8.10",
        python: "python3.6",
        ruby: "nodejs8.10", # node shim for ruby support
      }
      map[@task.lang]
    end

    def default_handler
      map = {
        node: @task.full_handler(:handler), # IE: handlers/controllers/posts/show.handler
        python: @task.full_handler(:lambda_handler), # IE: handlers/controllers/posts/show.lambda_handler
        ruby: handler, # IE: handlers/controllers/posts_controllers.index
      }
      map[@task.lang]
    end

    def handler
      handler_value(@task.meth)  # IE: handlers/controllers/posts_controllers.index
    end

    # Used for node-shim also
    def handler_value(meth)
      "handlers/#{@task.type.pluralize}/#{@app_class.underscore}.#{meth}"
    end

    # Ensure that the handler path is normalized.
    def full_handler(props)
      if props[:handler]
        handler_value(props[:handler])
      else
        default_handler
      end
    end

    def code_s3_key
      Jets::Naming.code_s3_key
    end

    # Examples:
    #   "#{Jets.config.project_namespace}-sleep_job-perform"
    #   "demo-dev-sleep_job-perform"
    def function_name
      # Example values:
      #   @app_class: admin/pages_controller
      #   @task.meth: index
      #   method: admin/pages_controller
      #   method: admin-pages_controller-index
      method = @app_class.underscore
      method = method.sub('/','-') + "-#{@task.meth}"
      "#{Jets.config.project_namespace}-#{method}"
    end

    def environment
      env = Jets.config.environment ? Jets.config.environment.to_h : {}
      jets_env_options = {JETS_ENV: Jets.env.to_s}
      jets_env_options[:JETS_ENV_EXTRA] = Jets.config.env_extra if Jets.config.env_extra
      env.deep_merge(jets_env_options)
    end
  end
end
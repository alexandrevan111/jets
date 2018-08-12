require "thor"

module Jets::Commands
  class Main < Base

    class_option :noop, type: :boolean

    desc "build", "Builds and packages project for AWS Lambda"
    long_desc Help.text(:build)
    option :templates_only, type: :boolean, default: false, desc: "provide a way to skip building the code and only build the CloudFormation templates"
    def build
      Build.new(options).run
    end

    desc "deploy [environment]", "Builds and deploys project to AWS Lambda"
    long_desc Help.text(:deploy)
    option :capabilities, type: :array, desc: "iam capabilities. Ex: CAPABILITY_IAM, CAPABILITY_NAMED_IAM"
    option :iam, type: :boolean, desc: "Shortcut for common IAM capabilities: CAPABILITY_IAM, CAPABILITY_NAMED_IAM"
    # Note the environment is here to trick the Thor parser to allowing an
    # environment parameter. It is not actually set here.  It is set earlier
    # in cli.rb: set_jets_env_for_deploy_command!
    def deploy(environment=nil)
      Jets::Timing.clear # must happen outside Deploy#run
      Deploy.new(options).run
      Jets::Timing.report
    end

    desc "delete", "Delete the Jets project and all its resources"
    long_desc Help.text(:delete)
    option :sure, type: :boolean, desc: "Skip are you sure prompt."
    option :wait, type: :boolean, default: true, desc: "Wait for stack deletion to complete."
    def delete
      Delete.new(options).run
    end

    desc "server", "Runs a local server that mimics API Gateway for development"
    long_desc Help.text(:server)
    option :port, default: "8888", desc: "use PORT"
    option :host, default: "127.0.0.1", desc: "listen on HOST"
    def server
      # shell out to shotgun for automatic reloading
      o = options
      command = "bundle exec shotgun --port #{o[:port]} --host #{o[:host]}"
      puts "=> #{command}".colorize(:green)
      puts Jets::Booter.message
      system(command)
    end

    desc "routes", "Print out your application routes"
    long_desc Help.text(:routes)
    def routes
      puts Jets::Router.routes_help
    end

    desc "console", "REPL console with Jets environment loaded"
    long_desc Help.text(:console)
    def console
      Console.run
    end

    desc "dbconsole", "Starts DB REPL console"
    long_desc Help.text(:dbconsole)
    def dbconsole
      Dbconsole.start(*args)
    end

    # Command is called 'call' because invoke is a Thor keyword.
    desc "call [function] [event]", "Call a lambda function on AWS or locally"
    long_desc Help.text(:call)
    option :invocation_type, default: "RequestResponse", desc: "RequestResponse, Event, or DryRun"
    option :log_type, default: "Tail", desc: "Works if invocation_type set to RequestResponse"
    option :qualifier, desc: "Lambda function version or alias name"
    option :show_log, type: :boolean, desc: "Shows last 4KB of log in the x-amz-log-result header"
    option :lambda_proxy, type: :boolean, default: true, desc: "Enables automatic Lambda proxy transformation of the event payload"
    option :guess, type: :boolean, default: true, desc: "Enables guess mode. Uses inference to allows use of all dashes to specify functions. Smart mode verifies that the function exists in the code base."
    option :local, type: :boolean, desc: "Enables local mode. Instead of invoke the AWS Lambda function, the method gets called locally with current app code. With local mode guess mode is always used."
    def call(function_name, payload='')
      Call.new(function_name, payload, options).run
    end

    desc "generate [type] [args]", "Generates things like scaffolds"
    long_desc Help.text(:generate)
    def generate(generator, *args)
      Jets::Generator.invoke(generator, *args)
    end

    desc "status", "Shows the current status of the Jets app."
    long_desc Help.text(:status)
    def status
      Jets::Cfn::Status.new(options).run
    end

    desc "url", "App url if routes are defined"
    long_desc Help.text(:url)
    def url
      Jets::Commands::Url.new(options).display
    end

    desc "version", "Prints Jets version"
    long_desc Help.text(:version)
    def version
      puts Jets.version
    end

    long_desc Help.text(:new)
    Jets::Commands::New.cli_options.each do |args|
      option *args
    end
    register(Jets::Commands::New, "new", "new", "Creates a starter skeleton jets project")
  end
end

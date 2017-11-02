require "thor"
require "jets/cli/help"

module Jets

  class CLI < Command
    class_option :verbose, type: :boolean
    class_option :noop, type: :boolean

    desc "build", "Builds and prepares project for Lambda"
    long_desc Help.build
    def build
      Jets::Build.new(options).run
    end

    desc "deploy", "Deploys project to Lambda"
    long_desc Help.deploy
    option :capabilities, type: :array, desc: "iam capabilities. Ex: CAPABILITY_IAM, CAPABILITY_NAMED_IAM"
    option :iam, type: :boolean, desc: "Shortcut for common IAM capabilities: CAPABILITY_IAM, CAPABILITY_NAMED_IAM"
    def deploy
      Jets::Deploy.new(options).run
    end

    desc "delete", "Delete project and all its resources"
    long_desc Help.delete
    option :sure, type: :boolean, desc: "Skip are you sure prompt."
    def delete
      Jets::Delete.new(options).run
    end

    desc "new", "Creates new starter project"
    long_desc Help.new_long_desc
    option :template, default: "starter", desc: "Starter template to use."
    def new(project_name)
      Jets::New.new(project_name, options).run
    end

    desc "process TYPE", "process subtasks"
    subcommand "process", Jets::Process

    desc "generate TYPE", "generate subtasks"
    subcommand "generate", Jets::Generate
  end
end

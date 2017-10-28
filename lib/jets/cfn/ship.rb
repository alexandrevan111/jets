require 'action_view'

class Jets::Cfn
  class Ship
    include Jets::AwsServices
    include ActionView::Helpers::NumberHelper # number_to_human_size

    def initialize(options)
      @options = options
      @stack_name = Jets::Naming.parent_stack_name
      @template_path = Jets::Naming.parent_template_path
    end

    def run
      upload_to_s3 if @options[:s3_bucket] # available when stack_type is not minimal

      puts "Shipping CloudFormation stack!"
      begin
        save_stack
      rescue Aws::CloudFormation::Errors::InsufficientCapabilitiesException => e
        capabilities = e.message.match(/\[(.*)\]/)[1]
        confirm = prompt_for_iam(capabilities)
        if confirm =~ /^y/
          @options.merge!(capabilities: [capabilities])
          puts "Re-running: #{command_with_iam(capabilities).colorize(:green)}"
          retry
        else
          puts "Exited"
          exit 1
        end
      end

      wait_for_stack
    end

    def save_stack
      if stack_exists?(@stack_name)
        update_stack
      else
        create_stack
      end
    end

    # TODO: move this all into create.rb class
    def create_stack
      # parent stack from file system, child stacks from s3
      template_body = IO.read(@template_path)
      cfn.create_stack(
        stack_name: @stack_name,
        template_body: template_body,
        capabilities: capabilities, # ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
        # disable_rollback: !@options[:rollback],
      )
    end

    # TODO: move this all into update.rb class and use changesets as default
    def update_stack
      template_body = IO.read(@template_path)
      begin
        cfn.update_stack(
          stack_name: @stack_name,
          template_body: template_body,
          capabilities: capabilities, # ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
          # disable_rollback: !@options[:rollback],
        )
      rescue Aws::CloudFormation::Errors::ValidationError => e
        puts "ERROR: #{e.message}".red
        error = true
      end
    end

    # check for _COMPLETE or _FAILED
    def wait_for_stack
      status = ''
      while status !~ /(_COMPLETE|_FAILED)$/
        resp, status = stack_status
        sleep 5
        print '.'
      end
      puts
      if status =~ /_FAILED/
        puts "Stack status: #{status}".colorize(:red)
        puts "Stack reason #{resp.stacks[0].stack_reason}".colorize(:red)
      else
        puts "Stack status: #{status}".colorize(:green)
      end
    end

    # All CloudFormation states listed here:
    # http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-describing-stacks.html
    def stack_status
      resp = cfn.describe_stacks(stack_name: @stack_name)
      status = resp.stacks[0].stack_status
      [resp, status]
    end

    def prompt_for_iam(capabilities)
      puts "This stack will create IAM resources.  Please approve to run the command again with #{capabilities} capabilities."
      puts "  #{command_with_iam(capabilities)}"

      puts "Please confirm (y/n)"
      confirm = $stdin.gets
    end

    def command_with_iam(capabilities)
      "#{File.basename($0)} #{ARGV.join(' ')} --capabilities #{capabilities}"
    end

    def capabilities
      return @options[:capabilities] if @options[:capabilities]
      if @options[:iam]
        ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
      end
    end

    # Upload both code and child templates to s3
    def upload_to_s3
      bucket_name = @options[:s3_bucket]

      puts "Uploading child CloudFormation templates to S3"
      expression = "#{Jets::Naming.template_prefix}-*"
      Dir.glob(expression).each do |path|
        next unless File.file?(path)

        key = "jets/cfn-templates/#{File.basename(path)}"
        obj = s3_resource.bucket(bucket_name).object(key)
        obj.upload_file(path)
      end

      zip_path = Jets::Naming.md5_code_zipfile
      file_size = number_to_human_size(File.size(zip_path))

      if ENV['SKIP_S3_UPLOAD']
        puts "Skipping uploading of #{zip_path} (#{file_size}) to S3 for quick testing"
        return
      end

      puts "Uploading #{zip_path} (#{file_size}) to S3"
      start_time = Time.now
      key = Jets::Naming.code_s3_key
      obj = s3_resource.bucket(bucket_name).object(key)
      obj.upload_file(zip_path)
      puts "Took #{pretty_time(Time.now-start_time)} to upload code to s3."
    end

    # http://stackoverflow.com/questions/4175733/convert-duration-to-hoursminutesseconds-or-similar-in-rails-3-or-ruby
    def pretty_time(total_seconds)
      minutes = (total_seconds / 60) % 60
      seconds = total_seconds % 60
      if total_seconds < 60
        "#{seconds.to_i}s"
      else
        "#{minutes.to_i}m #{seconds.to_i}s"
      end
    end
  end
end
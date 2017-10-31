require 'digest'

class Jets::Build
  autoload :Deducer, "jets/build/deducer"
  autoload :HandlerGenerator, "jets/build/handler_generator"
  autoload :TravelingRuby, "jets/build/traveling_ruby"
  autoload :RoutesBuilder, "jets/build/routes_builder"
  autoload :Route, "jets/build/route"

  def initialize(options)
    @options = options
  end

  def run
    puts "Building project for Lambda..."
    build
  end

  def build
    TravelingRuby.new.build unless @options[:noop]

    clean_start # cleans out templates and code-*.zip in /tmp/jets_build/

    puts "Building node shims..."
    each_deducer do |deducer|
      puts "  #{deducer.path} => #{deducer.js_path}"
      generate_node_shim(path)
    end
    create_zip_file

    # TODO: move this build.rb logic to cfn/builder.rb
    ## CloudFormation templates
    puts "Building Lambda functions as CloudFormation templates.."
    # 1. Shared templates - child templates needs them
    build_api_gateway_templates
    # 2. Child templates - parent template needs them
    each_deducer do |deducer|
      puts "  #{deducer.path} => #{deducer.cfn_path}"
      build_child_template(deducer) #
    end
    # 3. Finally parent template
    build_parent_template # must be called at the end
  end

  def generate_node_shim(path)
    handler = Jets::Build::HandlerGenerator.new(path)
    handler.generate
  end

  def build_api_gateway_templates
    gateway = Jets::Cfn::Builder::ApiGatewayTemplate.new(@options)
    gateway.build
    deployment = Jets::Cfn::Builder::ApiGatewayDeploymentTemplate.new(@options)
    deployment.build
  end

  def build_child_template(deducer)
    # require "#{Jets.root}#{deducer.path}" # "app/controllers/posts_controller.rb"
    klass = deducer.class_name.constantize # IE: PostsController
    cfn = Jets::Cfn::Builder::ChildTemplate.new(klass)
    cfn.build
  end

  def build_parent_template
    parent = Jets::Cfn::Builder::ParentTemplate.new(@options)
    parent.build
  end

  def each_deducer
    controller_paths.each do |path|
      deducer = LambdaDeducer.new(path)
      yield(deducer)
    end
  end

  # Remove any current templates in the tmp build folder for a clean start
  def clean_start
    FileUtils.rm_rf("/tmp/jets_build/templates")
    Dir.glob("/tmp/jets_build/code-*.zip").each { |f| FileUtils.rm_f(f) }
  end

  def controller_paths
    paths = []
    expression = "#{Jets.root}app/controllers/**/*.rb"
    Dir.glob(expression).each do |path|
      next unless File.file?(path)
      next if path.include?("application_controller.rb")

      paths << relative_path(path)
    end
    paths
  end

  # Rids of the Jets.root at beginning
  def relative_path(path)
    path.sub(Jets.root, '')
  end

  def create_zip_file
    puts 'Creating zip file.'
    Dir.chdir(Jets.root) do
      # TODO: create_zip_file adds unnecessary files like log files. cp and into temp directory and clean the directory up first.
      success = system("zip -rq #{File.basename(temp_code_zipfile)} .")
      dir = File.dirname(md5_code_zipfile)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      FileUtils.mv(temp_code_zipfile, md5_code_zipfile)
      abort('Creating zip failed, exiting.') unless success
    end
  end

  def temp_code_zipfile
    Jets::Naming.temp_code_zipfile
  end

  def md5_code_zipfile
    Jets::Naming.md5_code_zipfile
  end
end

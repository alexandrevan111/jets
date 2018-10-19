require "fileutils"
require "open-uri"
require "colorize"
require "socket"
require "net/http"
require "action_view"
require "bundler" # for clean_old_submodules only

# Some important folders to help understand how jets builds a project:
#
# /tmp/jets: build root where different jets projects get built.
# /tmp/jets/project: each jets project gets built in a different subdirectory.
#
# The rest of the folders are subfolders under /tmp/jets/project:
#
# cache: Gemfile is here, this is where we run bundle install.
# cache/bundled/gems: Vendored gems that get created as part of bundled install.
#   Initially, macosx gems but then get replaced by linux gems where appropriate.
# cache/downloads/rubies: ruby tarballs.
# cache/downloads/gems: gem tarballs.
# code: Where project gets copied into in order for us to configure it.
# app_root/bundled/gems: Where vendored gems finally end up at.  The compiled
#   gems at this point are only linux gems.
# artifacts/code/code-md5sha.zip: code artifact that gets uploaded to lambda.
#
# Building Steps:
#
### Before copy
# * compile assets: easier to do this before the copy
#
### copy project
# * copy project: to app_root
#
### setup app_root project
# * clean project: remove log and ignored files to reduce size
# * reconfigure webpacker: config/webpacker.yml
# * generate node shims: handlers
#
### build bundled in cache area
# * bundle install: cache/bundled/gems
#
### setup bundled on app root from cache
# * copy bundled to code: code/bundled
# * extract linux ruby: cache/downloads/rubies:
#                       cache/bundled/rbenv, cache/bundled/linuxbrew
# * extract linux gems: cache/downloads/gems:
#                       cache/bundled/gems, cache/bundled/linuxbrew
# * setup bundled config: code/.bundle/config
#
### zip
# * create zip fileC
class Jets::Builders
  class CodeBuilder
    include Jets::Timing
    include Jets::AwsServices
    include Util

    attr_reader :full_project_path
    def initialize
      # Expanding to the full path and capture now.
      # Dir.chdir gets called later and we'll lose this info.
      @full_project_path = File.expand_path(Jets.root) + "/"
    end

    def build
      cache_check_message
      check_ruby_version

      clean_start
      compile_assets # easier to do before we copy the project
      copy_project
      Dir.chdir(full(tmp_code)) do
        # These commands run from project root
        start_code_setup
        package_ruby
        finish_code_setup
        setup_tmp
        create_zip_files
      end
    end
    time :build

    # Moves code/bundled and code/rack to build_root.
    # These files will be packaged separated and lazy loaded as part of the
    # node shim. This keeps the code zipfile smaller in size and helps
    # with the 250MB extract limited. /tmp permits up to 512MB.
    # AWS Lambda Limits: https://amzn.to/2A7y6v6
    #
    #   > Each Lambda function receives an additional 512MB of non-persistent disk space in its own /tmp directory. The /tmp directory can be used for loading additional resources like dependency libraries or data sets during function initialization.
    #
    def setup_tmp
      symlink_to_tmp("bundled")
      symlink_to_tmp("rack")
    end

    def stage_area
      "#{Jets.build_root}/stage"
    end

    # Moves folder to a stage folder and create a symlink its place
    # that links from /var/task to /tmp. Example:
    #
    #   /var/task/bundled => /tmp/bundled
    #
    def symlink_to_tmp(folder)
      src = "#{full(tmp_code)}/#{folder}"
      return unless File.exist?(src)

      dest = "#{stage_area}/#{folder}"
      dir = File.dirname(dest)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      FileUtils.mv(src, dest)

      # Create symlink
      FileUtils.ln_sf("/tmp/#{folder}", "/#{full(tmp_code)}/#{folder}")
    end

    def create_zip_files
      paths = %w[
        stage/code
        stage/bundled
        stage/rack
      ]
      paths.map! { |p| "#{Jets.build_root}/#{p}" }
      paths.each do |path|
        zip = Md5Zip.new(path)
        zip.create
      end
    end
    time :create_zip_files

    def start_code_setup
      reconfigure_development_webpacker
      generate_node_shims
    end
    time :start_code_setup

    def finish_code_setup
      return if poly_only?

      store_s3_base_url
    end
    time :finish_code_setup

    # Store s3 base url is needed for asset serving from s3 later. Need to package this
    # as part of the code so we have a reference to it.
    # At this point the minimal stack exists, so we can grab it with the AWS API.
    # We do not want to grab this as part of the live request because it is slow.
    def store_s3_base_url
      IO.write("#{full(tmp_code)}/config/s3_base_url.txt", s3_base_url)
    end

    def s3_base_url
      # Allow user to set assets.base_url
      #
      #   Jets.application.configure do
      #     config.assets.base_url = "https://cloudfront.com/my/base/path"
      #   end
      #
      return Jets.config.assets.base_url if Jets.config.assets.base_url

      resp = cfn.describe_stacks(stack_name: Jets::Naming.parent_stack_name)
      stack = resp.stacks.first
      output = stack["outputs"].find { |o| o["output_key"] == "S3Bucket" }
      bucket_name = output["output_value"] # s3_bucket
      region = Jets.aws.region

      asset_base_url = "https://s3-#{region}.amazonaws.com"
      "#{asset_base_url}/#{bucket_name}/jets/public" # s3_base_url
    end

    # This happens in the current app directory not the tmp code for simplicity
    def compile_assets
      # puts "COMPILE_ASSETS TEMPORARILY DISABLED".colorize(:yellow)
      # return


      headline "Compling assets in current project directory"
      # Thanks: https://stackoverflow.com/questions/4195735/get-list-of-gems-being-used-by-a-bundler-project
      webpacker_loaded = Gem.loaded_specs.keys.include?("webpacker")
      return unless webpacker_loaded

      sh("yarn install")
      webpack_bin = File.exist?("#{Jets.root}bin/webpack") ?
          "bin/webpack" :
          `which webpack`.strip
      sh("JETS_ENV=#{Jets.env} #{webpack_bin}")
    end
    time :compile_assets

    # Cleans out non-cached files like code-*.zip in Jets.build_root
    # for a clean start. Also ensure that the /tmp/jets/project build root exists.
    #
    # Most files are kept around after the build process for inspection and
    # debugging. So we have to clean out the files. But we only want to clean out
    # some of the files.
    def clean_start
      Dir.glob("#{Jets.build_root}/code/code-*.zip").each { |f| FileUtils.rm_f(f) }
      FileUtils.mkdir_p(Jets.build_root) # /tmp/jets/demo
    end

    # Copy project into temporary directory. Do this so we can keep the project
    # directory untouched and we can also remove a bunch of unnecessary files like
    # logs before zipping it up.
    def copy_project
      headline "Copying current project directory to temporary build area: #{full(tmp_code)}"
      FileUtils.rm_rf(stage_area) # clear out from previous build
      FileUtils.mkdir_p(stage_area)
      FileUtils.rm_rf(full(tmp_code)) # remove current code folder
      move_node_modules(Jets.root, Jets.build_root)
      begin
        FileUtils.cp_r(@full_project_path, full(tmp_code))
      ensure
        move_node_modules(Jets.build_root, Jets.root) # move node_modules directory back
      end
    end
    time :copy_project

    # Move the node modules to the tmp build folder to speed up project copying.
    # A little bit risky because a ctrl-c in the middle of the project copying
    # results in a missing node_modules but user can easily rebuild that.
    #
    # Tesing shows 6.623413 vs 0.027754 speed improvement.
    def move_node_modules(source_folder, dest_folder)
      source = "#{source_folder}/node_modules"
      dest = "#{dest_folder}/node_modules"
      if File.exist?(source)
        FileUtils.mv(source, dest)
      end
    end

    def generate_node_shims
      headline "Generating node shims in the handlers folder."
      # Crucial that the Dir.pwd is in the tmp_code because for
      # Jets::Builders::app_files because Jets.boot set ups
      # autoload_paths and this is how project classes are loaded.
      Jets::Commands::Build.app_files.each do |path|
        handler = Jets::Builders::HandlerGenerator.new(path)
        handler.generate
      end
    end

    # Bit hacky but this saves the user from accidentally forgetting to change this
    # when they deploy a jets project in development mode
    def reconfigure_development_webpacker
      return unless Jets.env.development?
      headline "Reconfiguring webpacker development settings for AWS Lambda."

      webpacker_yml = "#{full(tmp_code)}/config/webpacker.yml"
      return unless File.exist?(webpacker_yml)

      config = YAML.load_file(webpacker_yml)
      config["development"]["compile"] = false # force this to be false for deployment
      new_yaml = YAML.dump(config)
      IO.write(webpacker_yml, new_yaml)
    end

    def package_ruby
      ruby_packager = RubyPackager.new(tmp_code)
      rack_packager = RackPackager.new("#{tmp_code}/rack")

      ruby_packager.install
      rack_packager.install
      ruby_packager.finish
      rack_packager.finish
    end
    time :package_ruby

    def cache_check_message
      if File.exist?("#{Jets.build_root}/cache")
        puts "The #{Jets.build_root}/cache folder exists. Incrementally re-building the jets using the cache.  To clear the cache: rm -rf #{Jets.build_root}/cache"
      end
    end

    def check_ruby_version
      unless ruby_version_supported?
        puts "You are using ruby version #{RUBY_VERSION} which is not supported by Jets."
        ruby_variant = Jets::RUBY_VERSION.split('.')[0..1].join('.') + '.x'
        abort("Jets uses ruby #{Jets::RUBY_VERSION}.  You should use a variant of ruby #{ruby_variant}".colorize(:red))
      end
    end

    def ruby_version_supported?
      pattern = /(\d+)\.(\d+)\.(\d+)/
      md = RUBY_VERSION.match(pattern)
      ruby = {major: md[1], minor: md[2]}
      md = Jets::RUBY_VERSION.match(pattern)
      jets = {major: md[1], minor: md[2]}

      ruby[:major] == jets[:major] && ruby[:minor] == jets[:minor]
    end

    # Group all the path settings together here
    def self.tmp_code
      Jets::Commands::Build.tmp_code
    end

    def tmp_code
      self.class.tmp_code
    end
  end
end

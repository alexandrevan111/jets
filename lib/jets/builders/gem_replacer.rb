class Jets::Builders
  class GemReplacer
    extend Memoist
    def initialize(options)
      @options = options
    end

    def run
      check = Jets::Gems::Check.new
      if Jets.config.lambda.layers.empty?
        found_gems = check.run! # exits early if missing gems found
      else
        # assumes missing gems are in the provided custom layer by the user
        found_gems = check.run # does not exist early
      end

      # found gems will only have gems that were found
      found_gems.each do |gem_name, source|
        options = @options.merge(source_url: source)
        gem_extractor = Jets::Gems::Extract::Gem.new(gem_name, options)
        gem_extractor.run
      end

      tidy
    end

    def sh(command)
      puts "=> #{command}".colorize(:green)
      success = system(command)
      abort("Command Failed") unless success
      success
    end

    def ruby_folder
      Jets::Gems.ruby_folder
    end

    # remove unnecessary files to reduce package size
    def tidy
      # project_root: /tmp/jets/demo/stage/code/
      # /tmp/jets/demo/stage/code/bundled
      tidy_gems("#{@options[:project_root]}/ruby/gems/#{ruby_folder}/*/gems/*")
      tidy_gems("#{@options[:project_root]}/ruby/gems/#{ruby_folder}/*/bundler/gems/*")
    end

    def tidy_gems(gems_path)
      Dir.glob(gems_path).each do |gem_path|
        tidy_gem(gem_path)
      end
    end

    # Clean up some unneeded files to try to keep the package size down
    # In a generated jets app this made a decent 9% difference:
    #  175M test2
    #  191M test3
    def tidy_gem(path)
      # remove top level tests and cache folders
      Dir.glob("#{path}/*").each do |path|
        next unless File.directory?(path)
        folder = File.basename(path)
        if %w[test tests spec features benchmark cache doc].include?(folder)
          FileUtils.rm_rf(path)
        end
      end

      Dir.glob("#{path}/**/*").each do |path|
        next unless File.file?(path)
        ext = File.extname(path)
        if %w[.rdoc .md .markdown].include?(ext) or
           path =~ /LICENSE|CHANGELOG|README/
          FileUtils.rm_f(path)
        end
      end
    end
  end
end

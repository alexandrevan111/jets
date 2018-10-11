class Jets::Builders
  class Tidy
    def initialize(project_root)
      @project_root = project_root
    end

    def cleanup!
      removals.each do |removal|
        removal = removal.sub(%r{^/},'') # remove leading slash
        removal_path = "#{@project_root}/#{removal}"
        puts "  rm -rf #{removal_path}".colorize(:yellow) # uncomment to debug
        FileUtils.rm_rf(removal_path)
      end

      tidy_bundled
    end

    def removals
      removals = default_removals
      removals += get_removals("#{@project_root}/.gitignore")
      removals += get_removals("#{@project_root}/.dockerignore")
      removals = removals.reject do |p|
        jetskeep.find do |keep|
          p.include?(keep)
        end
      end
      removals
    end

    def get_removals(file)
      path = file
      return [] unless File.exist?(path)

      removal = File.read(path).split("\n")
      removal.map {|i| i.strip}.reject {|i| i =~ /^#/ || i.empty?}
      # IE: ["/handlers", "/bundled*", "/vendor/jets]
    end

    # We clean out ignored files pretty aggressively. So provide
    # a way for users to keep files from being cleaned ou.
    def jetskeep
      defaults = %w[.bundle bundled pack handlers]
      path = "#{@project_root}/.jetskeep"
      return defaults unless File.exist?(path)

      keep = IO.readlines(path)
      keep = keep.map {|i| i.strip}.reject { |i| i =~ /^#/ || i.empty? }
      (defaults + keep).uniq
    end

    # folders to remove in the bundled folder regardless of the level of the folder
    def tidy_bundled
      puts "check #{@project_root}/bundled/**/*"
      Dir.glob("#{@project_root}/bundled/**/*").each do |path|
        next unless File.directory?(path)
        dir = File.basename(path)
        next unless default_removals.include?(dir)
        puts "  rm -rf #{path}".colorize(:yellow) # uncomment to debug
        FileUtils.rm_rf(path)
      end
    end

    # These directories will be removed regardless of dir level
    def default_removals
      %w[.git tmp spec cache]
    end
  end
end
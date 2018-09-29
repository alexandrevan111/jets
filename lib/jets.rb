$:.unshift(File.expand_path("../", __FILE__))
require "jets/version"
require "jets/camelizer"
require "active_support/core_ext/string"
require "active_support/ordered_hash"
require "colorize"
require "fileutils"
require "memoist"

module Jets
  # When we update Jets::RUBY_VERSION, need to update lambdagem/base.rb: def jets_ruby_version also
  RUBY_VERSION = "2.5.0"

  autoload :Application, "jets/application"
  autoload :AwsInfo, "jets/aws_info"
  autoload :AwsServices, "jets/aws_services"
  autoload :Booter, 'jets/booter'
  autoload :Builders, 'jets/builders'
  autoload :Call, "jets/call"
  autoload :Cfn, 'jets/cfn'
  autoload :CLI, "jets/cli"
  autoload :Commands, "jets/commands"
  autoload :Controller, 'jets/controller'
  autoload :Core, "jets/core"
  autoload :Dotenv, 'jets/dotenv'
  autoload :Erb, "jets/erb"
  autoload :Generator, "jets/generator"
  autoload :IO, "jets/io"
  autoload :Job, 'jets/job'
  autoload :Klass, 'jets/klass'
  autoload :Lambda, 'jets/lambda'
  autoload :Logger, "jets/logger"
  autoload :Naming, 'jets/naming'
  autoload :PolyFun, 'jets/poly_fun'
  autoload :Preheat, "jets/preheat"
  autoload :Processors, 'jets/processors'
  autoload :Rack, "jets/rack"
  autoload :Rdoc, "jets/rdoc"
  autoload :Resource, "jets/resource"
  autoload :Route, "jets/route"
  autoload :Router, "jets/router"
  autoload :RubyServer, "jets/ruby_server"
  autoload :Rule, 'jets/rule'
  autoload :Server, "jets/server"
  autoload :Stack, "jets/stack"
  autoload :Timing, "jets/timing"
  autoload :Util, "jets/util"
  autoload :Inflections, "jets/inflections"

  extend Core # root, logger, etc
end

require "jets/core_ext/kernel"

$:.unshift(File.expand_path("../../vendor/lambdagem/lib", __FILE__))
require "lambdagem"
require "gems" # lambdagem dependency

# lazy loaded dependencies: depends what project. Mainly determined by Gemfile
# and config files.
if File.exist?("#{Jets.root}config/dynamodb.yml")
  $:.unshift(File.expand_path("../../vendor/dynomite/lib", __FILE__))
  require "dynomite"
end

# Thanks: https://makandracards.com/makandra/42521-detecting-if-a-ruby-gem-is-loaded
# TODO: move require "pg" into loader class and abstract to support more gems
if File.exist?("#{Jets.root}config/database.yml")
  require "active_record"
  # Note: think this is only needed for specs
  # Apps require pg in their own Gemfile via bundler
  exists = File.exist?("/var/task/bundled/gems/ruby/2.5.0/gems/pg-0.21.0/lib/pg_ext.so")
  # Jets.logger.info("pg_ext.so exists #{exists.inspect}")
  require "pg" if Gem.loaded_specs.has_key?('pg')
end

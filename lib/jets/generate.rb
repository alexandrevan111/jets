class Jets::Generate < Jets::Command
  autoload :Help, 'jets/generate/help'
  autoload :Migration, 'jets/generate/migration'
  autoload :Scaffold, 'jets/generate/scaffold'

  class_option :verbose, type: :boolean
  class_option :noop, type: :boolean

  desc "migration [name]", "Creates a migration for a DynamoDB table"
  long_desc Help.migration
  option :partition_key, default: "id:string:hash", desc: "table's partition key"
  option :sort_key, default: nil, desc: "table's sort key"
  option :namespace, default: nil, desc: "namespace that gets prepended to table names"
  def migration(name)
    Migration.new(name, options).create
  end

  desc "scaffold [name]", "Creates a CRUD scaffold"
  long_desc Help.scaffold
  def scaffold(name)
    Scaffold.new(name, options).create
  end
end

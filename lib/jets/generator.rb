# Piggy back off of Rails Generators.
class Jets::Generator
  include Jets::Invoker

  def invoke
    # lazy require so Rails const is only defined when using generators
    require "rails/generators"
    require "rails/configuration"
    Rails::Generators.configure!(config)
    Rails::Generators.invoke(@generator, @args, behavior: :invoke, destination_root: Jets.root)
  end
end

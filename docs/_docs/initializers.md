---
title: Initializers
nav_order: 48
---

Jets supports custom initalization by running your app's `config/initalizers` files during the bootup process.

## Common Initializers

Common initializers always get run and go in the `config/initializers` folder. Here's an example:

config/initializers/custom.rb:

```ruby
Jets.application.config.silly = ActiveSupport::OrderedOptions.new
Jets.application.config.silly.name = "FooBar"
```

## Environment Initializers

Jets supports environment specific initializers also. Examples:

config/environments/development.rb:

```ruby
Jets.application.configure do
  config.function.memory_size = 1536
end
```

config/environments/production.rb:

```ruby
Jets.application.configure do
  config.function.memory_size = 2048
end
```

{% include prev_next.md %}
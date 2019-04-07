---
title: Associated Resources Extensions
nav_order: 56
---

You can define your own custom associated resource methods. This helps for shorter and cleaner code. Remember that methods like `cron` and `rate` are just convenience methods that ultimately call the `resource` method. You can extend Jets with custom convenience methods.

## Example Extension

To define a custom extension, you create a module in the `app/extensions` folder.  Here's an example:

app/extensions/iot_extension.rb:

```ruby
module IotExtension
  def thermostat_rule(logical_id, props={})
    defaults = {
      topic_rule_payload: {
        sql: "select * from TemperatureTopic where temperature > 60"
      },
      actions: [
        lambda: { function_arn: "!Ref {namespace}LambdaFunction" }
      ]
    }
    props = defaults.deep_merge(props)
    resource(logical_id, "AWS::Iot::TopicRule", props)
  end
end
```

After the module is defined, you can use the newly created convenience method like so:

```ruby
class TemperatureJob < ApplicationJob
  thermostat_rule(:room)
  def record
    # custom business logic
  end
end
```

The code above creates an `AWS::Iot::TopicRule` and runs the `record` Lambda function for incoming IoT thermostat data.  You can add your own custom business logic to handle the received data accordingly.

## Three Resource Forms

You might have noticed that the `thermostat_rule extension` used a different form of the `resource` method. There are 3 different forms of the `resource` method. Here are examples of each:

### Resource Long Form

```ruby
def thermostat_rule(logical_id, props={})
  # ...
  resource(
    logical_id : {
      type: "AWS::Iot::TopicRule",
      properties: props
    }
  )
end
```

### Resource Medium Form

```ruby
def thermostat_rule(logical_id, props={})
  # ...
  resource(logical_id,
    type: "AWS::Iot::TopicRule",
    properties: props
  )
end
```

### Resource Short Form

```ruby
def thermostat_rule(logical_id, props={})
  # ...
  resource(logical_id, "AWS::Iot::TopicRule", props)
end
```

### Which one to use?

You can use any of the resource forms depending on how much customization and control is needed.  It is probably best to try the simplest form first and then go up your way to the long form when needed.

{% include prev_next.md %}
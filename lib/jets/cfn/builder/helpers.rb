class Jets::Cfn::Builder
  module Helpers
    def compose
      # meant to be overridden by the concrete class
    end

    def compose!
      compose
      write
    end

    def template
      @template
    end

    def text
      text = YAML.dump(@template.to_hash)
      post_process_template(text)
    end

    # post process the text so that
    # "!Ref IamRole" => !Ref IamRole
    # We strip the surrounding quotes
    def post_process_template(text)
      results = text.split("\n").map do |line|
        if line.include?(': "!') # IE: IamRole: "!Ref IamRole",
           # IamRole: "!Ref IamRole" => IamRole: !Ref IamRole
          line.sub(/: "(.*)"/, ': \1')
        else
          line
        end
      end
      results.join("\n") + "\n"
    end

    def add_resource(logical_id, type, properties)
      options = {
        Type: type,
        Properties: properties
      }
      depends_on = properties.delete(:DependsOn)
      options[:DependsOn] = depends_on if depends_on

      @template[:Resources][logical_id] = options
    end

    def add_parameter(name, options={})
      defaults = { Type: "String" }
      options = defaults.merge(options)
      @template[:Parameters] ||= {}
      @template[:Parameters][name.camelize] = options
    end

    def add_output(name, options={})
      defaults = { Type: "String" }
      options = defaults.merge(options)
      @template[:Outputs] ||= {}
      @template[:Outputs][name.camelize] = options
    end
  end
end
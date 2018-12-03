class Jets::Resource::ApiGateway::RestApi
  class ChangeDetection
    extend Memoist
    include Jets::AwsServices

    def changed?
      return false unless parent_stack_exists?
      current_binary_media_types != new_binary_media_types ||
      Routes.changed?
    end

    def new_binary_media_types
      rest_api = Jets::Resource::ApiGateway::RestApi.new
      rest_api.binary_media_types
    end
    memoize :new_binary_media_types

    # Duplicated in rest_api/change_detection.rb, base_path/role.rb, rest_api/routes.rb
    def current_binary_media_types
      return nil unless parent_stack_exists?

      stack = cfn.describe_stacks(stack_name: parent_stack_name).stacks.first

      api_gateway_stack_arn = lookup(stack[:outputs], "ApiGateway")

      stack = cfn.describe_stacks(stack_name: api_gateway_stack_arn).stacks.first
      rest_api_id = lookup(stack[:outputs], "RestApi")

      resp = apigateway.get_rest_api(rest_api_id: rest_api_id)
      resp.binary_media_types
    end
    memoize :current_binary_media_types

    def parent_stack_exists?
      stack_exists?(parent_stack_name)
    end

    def parent_stack_name
      Jets::Naming.parent_stack_name
    end
  end
end

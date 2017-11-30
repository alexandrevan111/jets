class Jets::Cfn::TemplateMappers
  class ControllerMapper < ChildMapper
    # Parameters that are common to all controller stacks
    def parameters
      parameters = super
      return parameters if Jets::Router.routes.empty?

      # Add the API Gateway parameters
      parameters[:RestApi] = "!GetAtt ApiGateway.Outputs.RestApi"
      scoped_routes.each do |route|
        map = GatewayResourceMapper.new(route)
        parameters[map.logical_id] = "!GetAtt ApiGateway.Outputs.#{map.logical_id}"
      end

      parameters
    end

    def scoped_routes
      return @routes if @routes

      @routes = Jets::Router.routes.select do |route|
        puts "need to figure out how to get app_class from path"
        puts "path #{@path}"
        puts "route.controller_name: #{route.controller_name.inspect}"
        puts "current_class: #{current_class.inspect}"
        route.controller_name == current_class
      end

      puts "controller_mapper.rb: #{@routes.map(&:to).inspect}"
      @routes
    end

      # Example:
      #   1. demo-stag-admin-related_pages_controller.yml
      #   2. admin/posts_controller
      #   3. Admin::PostsController
    def current_class
      templates_prefix = "#{Jets::Naming.template_path_prefix}-"
      @path.sub(templates_prefix, '')
        .sub(/\.yml$/,'')
        .gsub('-','/')
        .classify
    end
  end
end

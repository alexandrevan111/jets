module Jets::Resource::ApiGateway
  class Resource < Jets::Resource::Base
    def initialize(path)
      @path = path # Examples: "posts/:id/edit" or "posts"
      super() # super initializer takes no arguments
    end

    def definition
      logical_id = @path == '' ?
        "RootResourceId" : # homepage
        "#{path_logical_id(@path)}ApiResource"
      {
        logical_id => {
          type: "AWS::ApiGateway::Resource",
          properties: {
            parent_id: parent_id,
            path_part: path_part,
            rest_api_id: "!Ref RestApi",
          }
        }
      }
    end

    def outputs
      {
        logical_id => "!Ref #{logical_id}",
      }
    end

    def parent_id
      if @path.include?('/') # posts/:id or posts/:id/edit
        parent_path = @path.split('/')[0..-2].join('/')
        parent_logical_id = path_logical_id(parent_path)
        "!Ref #{parent_logical_id}ApiResource"
      else
        "!GetAtt RestApi.RootResourceId"
      end
    end

    def path_part
      last_part = path.split('/').last
      last_part.split('/').map {|s| transform_capture(s) }.join('/')
    end

    # Modify the path to conform to API Gateway capture expressions
    def path
      @path.split('/').map {|s| transform_capture(s) }.join('/')
    end

    def transform_capture(text)
      if text.starts_with?(':')
        text = text.sub(':','')
        text = "{#{text}}" # :foo => {foo}
      end
      if text.starts_with?('*')
        text = text.sub('*','')
        text = "{#{text}+}" # *foo => {foo+}
      end
      text
    end

    # For parameter description
    def desc
      path.empty? ? 'Homepage route: /' : "Route for: /#{path}"
    end

  private
    # Similar path_logical_id method in resource/route.rb
    def path_logical_id(path)
      path.gsub('/','_').gsub(':','').gsub('*','').camelize
    end
  end
end

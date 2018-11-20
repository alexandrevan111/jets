require 'rack'

# Takes an ApiGateway event and converts it to an Rack env that can be used for
# rack.call(env).
module Jets::Controller::Rack
  class Env
    def initialize(event, context)
      @event, @context = event, context
    end

    def convert
      options = {}
      options = add_top_level(options)
      options = add_http_headers(options)
      path = @event['path'] || '/' # always set by API Gateway but might not be when testing shim, so setting it to make testing easier
      Rack::MockRequest.env_for(path, options)
    end

  private
    def add_top_level(options)
      map = {
        'CONTENT_TYPE' => content_type,
        'QUERY_STRING' => query_string,
        'REMOTE_ADDR' => headers['X-Forwarded-For'],
        'REMOTE_HOST' => headers['Host'],
        'REQUEST_METHOD' => @event['httpMethod'],
        'REQUEST_PATH' => @event['path'],
        'REQUEST_URI' => request_uri,
        'SCRIPT_NAME' => "",
        'SERVER_NAME' => headers['Host'],
        'SERVER_PORT' => headers['X-Forwarded-Port'],
        'SERVER_PROTOCOL' => "HTTP/1.1",  # unsure if this should be set
        'SERVER_SOFTWARE' => "WEBrick/1.3.1 (Ruby/2.2.2/2015-04-13)",
      }

      map['CONTENT_LENGTH'] = content_length if content_length
      # Even if not set, Rack always assigns an StringIO to "rack.input"
      map[:input] = StringIO.new(body) if body

      # TODO: handle decoding base64 encoded body from API Gateaway
      # Will need to make sure that pass the base64 info via a request header

      options.merge(map)
    end

    def content_type
      headers['Content-Type'] || Jets::Controller::DEFAULT_CONTENT_TYPE
    end

    def content_length
      bytesize = body.bytesize.to_s if body
      headers['Content-Length'] || bytesize
    end

    def body
      @event['body']
    end

    def add_http_headers(options)
      headers.each do |k,v|
        # content-type => HTTP_CONTENT_TYPE
        key = k.gsub('-','_').upcase
        key = "HTTP_#{key}"
        options[key] = v
      end
      options
    end

    def request_uri
      # IE: "http://localhost:8888/posts/tung/edit?foo=bar"
      proto = headers['X-Forwarded-Proto']
      host = headers['Host']
      port = headers['X-Forwarded-Port']

      # Add port if needed
      if proto == 'https' && port != '443' or
         proto == 'http'  && port != '80'
        host = "#{host}:#{port}"
      end

      path = @event['path']
      qs = "?#{query_string}" unless query_string.empty?
      "#{proto}://#{host}#{path}#{qs}"
    end

    def query_string
      qs_params = @event["queryStringParameters"] || {} # always set with API Gateway but when testing node shim might not be
      hash = Jets::Mega::HashConverter.encode(qs_params)
      hash.to_query
    end

    def headers
      @event['headers'] || {}
    end
  end
end

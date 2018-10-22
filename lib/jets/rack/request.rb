require 'net/http'

module Jets::Rack
  class Request
    def initialize(event, controller)
      @event = event
      @controller = controller # Jets::Controller instance
      # local rack server settings
      @host = 'localhost'
      @port = 9292
    end

    def process
      request = @controller.request

      puts "ENV:"
      puts ENV

      uri = URI("http://#{@host}:#{@port}#{request.path}")
      params = @controller.params(raw: true, path_parameters: false)
      uri.query = URI.encode_www_form(params)

      # Looks like get_response is smart enough to send POST request when needed.
      # Thanks: https://docs.ruby-lang.org/en/2.0.0/Net/HTTP.html
      resp = Net::HTTP.get_response(uri)
      # puts resp.body
      {
        status: resp.code.to_i,
        headers: resp.each_header.to_h,
        body: resp.body,
      }
      # TODO: handle binary
    end
  end
end

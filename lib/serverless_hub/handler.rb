ActiveSupport::Dependencies.autoload_paths += Dir[ "#{ENV["LAMBDA_TASK_ROOT"]}/app/**" ]

class DefaultApiEntry
  def self.call(env)
    status  = 200
    headers = { "Content-Type" => "text/html" }
    body    = ['Hello World.']

    [status, headers, body]
  end
end

module ServerlessHub
  module Handler
    $app ||= Rack::Builder.new do
      app = begin
              Kernel.const_get(ENV.fetch('API_ENTRY_CLASS_NAME', 'ApiEntry'))
            rescue
              DefaultApiEntry
            end

      use AuthorizerTokenDecoder
      use Authorizer
      run app
    end.to_app
    
    def self.call(event:, context:)
      return "Warm Up" if event["source"] == "serverless-plugin-warmup"
      
        Lamby.handler $app, event, context, rack: :api
    rescue Exception => msg
      p "errors: #{msg}"
      response = {
        "statusCode" => 500,
        "body" => ENV["RAILS_ENV"] == "production" ? "Something wrong happened" : msg,
      }
    end
  end
end

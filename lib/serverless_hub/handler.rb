require 'rails'
require 'lamby'

module ServerlessHub
  module Handler
    $app ||= Rack::Builder.new do
      app = Proc.new do |env|
        ['200', {'Content-Type' => 'text/html'}, ['A barebones rack app.']]
      end
      run app
    end.to_app
    
    def self.call(event:, context:)
        return "Warm Up" if event["source"] == "serverless-plugin-warmup"
    
        Lamby.handler $app, event, context
    end
  end
end

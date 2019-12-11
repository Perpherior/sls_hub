require "jwt"
require "json/jwt"
require "rest-client"

module ServerlessHub
  class AuthorizerTokenDecoder
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["HTTP_AUTHORIZATION"]
        tokens = decoded_token(env["HTTP_AUTHORIZATION"])

        if tokens.present?
          claims = tokens[0]

          env["lambda.event"]["requestContext"]["authorizer"] = {
            "principalId" => claims["sub"],
            "claims" => claims,
          }
        end
      end

      return @app.call(env)
    end

    def self.jwks
      RestClient.get(ENV["JWKS_URL"] || "")
    end

    private

    def decoded_token(token)
      token = token.split(" ").last
      JWT.decode token, jwk_set.first.to_key, true, { algorithm: "RS256" } rescue ""
    end

    def jwk_set
      @jwk_set ||= JSON::JWK::Set.new(
        JSON.parse(
          AuthorizerTokenDecoder.jwks
        )
      )
    end
  end

  class Authorizer
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["lambda.event"] && env["lambda.event"]["requestContext"]
        env["authorizer"] = env["lambda.event"]["requestContext"]["authorizer"]
      end

      return @app.call(env)
    end
  end
end

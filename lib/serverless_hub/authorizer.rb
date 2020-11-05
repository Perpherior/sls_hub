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
      token = token.strip
      if token.include? ' '
        token = token.split(" ").last
      end
      decoded = JWT.decode token, jwk_set.first.to_key, false, { algorithm: "RS256" }
      key_id = decoded[1]['kid']
      key = jwk_set.find { |key_obj| key_obj['kid'] == key_id }
      if key == nil
        return ""
      end
      JWT.decode token, key.to_key, true, { algorithm: "RS256" } rescue ""
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

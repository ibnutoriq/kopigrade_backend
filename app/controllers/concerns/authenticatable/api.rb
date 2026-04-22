module Authenticatable
  module Api
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_api_client!
    end

    private

    def authenticate_api_client!
      token = extract_bearer_token
      client = token && ApiClient.authenticate(token)

      if client
        client.touch_last_used!
        Current.api_client = client
      else
        render json: { error: I18n.t("api.errors.unauthorized") }, status: :unauthorized
      end
    end

    def extract_bearer_token
      header = request.headers["Authorization"].to_s
      header.start_with?("Bearer ") ? header.delete_prefix("Bearer ").strip : nil
    end
  end
end

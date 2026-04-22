class Api::V1::BaseController < ActionController::API
  include Authenticatable::Api
  include AbstractController::Translation

  before_action :set_locale

  # rescue_from handlers are checked in REVERSE definition order — most specific last.
  rescue_from StandardError do |e|
    Rails.logger.error("API error: #{e.class}: #{e.message}\n#{e.backtrace.first(10).join("\n")}")
    render json: { error: t("api.errors.internal_server_error") }, status: :internal_server_error
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :bad_request
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def set_locale
    locale = extract_locale_from_header
    I18n.locale = locale if I18n.available_locales.include?(locale)
  end

  def extract_locale_from_header
    header = request.headers["Accept-Language"].to_s
    return I18n.default_locale if header.blank?
    # Accept-Language examples: "id", "id-ID,id;q=0.9,en;q=0.8"
    primary_tag = header.split(",").first.to_s.split(";").first.to_s.strip
    primary_tag.split("-").first.to_sym
  end
end

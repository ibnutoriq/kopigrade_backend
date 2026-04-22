class Web::BaseController < ApplicationController
  layout "web"
  allow_unauthenticated_access

  before_action :force_indonesian_locale

  private

  def force_indonesian_locale
    I18n.locale = :id
  end
end

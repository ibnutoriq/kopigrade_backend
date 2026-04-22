class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :api_client
  delegate :user, to: :session, allow_nil: true
end

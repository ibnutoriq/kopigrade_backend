module Web
  module ScansHelper
    PENDING_TIMEOUT_SECONDS = 90

    def scan_pending_too_long?(scan)
      Time.current - scan.created_at > PENDING_TIMEOUT_SECONDS
    end
  end
end

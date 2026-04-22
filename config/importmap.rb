# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# chartkick and Chart.bundle.js are loaded as plain scripts in the admin layout,
# not through importmap — chartkick auto-detects window.Chart when loaded in order.

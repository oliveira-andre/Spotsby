# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@stimulus-components/reveal", to: "https://ga.jspm.io/npm:@stimulus-components/reveal@5.0.0/dist/stimulus-reveal-controller.mjs"
pin "sortablejs", to: "https://ga.jspm.io/npm:sortablejs@1.15.6/modular/sortable.esm.js"
pin_all_from "app/javascript/controllers", under: "controllers"

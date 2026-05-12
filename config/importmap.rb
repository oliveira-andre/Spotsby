# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@stimulus-components/reveal", to: "https://ga.jspm.io/npm:@stimulus-components/reveal@5.0.0/dist/stimulus-reveal-controller.mjs"
pin "@stimulus-components/clipboard", to: "https://ga.jspm.io/npm:@stimulus-components/clipboard@5.0.0/dist/stimulus-clipboard.mjs"
pin "@stimulus-components/color-picker", to: "https://ga.jspm.io/npm:@stimulus-components/color-picker@2.0.0/dist/stimulus-color-picker.mjs"
pin "stimulus-textarea-autogrow", to: "https://ga.jspm.io/npm:stimulus-textarea-autogrow@4.1.0/dist/stimulus-textarea-autogrow.mjs"
pin "@simonwep/pickr", to: "https://ga.jspm.io/npm:@simonwep/pickr@1.9.0/dist/pickr.min.js"
pin "sortablejs", to: "https://ga.jspm.io/npm:sortablejs@1.15.6/modular/sortable.esm.js"
pin_all_from "app/javascript/controllers", under: "controllers"

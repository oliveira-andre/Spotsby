import { Application } from "@hotwired/stimulus"
import Reveal from "@stimulus-components/reveal"

const application = Application.start()
application.register("reveal", Reveal)

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }

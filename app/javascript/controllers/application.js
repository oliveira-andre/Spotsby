import { Application } from "@hotwired/stimulus"
import Reveal from "@stimulus-components/reveal"
import TextareaAutogrow from "stimulus-textarea-autogrow"

const application = Application.start()
application.register("reveal", Reveal)
application.register("textarea-autogrow", TextareaAutogrow)

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }

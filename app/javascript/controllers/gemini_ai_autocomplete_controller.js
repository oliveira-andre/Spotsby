import { Controller } from "@hotwired/stimulus"

const TEMPERATURE = 0.7
const TOP_K = 8

export default class extends Controller {
  static targets = [
    "nameInput",
    "descriptionField", "descriptionButton",
    "releaseDateField", "releaseDateButton",
    "categoryField", "categoryButton",
    "ageField", "ageButton",
    "listenersField", "listenersButton",
    "lyricsField", "lyricsButton"
  ]

  static values = {
    authorName: String,
    albumName: String,
    categories: Array
  }

  async connect() {
    this.busy = false

    if (!("LanguageModel" in self)) {
      this.#hideButtons()
      return
    }

    try {
      const availability = await LanguageModel.availability()
      if (availability === "unavailable") {
        this.#hideButtons()
        return
      }
    } catch {
      this.#hideButtons()
      return
    }

    if (this.hasNameInputTarget) {
      this.nameInputTarget.addEventListener("input", () => this.#refreshButtons())
    }
    this.#refreshButtons()
  }

  async fillDescription(event) {
    event.preventDefault()
    const author = this.#name()
    if (!author) return

    const prompt = `Write a short, factual biography for the music artist "${author}". 2-3 sentences. Plain text only, no markdown, no headings.`
    await this.#stream(this.descriptionFieldTarget, prompt, this.descriptionButtonTarget)
  }

  async fillReleaseDate(event) {
    event.preventDefault()
    const album = this.#name()
    const author = this.authorNameValue
    if (!album || !author) return

    const prompt = `What is the original release date of the album "${album}" by "${author}"? Reply only with a single date in YYYY-MM-DD format. If unsure, give your best estimate. No other text.`
    const text = await this.#prompt(prompt, this.releaseDateButtonTarget)
    const match = text && text.match(/\d{4}-\d{2}-\d{2}/)
    if (match) this.#setValue(this.releaseDateFieldTarget, match[0])
  }

  async fillCategory(event) {
    event.preventDefault()
    const song = this.#name()
    const album = this.albumNameValue
    const author = this.authorNameValue
    if (!song || !album || !author) return

    const categories = this.categoriesValue
    const names = categories.map(c => c[0])
    const prompt = `Pick the most fitting music genre for the song "${song}" from the album "${album}" by "${author}". Choose ONE option exactly as written from this list: ${names.join(", ")}. Reply with ONLY the chosen genre name, nothing else.`

    const text = await this.#prompt(prompt, this.categoryButtonTarget)
    if (!text) return

    const cleaned = text.trim().toLowerCase()
    const match =
      categories.find(c => c[0].toLowerCase() === cleaned) ||
      categories.find(c => cleaned.includes(c[0].toLowerCase())) ||
      categories.find(c => c[0].toLowerCase().includes(cleaned))
    if (match) this.#setValue(this.categoryFieldTarget, match[1])
  }

  async fillAge(event) {
    event.preventDefault()
    const song = this.#name()
    const album = this.albumNameValue
    const author = this.authorNameValue
    if (!song || !album || !author) return

    const prompt = `What is a reasonable minimum age rating for the song "${song}" from the album "${album}" by "${author}"? Consider explicit lyrics and themes. Reply with only a single integer like 0, 13, 16, or 18. No other text.`
    const text = await this.#prompt(prompt, this.ageButtonTarget)
    const match = text && text.match(/\d+/)
    if (match) this.#setValue(this.ageFieldTarget, parseInt(match[0], 10))
  }

  async fillListeners(event) {
    event.preventDefault()
    const song = this.#name()
    const album = this.albumNameValue
    const author = this.authorNameValue
    if (!song || !album || !author) return

    const prompt = `Estimate the monthly listeners on a streaming platform for the song "${song}" from the album "${album}" by "${author}". Reply with a single integer only — no commas, no words, no thousand separators.`
    const text = await this.#prompt(prompt, this.listenersButtonTarget)
    const match = text && text.replace(/[,\s]/g, "").match(/\d+/)
    if (match) this.#setValue(this.listenersFieldTarget, parseInt(match[0], 10))
  }

  async fillLyrics(event) {
    event.preventDefault()
    const song = this.#name()
    const album = this.albumNameValue
    const author = this.authorNameValue
    if (!song || !album || !author) return

    const prompt = `Write original song lyrics inspired by the style of "${author}" for a song titled "${song}" from the album "${album}". Include verses and a chorus. Plain text only, no markdown, no commentary, no title heading.`
    await this.#stream(this.lyricsFieldTarget, prompt, this.lyricsButtonTarget)
  }

  #name() {
    return this.hasNameInputTarget ? this.nameInputTarget.value.trim() : ""
  }

  #allButtons() {
    return [
      ...this.descriptionButtonTargets,
      ...this.releaseDateButtonTargets,
      ...this.categoryButtonTargets,
      ...this.ageButtonTargets,
      ...this.listenersButtonTargets,
      ...this.lyricsButtonTargets
    ]
  }

  #hideButtons() {
    this.#allButtons().forEach(b => { b.hidden = true })
  }

  #refreshButtons() {
    if (this.busy) return

    const name = this.#name()
    const author = this.authorNameValue
    const album = this.albumNameValue

    this.descriptionButtonTargets.forEach(b => { b.disabled = !name })
    this.releaseDateButtonTargets.forEach(b => { b.disabled = !name || !author })

    const songReady = !!(name && album && author)
    this.categoryButtonTargets.forEach(b => { b.disabled = !songReady })
    this.ageButtonTargets.forEach(b => { b.disabled = !songReady })
    this.listenersButtonTargets.forEach(b => { b.disabled = !songReady })
    this.lyricsButtonTargets.forEach(b => { b.disabled = !songReady })
  }

  #setValue(field, value) {
    field.value = value
    field.dispatchEvent(new Event("input", { bubbles: true }))
    field.dispatchEvent(new Event("change", { bubbles: true }))
  }

  #setBusy(busy, activeButton) {
    this.busy = busy
    if (busy) {
      this.#allButtons().forEach(b => { b.disabled = true })
      activeButton?.classList.add("ai-button--busy")
    } else {
      this.#allButtons().forEach(b => b.classList.remove("ai-button--busy"))
      this.#refreshButtons()
    }
  }

  async #createSession() {
    return await LanguageModel.create({
      expectedInputLanguages: ["en"],
      temperature: TEMPERATURE,
      topK: TOP_K
    })
  }

  async #prompt(prompt, button) {
    if (this.busy) return null
    this.#setBusy(true, button)
    let session
    try {
      session = await this.#createSession()
      return await session.prompt(prompt)
    } catch (e) {
      console.error("AI generation failed", e)
      return null
    } finally {
      session?.destroy()
      this.#setBusy(false, button)
    }
  }

  async #stream(field, prompt, button) {
    if (this.busy) return
    this.#setBusy(true, button)
    field.value = ""
    field.dispatchEvent(new Event("input", { bubbles: true }))

    let session
    try {
      session = await this.#createSession()
      const stream = await session.promptStreaming(prompt)
      for await (const chunk of stream) {
        field.value += chunk
        field.dispatchEvent(new Event("input", { bubbles: true }))
      }
    } catch (e) {
      console.error("AI generation failed", e)
    } finally {
      session?.destroy()
      this.#setBusy(false, button)
    }
  }
}

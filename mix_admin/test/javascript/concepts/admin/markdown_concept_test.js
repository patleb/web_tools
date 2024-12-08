import concepts from './../spec_helper'

let concept = null
let textarea = null
let undo = null
let redo = null

describe('Js.Admin.MarkdownConcept', () => {
  concepts.with_page('admin/markdown', false)

  beforeEach(() => {
    concept = Js.Admin.MarkdownConcept
    textarea = dom.find('.js_markdown')
    undo = dom.find('.js_markdown_toolbar .undo')
    redo = dom.find('.js_markdown_toolbar .redo')
  })

  test('#push_history, #undo_history, #redo_history', () => {
    assert.equal('text', textarea.get_value())
    assert.equal({ push: ['text'], redo: [], undo: [] }, concept.get_history(textarea))

    undo.click()
    assert.equal({ push: ['text'], redo: [], undo: [] }, concept.get_history(textarea))

    redo.click()
    assert.equal({ push: ['text'], undo: [], redo: [] }, concept.get_history(textarea))

    textarea.set_value('new text', { event: true })
    assert.equal({ 'page_fields_html[text_fr]': { push: ['new text'], redo: [], undo: ['text', 'new text'] } }, concept.history)

    textarea.set_value('new text', { event: true })
    assert.equal({ 'page_fields_html[text_fr]': { push: ['new text'], redo: [], undo: ['text', 'new text'] } }, concept.history)

    textarea.set_value('changed text', { event: true })
    assert.equal({ 'page_fields_html[text_fr]': { push: ['changed text'], redo: [], undo: ['text', 'new text', 'changed text'] } }, concept.history)

    undo.click()
    assert.equal({ 'page_fields_html[text_fr]': { push: ['new text'], redo: ['changed text'], undo: ['text'] } }, concept.history)

    redo.click()
    assert.equal({ 'page_fields_html[text_fr]': { push: ['changed text'], redo: [], undo: ['text', 'new text'] } }, concept.history)
  })
})

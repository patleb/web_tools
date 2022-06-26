import './spec_helper'

describe('I18n', () => {
  beforeAll(() => {
    I18n.translations = {
      fr: {
        name: 'Le nom',
        html: '<div>Escape</div>',
        var: 'Hello %{name}!'
      },
      en: {
        name: 'The name'
      },
    }
    dom.setup_document(fixture.html('i18n', { root: 'ext_coffee/test/fixtures/files/core_ext' }))
    dom.fire('turbolinks:load')
  })

  it('should set the locale and add js_i18n data-translations elements', () => {
    assert.equal('fr', I18n.default_locale)
    assert.equal('fr', I18n.locale)
    assert.equal('Chien', I18n.t('dog'))
  })

  it('should prefer lang attribute locale, use the locale option or use the key if missing', () => {
    assert.equal('Le nom', I18n.t('name'))
    assert.equal('The name', I18n.t('name', { locale: 'en' }))
    assert.equal('Deep nested name', I18n.t('deep.nested.name', { locale: 'it' }))
  })

  it('should not mark as html_safe if escape option is not false', () => {
    assert.false(I18n.t('html').html_safe())
    assert.true(I18n.t('html', { escape: false }).html_safe())
  })

  it('should interpolate variables', () => {
    assert.equal('Hello John!', I18n.t('var', { name: 'John' }))
  })

  it('should use the contextual locale', () => {
    I18n.with_locale('en', () => {
      assert.equal('The name', I18n.t('name'))
    })
  })
})

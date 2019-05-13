#= require mocha/2.3.3
#= require teaspoon/mocha

# Teaspoon includes some support files, but you can use anything from your own support path too.
# require support/expect
#= require support/sinon
#= require support/chai
# require support/chai-jq-0.0.7
# require support/your-support-file
#= require_self
#
# PhantomJS (Teaspoons default driver) doesn't have support for Function.prototype.bind, which has caused confusion.
# Use this polyfill to avoid the confusion.
# require support/phantomjs-shims
#
# You can require your own javascript files here. By default this will include everything in application, however you
# may get better load performance if you require the specific files that are being used in the spec that tests them.
# require application
#
# Deferring execution
# If you're using CommonJS, RequireJS or some other asynchronous library you can defer execution. Call
# Teaspoon.execute() after everything has been loaded. Simple example of a timeout:
#
# Teaspoon.defer = true
# setTimeout(Teaspoon.execute, 1000)
#
# Matching files
# By default Teaspoon will look for files that match _spec.{js,js.coffee,.coffee}. Add a filename_spec.js file in your
# spec path and it'll be included in the default suite automatically. If you want to customize suites, check out the
# configuration in teaspoon_env.rb
#
# Manifest
# If you'd rather require your spec files manually (to control order for instance) you can disable the suite matcher in
# the configuration and use this file as a manifest.
#
# For more information: http://github.com/modeset/teaspoon
#
# Chai
# If you're using Chai, you'll probably want to initialize your preferred assertion style. You can read more about Chai
# at: http://chaijs.com/guide/styles
#
window.assert = chai.assert
# window.expect = chai.expect
# window.should = chai.should()
window.support = {}

old_equal = assert.equal
assert.equal = (exp, act, msg) ->
  old_equal(act, exp, msg)

old_notEqual = assert.notEqual
assert.notEqual = (exp, act, msg) ->
  old_notEqual(act, exp, msg)

old_strictEqual = assert.strictEqual
assert.strictEqual = (exp, act, msg) ->
  old_strictEqual(act, exp, msg)

old_notStrictEqual = assert.notStrictEqual
assert.notStrictEqual = (exp, act, msg) ->
  old_notStrictEqual(act, exp, msg)

old_deepEqual = assert.deepEqual
assert.deepEqual = (exp, act, msg) ->
  old_deepEqual(act, exp, msg)

old_notDeepEqual = assert.notDeepEqual
assert.notDeepEqual = (exp, act, msg) ->
  old_notDeepEqual(act, exp, msg)

old_fail = assert.fail
assert.fail = (expected, actual, message, operator) ->
  old_fail(actual, expected, message, operator)

afterEach 'log errors', (done) ->
  if (test = this.currentTest).state == 'failed'
    console.error test.err.stack.split("\n").first(6).join("\n")
  done()

window.assert.conceptConstants = (concept) ->
  concept.CONSTANTS.each (name, value) ->
    if value.match(/^[#.]js_[a-z][a-z0-9_]*$/)
      assert.notEqual 0, $(value).length, value
    else if value.match(/^js_[a-z][a-z0-9_]*$/)
      assert.notEqual 0, $("[id^='#{value}'], [class*='#{value}']").length, value

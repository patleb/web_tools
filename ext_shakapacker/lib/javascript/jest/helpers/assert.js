const matchers = require('jest-extended')

expect.extend(matchers)

let not = false

const expect_with_not = (act) => {
  const handler = not ? expect(act).not : expect(act)
  not = false
  return handler
}

const assert = {
  get not() {
    not = true
    return assert
  },
  total: (n) => expect.assertions(n),
  true: (act) => expect_with_not(act).toBeTrue(),
  false: (act) => expect_with_not(act).toBeFalse(),
  same: (exp, act) => assert.true(Object.is(exp, act)),
  equal: (exp, act) => (typeof exp === 'object') ? expect_with_not(act).toStrictEqual(exp) : expect_with_not(act).toBe(exp),
  deep_equal: (exp, act) => assert.equal(JSON.stringify(exp), JSON.stringify(act)),
  html_equal: (exp, act) => expect_with_not(act).toEqualIgnoringWhitespace(exp),
  nan: (act) => expect_with_not(act).toBeNaN(),
  nil: (act) => expect_with_not(act).toBeNil(),
  null: (act) => expect_with_not(act).toBeNull(),
  undefined: (act) => expect_with_not(act).toBeUndefined(),
  empty: (act) => expect_with_not(act).toBeEmpty(),
  includes: (exp, act) => expect_with_not(act).toInclude(exp),
  excludes: (exp, act) => expect_with_not(act).not.toInclude(exp),
  called: (act, n = null) => n == null ? expect_with_not(act).toBeCalled() : expect_with_not(act).toBeCalledTimes(n),
  raise: (error, handler) => expect_with_not(handler).toThrow(error),
}
global.assert = assert

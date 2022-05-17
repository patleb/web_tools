const assert = {
  true: (act) => expect(act).toBeTrue(),
  false: (act) => expect(act).toBeFalse(),
  same: (exp, act) => expect(exp === act).toBe(true),
  not_same: (exp, act) => expect(exp === act).not.toBe(true),
  equal: (exp, act) => (typeof exp === 'object') ? expect(act).toStrictEqual(exp) : expect(act).toBe(exp),
  not_equal: (exp, act) => (typeof exp === 'object') ? expect(act).not.toStrictEqual(exp) : expect(act).not.toBe(exp),
  null: (act) => expect(act).toBeNil(),
  not_null: (act) => expect(act).not.toBeNil(),
  empty: (act) => expect(act).toBeEmpty(),
  not_empty: (act) => expect(act).not.toBeEmpty(),
  called: (act, n = null) => n == null ? expect(act).toBeCalled() : expect(act).toBeCalledTimes(n),
  total: (n) => expect.assertions(n),
}
global.assert = assert

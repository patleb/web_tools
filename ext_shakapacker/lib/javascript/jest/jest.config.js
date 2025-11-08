process.env.TZ = 'GMT'

module.exports = {
  testEnvironment: 'jsdom',
  roots: [
    'test/javascript',
  ],
  moduleDirectories: [
    'node_modules',
  ],
  moduleNameMapper: {
    '^@@/(.+)':              '<rootDir>/app/javascript/$1',
    '^@@lib/(.+)':           '<rootDir>/app/javascript/lib/$1',
    '^@@vendor/(.+)':        '<rootDir>/app/javascript/vendor/$1',
    '^@@test/fixtures/(.+)': '<rootDir>/test/fixtures/$1',
    '^@@test/(.+)':          '<rootDir>/test/javascript/$1',
  },
  moduleFileExtensions: [
    'js',
    'json',
    'coffee',
  ],
  testRegex: '_test\\.js$',
  transform: {
    '\\.js$': 'babel-jest',
    '\\.coffee$': './app/javascript/lib/ext_shakapacker/jest/jest_preprocessor.js',
  },
  preset: './app/javascript/lib/ext_shakapacker/jest/jest_preset.js',
  setupFilesAfterEnv: [
    './app/javascript/lib/ext_shakapacker/jest/jest_setup.js'
  ],
  clearMocks: true,
}

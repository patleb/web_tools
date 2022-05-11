module.exports = {
  testEnvironment: 'jsdom',
  roots: [
    'test/javascript',
  ],
  moduleDirectories: [
    'node_modules',
  ],
  moduleNameMapper: {
    '^@@/(.+)': '<rootDir>/app/javascript/$1',
    '^@@lib/(.+)': '<rootDir>/app/javascript/lib/$1',
    '^@@vendor/(.+)': '<rootDir>/app/javascript/vendor/$1',
  },
  moduleFileExtensions: [
    'js',
    'json',
    'coffee',
  ],
  testRegex: '_test\\.js$',
  transform: {
    '\\.js$': 'babel-jest',
    '\\.coffee$': './app/javascript/lib/ext_webpacker/jest/jest-preprocessor.js',
  },
  preset: './app/javascript/lib/ext_webpacker/jest/jest-preset.js',
  setupFilesAfterEnv: [
    './app/javascript/lib/ext_webpacker/jest/jest-setup.js'
  ],
  clearMocks: true,
}

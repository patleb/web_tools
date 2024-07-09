### References
# https://mildlyinternet.com/code/profiling-rails-boot-time.html
# i18n is slow to load --> would be the next best thing to replace (routes aren't that bad ~100ms)
# bin/rake is significantly faster

require 'ext_rails/monkey_patch'
require 'ext_rails/rake/backtrace'

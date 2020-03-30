### References
# https://mildlyinternet.com/code/profiling-rails-boot-time.html
# i18n is slow to load --> would be the next best thing to replace (routes aren't that bad ~100ms)
# bin/rake is significantly faster

require 'mix_core/active_support/dependencies/with_profile'
require 'mix_core/rake/backtrace'

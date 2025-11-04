### References
# https://github.com/basecamp/local_time/blob/v2.1.0/lib/assets/javascripts/src/local-time
###
I18n.translations.deep_merge
  en:
    date:
      days: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
      short_days: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      months: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
      short_months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      yesterday: 'yesterday'
      today: 'today'
      tomorrow: 'tomorrow'
      on: 'on %{date}'
      formats:
        default: '%b %e, %Y'
        this_year: '%b %e'
    time:
      am: 'am'
      pm: 'pm'
      singular: 'a %{time}'
      singular_an: 'an %{time}'
      elapsed: '%{time} ago'
      second: 'second'
      seconds: 'seconds'
      minute: 'minute'
      minutes: 'minutes'
      hour: 'hour'
      hours: 'hours'
      formats:
        default: '%l:%M%P'
    datetime:
      at: '%{date} at %{time}'
      formats:
        default: '%B %e, %Y at %l:%M%P %Z'

Date.define_singleton_methods
  current: ->
    new Date(Date.now())

Date.polyfill_singleton_methods
  now: ->
    new Date().getTime()

Date.override_methods
  blank: ->
    false

  eql: (other) ->
    return false unless other.is_a Date
    @getTime() is other.getTime()

Date.define_methods
  to_i: ->
    Math.floor(@to_f())

  to_f: ->
    @getTime() / 1000

  to_d: ->
    @to_f()

  to_s: ->
    @toString()

  to_date: ->
    this

  safe_text: ->
    @toString()

  strftime: (format) ->
    day    = @getDay()
    date   = @getDate()
    month  = @getMonth()
    year   = @getFullYear()
    hour   = @getHours()
    minute = @getMinutes()
    second = @getSeconds()
    format.replace /%(-?)([%aAbBcdeHIlmMpPSwyYZ])/g, (match, flag, modifier) =>
      switch modifier
        when '%' then '%'
        when 'a' then t('date.short_days')[day]
        when 'A' then t('date.days')[day]
        when 'b' then t('date.short_months')[month]
        when 'B' then t('date.months')[month]
        when 'c' then @toString()
        when 'd' then pad(date, flag)
        when 'e' then date
        when 'H' then pad(hour, flag)
        when 'I' then pad(@strftime('%l'), flag)
        when 'l' then (if hour is 0 or hour is 12 then 12 else (hour + 12) % 12)
        when 'm' then pad(month + 1, flag)
        when 'M' then pad(minute, flag)
        when 'p' then t("time.#{if hour > 11 then 'pm' else 'am'}").upcase()
        when 'P' then t("time.#{if hour > 11 then 'pm' else 'am'}")
        when 'S' then pad(second, flag)
        when 'w' then day
        when 'y' then pad(year % 100, flag)
        when 'Y' then year
        when 'Z' then parse_timezone(this)

pad = (num, flag) ->
  switch flag
    when '-' then num
    else ("0#{num}").slice(-2)

parse_timezone = (time) ->
  string = time.toString()
  # Sun Aug 30 2015 10:22:57 GMT-0400 (NAME)
  if name = string.match(/\(([\w\s]+)\)$/)?[1]
    if /\s/.test(name)
      # Sun Aug 30 2015 10:22:57 GMT-0400 (Eastern Daylight Time)
      name.match(/\b(\w)/g).join('')
    else
      # Sun Aug 30 2015 10:22:57 GMT-0400 (EDT)
      name
  # Sun Aug 30 10:22:57 EDT 2015
  else if name = string.match(/(\w{3,4})\s\d{4}$/)?[1]
    name
  # 'Sun Aug 30 10:22:57 UTC-0400 2015'
  else if name = string.match(/(UTC[\+\-]\d+)/)?[1]
    name
  else
    ''

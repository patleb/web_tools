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

DATE = /^\d{4}(-\d{1,2}){0,2}$/
DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
DAYS_LEAP = DAYS.dup().tap (days) -> days[1] = 29
WEEK_DAYS = [null, null, 0, 28, 59, 89, 120, 150, 181, 212, 242, 273, 303, 334]
WEEK_DAYS_LEAP = WEEK_DAYS.dup().tap (days) -> days[3] = 29

Date.polyfill_singleton_methods
  now: ->
    new Date().getTime()

Date.decorate_singleton_methods
  parse: (string) ->
    if string.match DATE
      @super("#{string}T12:00:00") # default to 12:00:00 to skip time zone logic, support for UTC ± 12 only
    else
      @super(string)

Date.override_singleton_methods
  new: (args...) ->
    if 1 <= args.length <= 3
      [year, month_i, day] = args
      new this(year, month_i ? 0, day ? 1, 12, 0, 0)
    else
      new this(args...)

Date.define_singleton_methods
  current: ->
    new Date(Date.now())

  leap: (year) ->
    (year % 4 is 0) and not (year % 100 is 0) or (year % 400 is 0)

  # NOTE: first week starts on January 1st, second week stars on next Monday
  week: (year, month, day) ->
    date = new Date(year, month - 1, day)
    if month is 1 and day <= 7
      if day <= date.weekday then 1 else 2
    else
      if month is 1
        Math.ceil((day - @first_week_last_day(year)) / 7) + 1
      else
        days = 31 - @first_week_last_day(year)
        days += (if @leap year then WEEK_DAYS_LEAP else WEEK_DAYS)[month]
        days += day
        Math.ceil(days / 7) + 1

  days_for: (year, month = null) ->
    days = DAYS
    days = DAYS_LEAP if @leap year
    days = days[month - 1] if month
    days

  second_week_first_date: (year) ->
    new Date(year, 0, @first_week_last_day(year) + 1)

  first_week_last_day: (year) ->
    7 - new Date(year, 0, 1).weekday + 1

Date.define_readers
  leap:    -> @constructor.leap @year
  week:    -> @constructor.week @year, @month, @day
  weekday: -> if (day = @getDay()) then day else 7 # the week starts on Monday [1 to 7]
  year:    -> @getFullYear()
  month:   -> @getMonth() + 1 # [1 to 12]
  month_days: -> @constructor.days_for(@year, @month)
  day:     -> @getDate()
  hour:    -> @getHours()
  minute:  -> @getMinutes()
  second:  -> @getSeconds()
  offset:  -> -Math.round(@getTimezoneOffset() / 15) * 15 * 60

Date.override_methods
  blank: ->
    false

  eql: (other) ->
    return false unless other.is_a Date
    @getTime() is other.getTime()

  dup: ->
    new @constructor this

  to_h: ->
    { @year, @month, @day, @hour, @minute, @second }

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

  duration: (date) ->
    new Duration(Math.floor((this - date) / 1000))

  advance: (value) ->
    unless value.is_a Duration
      value = new Duration(value)
    { sign = 1, years = 0, months = 0, weeks = 0, days = 0, hours = 0, minutes = 0, seconds = 0 } = value
    months += years * 12
    [weeks, remainder] = weeks.divmod(1)
    days += 7 * remainder
    [days, remainder] = days.divmod(1)
    days += weeks * 7
    hours += 24 * remainder
    minutes += hours * 60
    seconds += minutes * 60
    date = @dup()
    date.setMonth(date.month + sign * months) if months
    date.setDate(date.day + sign * days) if days
    date.setSeconds(date.second + sign * seconds) if seconds
    date

  strftime: (format) ->
    format.replace /%(-?)([%aAbBcdeHIlmMpPSwyYZ])/g, (match, flag, modifier) =>
      switch modifier
        when '%' then '%'
        when 'a' then t('date.short_days')[@weekday - 1]
        when 'A' then t('date.days')[@weekday - 1]
        when 'b' then t('date.short_months')[@month - 1]
        when 'B' then t('date.months')[@month - 1]
        when 'c' then @toString()
        when 'd' then pad(@day, flag)
        when 'e' then @day
        when 'H' then pad(@hour, flag)
        when 'I' then pad(@strftime('%l'), flag)
        when 'l' then (if @hour is 0 or @hour is 12 then 12 else (@hour + 12) % 12)
        when 'm' then pad(@month, flag)
        when 'M' then pad(@minute, flag)
        when 'p' then t("time.#{if @hour > 11 then 'pm' else 'am'}").upcase()
        when 'P' then t("time.#{if @hour > 11 then 'pm' else 'am'}")
        when 'S' then pad(@second, flag)
        when 'w' then @weekday - 1
        when 'y' then pad(@year % 100, flag)
        when 'Y' then @year
        when 'Z'
          string = @toString()
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

pad = (num, flag) ->
  switch flag
    when '-' then num
    else ("0#{num}").slice(-2)

class window.Duration
  @SECONDS: {
    second: 1,
    minute: 60,
    hour:   3600,
    day:    86400,
    week:   604800,
    month:  2629746, # 1/12 of a gregorian year
    year:   31556952, # length of a gregorian year (365.2425 days)
  }

  # NOTE: sub-seconds not supported
  constructor: (d) ->
    if d.is_a Array # dates sorted in ascending order
      d = d.last().duration(d.first())
    if d.is_a String
      time = false
      number = ''
      for char in d
        switch char
          when '+' then @sign = 1
          when '-' then @sign = -1
          when 'P' then @sign ||= 1; @years = @months = @weeks = @days = @hours = @minutes = @seconds = 0
          when 'Y' then [@years,   number] = [+number, '']
          when 'W' then [@weeks,   number] = [+number, '']
          when 'D' then [@days,    number] = [+number, '']
          when 'H' then [@hours,   number] = [+number, '']
          when 'S' then [@seconds, number] = [+number, '']
          when 'T' then time = true
          when 'M'
            if time
              [@minutes, number] = [+number, '']
            else
              [@months, number] = [+number, '']
          else number += char
    else if d.is_a Number
      @years = @months = @weeks = @days = @hours = @minutes = @seconds = 0
      [@sign, d] = [Math.sign(d), Math.abs(d)]
      return if d is 0
      ['years', 'months', 'weeks', 'days', 'hours', 'minutes'].each (part) =>
        seconds = Duration.SECONDS[part.singularize()]
        this[part] = Math.floor(d / seconds)
        d = d % seconds
        return if this[part] is 0
      @seconds = Math.floor(d)
    else
      [@sign, @years, @months, @weeks, @days, @hours, @minutes, @seconds] =
        [d.sign ? 1, d.years ? 0, d.months ? 0, d.weeks ? 0, d.days ? 0, d.hours ? 0, d.minutes ? 0, d.seconds ? 0]
          .map('to_f')

  blank: ->
    false

  eql: (other) ->
    return false unless other?.is_a Duration
    @to_i() is other.to_i()

  to_h: ->
    { @sign, @years, @months, @weeks, @days, @hours, @minutes, @seconds }

  toJSON: ->
    hash = @to_h()
    delete hash.sign if hash.sign is 1
    hash.select (k, v) -> v

  to_i: ->
    @sign * (
      @years   * Duration.SECONDS.year   +
      @months  * Duration.SECONDS.month  +
      @weeks   * Duration.SECONDS.week   +
      @days    * Duration.SECONDS.day    +
      @hours   * Duration.SECONDS.hour   +
      @minutes * Duration.SECONDS.minute +
      @seconds
    )

  to_s: ->
    string = if @sign is -1 then '-P' else 'P'
    string += "#{@years}Y"  if @years
    string += "#{@months}M" if @months
    string += "#{@weeks}W"  if @weeks
    string += "#{@days}D"   if @days
    if @hours or @minutes or @seconds
      string += 'T'
      string += "#{@hours}H"   if @hours
      string += "#{@minutes}M" if @minutes
      string += "#{@seconds}S" if @seconds
    string

  toString: Duration::to_s

  safe_text: ->
    @to_s().html_safe(true)

  in_years:   -> @to_i() / Duration.SECONDS.year
  in_months:  -> @to_i() / Duration.SECONDS.month
  in_weeks:   -> @to_i() / Duration.SECONDS.week
  in_days:    -> @to_i() / Duration.SECONDS.day
  in_hours:   -> @to_i() / Duration.SECONDS.hour
  in_minutes: -> @to_i() / Duration.SECONDS.minute
  in_seconds: -> @to_i()

  add: (other) ->
    unless other.is_a Duration
      other = new @constructor(other)
    new @constructor(
      years:   @sign * @years   + other.sign * other.years,
      months:  @sign * @months  + other.sign * other.months,
      weeks:   @sign * @weeks   + other.sign * other.weeks,
      days:    @sign * @days    + other.sign * other.days,
      hours:   @sign * @hours   + other.sign * other.hours,
      minutes: @sign * @minutes + other.sign * other.minutes,
      seconds: @sign * @seconds + other.sign * other.seconds,
    )

  sub: (other) ->
    unless other.is_a Duration
      other = new @constructor(other)
    other.sign *= -1
    @add(other)

class Sm.ActiveStandbyPair extends Js.StateMachine
  config: ->
    events:
      fault_trigger:
        'suspect, failed': 'active, standby':
          next: =>
            switch @condition()
              when 'val_0' then 'active'
              when 'val_1' then 'standby'
        active: 'suspect':
          before: =>
            @perform_switchover()
        standby: 'suspect'
        after: =>
          @send_diagnostic_request()
          @raise_alarm('loss_of_redundancy')
      switchover:
        standby: 'active'
        active: 'standby'
        before: =>
          @perform_switchover()
          @check_mate_status()
          @send_switchover_response()
      diagnostic_passed:
        suspect: 'standby'
        before: =>
          @send_diagnostic_pass_report()
          @clear_alarm('loss_of_redundancy')
      diagnostic_failed:
        suspect: 'failed'
        before: =>
          @send_diagnostic_failure_report()
      operator_inservice:
        failed: 'suspect'
        suspect: 'suspect':
          before: =>
            @abort_diagnostics()
            @transition.event_before()
        before: =>
          @send_diagnostic_request()
          @send_operator_inservice_response()

    send_diagnostic_request: ->
    raise_alarm: (msg) ->
    clear_alarm: (msg) ->
    perform_switchover: ->
    send_switchover_response: ->
    send_operator_inservice_response: ->
    send_diagnostic_failure_report: ->
    send_diagnostic_pass_report: ->
    abort_diagnostics: ->
    check_mate_status: ->

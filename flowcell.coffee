

# ////////// Helpers for in-place editing //////////

# Returns an event map that handles the "escape" and "return" keys and
# "blur" events on a text input (given by selector) and interprets them
# as "ok" or "cancel".
okCancelEvents = (selector, callbacks) ->
  ok = callbacks.ok || () -> null
  cancel = callbacks.cancel || () -> null

  console.log('hey')
  events = {}
  k = 'keyup '+selector+', keydown '+selector+', focusout '+selector
  events = (evt) ->
    if evt.type is "keydown" && evt.which is 27
      # escape = cancel
      cancel.call(this, evt)
    else if evt.type is "keyup" && evt.which is 13 ||
               evt.type is "focusout"
      # blur/return/enter = ok/submit if non-empty
      value = String(evt.target.value || "")
      if value
        ok.call(this, value, evt)
      else
        cancel.call(this, evt)
  events

activateInput = (input) ->
  input.focus()
  input.select()


truef = -> true


@Flowcells = new Meteor.Collection('flowcells')
@Config = new Meteor.Collection('config')
@Exps = new Meteor.Collection('exps')


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

if Meteor.isClient
  Meteor.loginWithGoogle()

  checkTimeLapse = -> Session.set('time',new Date())
  
  Session.setDefault('editing',null)
  
  window.setInterval(checkTimeLapse,1000)

truef = -> true

if Meteor.isServer
  Meteor.startup ->
    # code to run on server at startup
    
    @Flowcells.allow({insert: truef, update: truef, remove: truef})

    @Config.remove({})
    @Config.insert
      duration: {SUV: 40, Ni: 5, protein: 40, heating: 20, cells: 20, fix: 10}
      warning: {yellow: 3}

resetData = ->
 sample_data = [
      {name: "FC1"}
    , {name: "FC2"}
    , {name: "FC3"}
    , {name: "FC4"}
    , {name: "FC5"}
  ]

  @Flowcells.remove({})

  _.each(sample_data,(d) -> @Flowcells.insert(d))


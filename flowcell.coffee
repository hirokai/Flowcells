@Flowcells = new Meteor.Collection('flowcells')
@Config = new Meteor.Collection('config')
@Exps = new Meteor.Collection('exps')

@Protocols = new Meteor.Collection('protocols')


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

if Meteor.isServer
  Meteor.startup ->
    # code to run on server at startup
    
    @Flowcells.allow({insert: truef, update: truef, remove: truef})

    @Config.remove({})
    @Config.insert
      duration: {SUV: 40, Ni: 5, protein: 40, heating: 20, cells: 20, fix: 10}
      warning: {yellow: 3}
#    if @Protocols.find({}).count() == 0
    initProtocols()

initProtocols = ->
  @Protocols.remove({})
  @Protocols.insert
    name: 'biotin',
    fullname: 'Biotin'
    header1: [
      (col: 1, row: 2, name: 'Dry coverslip')
      (col: 1, row: 2, name: 'TBS in')
      (col: 1, row: 2, name: 'SUV mix')
      (col: 2, row: 1, name: 'SUV')
      (col: 2, row: 1, name: 'NiCl2')
      (col: 1, row: 2, name: 'H/F in')
      (col: 2, row: 1, name: 'Streptavidin')
      (col: 2, row: 1, name: 'Protein')
      (col: 1, row: 2, name: 'Heating')
      (col: 3, row: 1, name: 'Cells')
    ]
    header2:[
      'in','wash','in','wash','in','wash','in','wash','in','fix','wash'
    ]
    timepoints: [ 
      (name: 'dry')
      (name: 'TBS')
      (name: 'SUVmix')
      (name: 'SUV', duration: 40)
      (name: 'SUVwash', time: true)
      (name: 'Ni', duration: 5)
      (name: 'Niwash', time: true)
      (name: 'HF', duration: 15)
      (name: 'streptavidin', time: true, duration: 45)
      (name: 'streptavidin_wash', time: true)
      (name: 'protein', duration: 40)
      (name: 'proteinwash', time: true)
      (name: 'heating', duration: 20)
      (name: 'cells', time: true, duration: 20)
      (name: 'fix', time: true, duration: 10)
      (name: 'fixwash', time: true)
    ]
    totalTime: 210

  @Protocols.insert
    name: 'pllpeg',
    fullname: 'PLL-PEG'
    header1: [
      (col: 2, row: 1, name: 'Etch coverslip')
      (col: 1, row: 2, name: 'Dry coverslip')
      (col: 3, row: 1, name: 'PLL-PEG')
      (col: 1, row: 2, name: 'TBS in')
      (col: 1, row: 2, name: 'SUV mix')
      (col: 2, row: 1, name: 'SUV')
      (col: 2, row: 1, name: 'NiCl2')
      (col: 1, row: 2, name: 'H/F in')
      (col: 2, row: 1, name: 'Protein')
      (col: 1, row: 2, name: 'Heating')
      (col: 3, row: 1, name: 'Cells')
    ]
    header2: [
      'start','wash','start','wash','dry','in','wash','in','wash','in','wash','in','fix','wash'
    ]
    timepoints: [
      (name: 'piranha', duration: 5)
      (name: 'piranha_wash', time: true)
      (name: 'dry_piranha')
      (name: 'pll',duration: 60)
      (name: 'pll_wash', time: true)
      (name: 'dry_pll')
      (name: 'TBS')
      (name: 'SUVmix')
      (name: 'SUV', duration: 40)
      (name: 'SUVwash', time: true)
      (name: 'Ni', duration: 5)
      (name: 'Niwash', time: true)
      (name: 'HF')
      (name: 'protein', duration: 40)
      (name: 'proteinwash', time: true)
      (name: 'heating', duration: 20)
      (name: 'cells', time: true, duration: 20)
      (name: 'fix', time: true, duration: 10)
      (name: 'fixwash', time: true)
    ]
    totalTime: 270

  @Protocols.insert
    name: 'default',
    fullname: 'Default'
    header1: [
      (col: 1, row: 2, name: 'Dry coverslip')
      (col: 1, row: 2, name: 'TBS in')
      (col: 1, row: 2, name: 'SUV mix')
      (col: 2, row: 1, name: 'SUV')
      (col: 2, row: 1, name: 'NiCl2')
      (col: 1, row: 2, name: 'H/F in')
      (col: 2, row: 1, name: 'Protein')
      (col: 1, row: 2, name: 'Heating')
      (col: 3, row: 1, name: 'Cells')
    ]
    header2: [
      'in','wash','in','wash','in','wash','in','fix','wash'
    ]
    timepoints: [
      (name: 'dry')
      (name: 'TBS')
      (name: 'SUVmix')
      (name: 'SUV', duration: 40)
      (name: 'SUVwash', time: true)
      (name: 'Ni', duration: 5)
      (name: 'Niwash', time: true)
      (name: 'HF')
      (name: 'protein', duration: 40)
      (name: 'proteinwash', time: true)
      (name: 'heating', duration: 20)
      (name: 'cells', time: true, duration: 20)
      (name: 'fix', time: true, duration: 10)
      (name: 'fixwash', time: true)
    ]
    totalTime: 150

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


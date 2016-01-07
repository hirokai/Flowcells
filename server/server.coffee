@Protocols = new Meteor.Collection('protocols')
@Flowcells = new Meteor.Collection('flowcells')
@Config = new Meteor.Collection('config')
@Exps = new Meteor.Collection('exps')

tobj =
  insert: (uid, obj) -> obj.owner == (uid || 'sandbox')
  update: (uid, obj) -> obj.owner == (uid || 'sandbox')
  remove: (uid, obj) -> obj.owner == (uid || 'sandbox')

@Protocols.allow
  insert: () -> false
  update: (uid, obj) -> false
  remove: () -> false

@Flowcells.allow tobj
@Exps.allow tobj
@Config.allow tobj

Meteor.publish("exps", ->
  Exps.find({$or: [{owner: this.userId || 'sandbox'}, {shared: this.userId}]})
)

Meteor.publish("flowcells", ->
  Flowcells.find({$or: [{owner: this.userId || 'sandbox'}, {shared: this.userId}]})
)

Meteor.publish("protocols", ->
  Protocols.find({})
)

Meteor.publish("config", ->
  Config.find({})
)

Meteor.startup ->
  # code to run on server at startup
  @Config.remove({})
  @Config.insert
    duration: {SUV: 40, Ni: 5, protein: 40, heating: 20, cells: 20, fix: 10}
    warning: {yellow: 3}
  #    if @Protocols.find({}).count() == 0
  initProtocols_201512()

truef = -> true

initProtocols_201512 = ->
  @Protocols.remove({})
  @Protocols.insert
    name: 'default'
    version: '1'
    fullname: 'PLA MNs'
    sample_name: 'Sample'
    header1: [
      (col: 1, row: 2, name: 'Put in oven')
      (col: 3, row: 1, name: 'Degas #1')
      (col: 3, row: 1, name: 'Degas #2')
      (col: 3, row: 1, name: 'Degas #3')
      (col: 1, row: 2, name: 'Put PTFE weight')
      (col: 1, row: 2, name: 'Take out')
      (col: 1, row: 2, name: 'Peel off')
    ]
    header2: [
      'Pump', 'Hold', 'Release',
      'Pump', 'Hold', 'Release',
      'Pump', 'Hold', 'Release'
    ]
    timepoints: [
      (name: 'oven', duration: 30)
      (name: 'degas1_pump', duration: 2)
      (name: 'degas1_hold', duration: 5)
      (name: 'degas1_release', duration: 5)
      (name: 'degas2_pump', duration: 2)
      (name: 'degas2_hold', duration: 5)
      (name: 'degas2_release', duration: 5)
      (name: 'degas3_pump', duration: 2)
      (name: 'degas3_hold', duration: 5)
      (name: 'degas3_release', duration: 15)
      (name: 'put_weight', duration: 120)
      (name: 'take_out', duration: 20)
      (name: 'peel_off')
    ]
    totalTime: 216

initProtocols = ->
  @Protocols.remove({})
  @Protocols.insert
    name: 'biotin'
    version: '2'
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
    header2: [
      'in', 'wash', 'in', 'wash', 'in', 'wash', 'in', 'wash', 'in', 'fix', 'wash'
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
    name: 'pllpeg'
    version: '2'
    fullname: 'PLL-PEG'
    header1: [
      (col: 2, row: 1, name: 'Etch coverslip')
      (col: 1, row: 2, name: 'Dry coverslip')
      (col: 3, row: 1, name: 'PLL-PEG')
      (col: 2, row: 1, name: 'UV exposure')
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
      'start', 'wash', 'start', 'wash', 'dry',
      'start', 'wash'
      'in', 'wash', 'in', 'wash', 'in', 'wash', 'in', 'fix', 'wash'
    ]
    timepoints: [
      (name: 'piranha', duration: 5, fullname: 'Piranha etching')
      (name: 'piranha_wash', time: true, fullname: 'Rinse piranha')
      (name: 'dry_piranha', fullname: 'Dry coverslip')
      (name: 'pll', duration: 60, fullname: 'PLL-PEG incubation')
      (name: 'pll_wash', time: true, fullname: 'PLL-PEG wash and dry')
      (name: 'uv', duration: 10, fullname: 'Deep UV exposure (10 min)')
      (name: 'uv_wash', time: true, fullname: 'Wash coverslip')
      (name: 'TBS', fullname: 'Flow in 1x TBS (2 mL)')
      (name: 'SUVmix', fullname: 'Mix SUVs with 10x TBS')
      (name: 'SUV', duration: 40, fullname: 'Flow in SUVs')
      (name: 'SUVwash', time: true, fullname: 'Wash SUVs (3 mL)')
      (name: 'Ni', duration: 5, fullname: 'Flow in NiCl2')
      (name: 'Niwash', time: true, fullname: 'Wash NiCl2 (3 mL)')
      (name: 'HF', duration: 20, fullname: 'Flow in HBS/FBS (2 mL)')
      (name: 'protein', time: true, duration: 40, fullname: 'Flow in proteins')
      (name: 'proteinwash', time: true, fullname: 'Wash proteins (2 mL)')
      (name: 'heating', duration: 20, fullname: 'Start heating FC')
      (name: 'cells', time: true, duration: 20, fullname: 'Inject cells')
      (name: 'fix', time: true, duration: 10, fullname: 'Fix cells')
      (name: 'fixwash', time: true, fullname: 'Wash formaldehyde (2 mL)')
    ]
    totalTime: 270

  @Protocols.insert
    name: 'pllpeg_onlyprotein',
    version: '2'
    fullname: 'PLL-PEG (No cells)'
    header1: [
      (col: 2, row: 1, name: 'Etch coverslip')
      (col: 1, row: 2, name: 'Dry coverslip')
      (col: 3, row: 1, name: 'PLL-PEG')
      (col: 2, row: 1, name: 'UV exposure')
      (col: 1, row: 2, name: 'TBS in')
      (col: 1, row: 2, name: 'SUV mix')
      (col: 2, row: 1, name: 'SUV')
      (col: 2, row: 1, name: 'NiCl2')
      (col: 1, row: 2, name: 'H/F in')
      (col: 2, row: 1, name: 'Protein')
    ]
    header2: [
      'start', 'wash', 'start', 'wash', 'dry',
      'start', 'wash'
      'in', 'wash', 'in', 'wash', 'in', 'wash'
    ]
    timepoints: [
      (name: 'piranha', duration: 5)
      (name: 'piranha_wash', time: true)
      (name: 'dry_piranha')
      (name: 'pll', duration: 60)
      (name: 'pll_wash', time: true)
      (name: 'dry_pll')
      (name: 'uv', duration: 10)
      (name: 'uv_wash', time: true)
      (name: 'TBS')
      (name: 'SUVmix')
      (name: 'SUV', duration: 40)
      (name: 'SUVwash', time: true)
      (name: 'Ni', duration: 5)
      (name: 'Niwash', time: true)
      (name: 'HF')
      (name: 'protein', duration: 40)
      (name: 'proteinwash', time: true)
    ]
    totalTime: 210

  @Protocols.insert
    name: 'pllpeg_onlyslb',
    version: '2'
    fullname: 'PLL-PEG (Only SLB)'
    header1: [
      (col: 2, row: 1, name: 'Etch coverslip')
      (col: 1, row: 2, name: 'Dry coverslip')
      (col: 3, row: 1, name: 'PLL-PEG')
      (col: 2, row: 1, name: 'UV exposure')
      (col: 1, row: 2, name: 'TBS in')
      (col: 1, row: 2, name: 'SUV mix')
      (col: 2, row: 1, name: 'SUV')
    ]
    header2: [
      'start', 'wash', 'start', 'wash', 'dry',
      'start', 'wash'
      'in', 'wash'
    ]
    timepoints: [
      (name: 'piranha', duration: 5)
      (name: 'piranha_wash', time: true, fullname: 'Rinse piranha')
      (name: 'dry_piranha', fullname: 'Dry coverslip')
      (name: 'pll', duration: 60)
      (name: 'pll_wash', time: true)
      (name: 'dry_pll')
      (name: 'uv', duration: 10)
      (name: 'uv_wash', time: true)
      (name: 'TBS')
      (name: 'SUVmix')
      (name: 'SUV', duration: 40)
      (name: 'SUVwash', time: true)
    ]
    totalTime: 150


  @Protocols.insert
    name: 'default'
    version: '2'
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
      'in', 'wash', 'in', 'wash', 'in', 'wash', 'in', 'fix', 'wash'
    ]
    timepoints: [
      (name: 'dry', fullname: 'Dry coverslip')
      (name: 'TBS', fullname: 'Flow in 1x TBS (2 mL)')
      (name: 'SUVmix', fullname: 'Mix SUVs with 10x TBS')
      (name: 'SUV', duration: 40, fullname: 'Flow in SUVs')
      (name: 'SUVwash', time: true, fullname: 'Wash SUVs (3 mL)')
      (name: 'Ni', duration: 5, fullname: 'Flow in NiCl2')
      (name: 'Niwash', time: true, fullname: 'Wash NiCl2 (3 mL)')
      (name: 'HF', duration: 20, fullname: 'Flow in HBS/FBS (2 mL)')
      (name: 'protein', time: true, duration: 40, fullname: 'Flow in proteins')
      (name: 'proteinwash', time: true, fullname: 'Wash proteins (2 mL)')
      (name: 'heating', duration: 20, fullname: 'Start heating FC')
      (name: 'cells', time: true, duration: 20, fullname: 'Inject cells')
      (name: 'fix', time: true, duration: 10, fullname: 'Fix cells')
      (name: 'fixwash', time: true, fullname: 'Wash formaldehyde (2 mL)')
    ]
    totalTime: 180

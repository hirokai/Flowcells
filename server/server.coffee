@Protocols = new Meteor.Collection('protocols')
@Flowcells = new Meteor.Collection('flowcells')
@Config = new Meteor.Collection('config')
@Exps = new Meteor.Collection('exps')

tobj = 
	insert: (uid,obj) -> obj.owner == (uid || 'sandbox')
	update: (uid,obj) -> obj.owner == (uid || 'sandbox')
	remove: (uid,obj) -> obj.owner == (uid || 'sandbox')

@Protocols.allow
	insert: () -> false
	update: (uid,obj) -> false
	remove: () -> false
	
@Flowcells.allow tobj
@Exps.allow tobj
@Config.allow tobj

Meteor.publish("exps", ->
  Exps.find({owner: this.userId || 'sandbox'})
  )

Meteor.publish("flowcells", ->
  Flowcells.find({owner: this.userId || 'sandbox'})
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
	initProtocols()

truef = -> true

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
      'start','wash','start','wash','dry',
      'start','wash'
      'in','wash','in','wash','in','wash','in','fix','wash'
    ]
    timepoints: [
      (name: 'piranha', duration: 5)
      (name: 'piranha_wash', time: true)
      (name: 'dry_piranha')
      (name: 'pll',duration: 60)
      (name: 'pll_wash', time: true)
      (name: 'dry_pll')
      (name: 'uv',duration: 10)
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
      (name: 'heating', duration: 20)
      (name: 'cells', time: true, duration: 20)
      (name: 'fix', time: true, duration: 10)
      (name: 'fixwash', time: true)
    ]
    totalTime: 270

  @Protocols.insert
    name: 'pllpeg_onlyprotein',
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
      'start','wash','start','wash','dry',
      'start','wash'
      'in','wash','in','wash','in','wash'
    ]
    timepoints: [
      (name: 'piranha', duration: 5)
      (name: 'piranha_wash', time: true)
      (name: 'dry_piranha')
      (name: 'pll',duration: 60)
      (name: 'pll_wash', time: true)
      (name: 'dry_pll')
      (name: 'uv',duration: 10)
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
      'start','wash','start','wash','dry',
      'start','wash'
      'in','wash'
    ]
    timepoints: [
      (name: 'piranha', duration: 5)
      (name: 'piranha_wash', time: true)
      (name: 'dry_piranha')
      (name: 'pll',duration: 60)
      (name: 'pll_wash', time: true)
      (name: 'dry_pll')
      (name: 'uv',duration: 10)
      (name: 'uv_wash', time: true)
      (name: 'TBS')
      (name: 'SUVmix')
      (name: 'SUV', duration: 40)
      (name: 'SUVwash', time: true)
    ]
    totalTime: 150


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
    totalTime: 180
Session.setDefault('editing', null)

Template.exps.helpers(
  exps: () -> Exps.find({},{sort: {createOn: 1}})

  active: () -> if Session.equals('exp_active',this._id) then 'active' else ''

  editing: () -> Session.equals('editing',this._id)
  )

#
# Exps
#

findName = () ->
  s_base = moment().format('M/DD/YYYY')
  s = s_base
  n = 2
  while Exps.find({name: s}).count() > 0
    s = s_base + "-" + n
    n += 1
  s

Template.exps.events =
  'click #add-exp': (e) ->
    Exps.insert({name: findName(), createOn: new Date(), expType: 'default'})
    
  'click #add-biotin': (e) ->
    Exps.insert({name: findName(), createOn: new Date(), expType: 'biotin'})

  'click .expentry': (e) -> Session.set('exp_active',this._id)
    
  'click .edit': (e,tmpl) -> Session.set('editing',this._id)

  'click .ok': (e,tmpl) ->
    s = $(tmpl.find('#nameinput')).val()
    Exps.update(this._id,{name: s})
    Session.set('editing',null)
  
  'click .cancel': (e) -> Session.set('editing',null)
  
  'click .remove': (e) ->
    if window.confirm('Are you sure you want to remove this? This cannot be undone.')
      Exps.remove(this._id)

  'dblclick .active': (e) -> Session.set('editing',this._id)

  'keydown #nameinput': (e,tmpl) ->
    if e.keyCode == 13    # if Enter
      s = $(tmpl.find('#nameinput')).val()
      Exps.update(this._id,{name: s})
      Session.set('editing',null)
    else if e.keyCode == 27   #if Escape
      Session.set('editing',null)


Template.right_pane.helpers
  exp_selected: () -> Session.get('exp_active')?

#
# Utility functions
#

formatDate = (d) -> moment(d).format("H:mm:ss")

formatMin = (v) ->
  vv = Math.abs(v)
  s = Math.round(vv/1000)
  "" + Math.floor(s/60) + "'" + s % 60 + '"'


steps = 
  default: [
    'dry','TBS','SUVmix','SUV','SUVwash','Ni','Niwash','HF',
    'protein','proteinwash',
    'heating','cells','fix','fixwash']
  biotin: [
    'dry','TBS','SUVmix','SUV','SUVwash','Ni','Niwash','HF',
    'streptavidin', 'streptavidin_wash',
    'protein','proteinwash',
    'heating','cells','fix','fixwash']


duration =
  default: {SUV: 40, Ni: 5, protein: 40, heating: 20, cells: 20, fix: 10}
  biotin: {SUV: 40, Ni: 5, HF: 15, streptavidin: 45, protein: 40, heating: 20, cells: 20, fix: 10}

prevStep = (n,typ) ->
  i = steps[typ || 'default'].indexOf(n)
  if i > 0 then steps[typ || 'default'][i-1] else undefined

#
# Flowcells
#

Template.list.helpers
  header1: () ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    if  exp?.expType == 'biotin' then [
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
    ] else [
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
  header2: () ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    if exp?.expType == 'biotin' then [
      'in','wash','in','wash','in','wash','in','wash','in','fix','wash'
    ] else [
      'in','wash','in','wash','in','wash','in','fix','wash'
    ]

  timepoints: () ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    if exp?.expType == 'biotin' then [
      (name: 'dry')
      (name: 'TBS')
      (name: 'SUVmix')
      (name: 'SUV')
      (name: 'SUVwash', time: true)
      (name: 'Ni')
      (name: 'Niwash', time: true)
      (name: 'HF')
      (name: 'streptavidin', time: true)
      (name: 'streptavidin_wash', time: true)
      (name: 'protein')
      (name: 'proteinwash', time: true)
      (name: 'heating')
      (name: 'cells', time: true)
      (name: 'fix', time: true)
      (name: 'fixwash', time: true)
    ] else [
      (name: 'dry')
      (name: 'TBS')
      (name: 'SUVmix')
      (name: 'SUV')
      (name: 'SUVwash', time: true)
      (name: 'Ni')
      (name: 'Niwash', time: true)
      (name: 'HF')
      (name: 'protein')
      (name: 'proteinwash', time: true)
      (name: 'heating')
      (name: 'cells', time: true)
      (name: 'fix', time: true)
      (name: 'fixwash', time: true)
    ]

  flowcells: () ->
    eid = Session.get('exp_active')
    Flowcells.find({exp: eid},{sort: {createOn: 1}})

  exp_name: () ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    exp?.name

  label_type: () ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    t = exp?.expType || 'default'
    s = switch t
      when 'biotin' then 'warning'
      else 'default'
    new Handlebars.SafeString('<span class="label label-'+s+'">'+t+'</span>')

  editing: () -> Session.get('editing') == this._id

  done: (name) -> if this[name]? then "done" else ""

  cell: (name,fc) ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    typ = exp?.expType || 'default'
    t = fc[name]
    if t
      new Handlebars.SafeString(formatDate(t)+"<span data-name='"+name+"' class='undo glyphicon glyphicon-remove'></span>")
    else
      ps = prevStep(name,typ)
      if name == "dry" || fc[ps]
        new Handlebars.SafeString("<button class='do' data-name='"+name+"'>Do</button>");
      else
        ""

  celltime: (name,fc) ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    typ = exp?.expType || 'default'
    t = fc[name]
    if t
      new Handlebars.SafeString(formatDate(t)+"<span class='undo glyphicon glyphicon-remove' data-name='"+name+"'></span>")
    else
      config = Config.findOne()
      warning = {yellow: 3}
      tp = fc[prevStep(name,typ)]
      if tp
        dur = duration[typ][prevStep(name,typ)] * 60 * 1000
        elapsed = Session.get('time') - tp
        rest = dur - elapsed
        c = ''
        if rest < 0
          c = 'late'
        else if rest < 1000*60*warning.yellow # within 3 min.
          c = 'coming'
        new Handlebars.SafeString("<button class='do "+c+"' data-name='"+name+"'>"+formatMin(rest)+"</button>")
      else
        if Flowcells.findOne(fc._id)[prevStep(name,typ)]
            new Handlebars.SafeString("<button class='do "+c+"' data-name='"+name+"'>"+formatMin(rest)+"</button>")
        else ""

# You can choose "Fixing cell is not done" option.
  celltime_fixing: () ->
    t = this[name]
    if t
      new Handlebars.SafeString(formatDate(t)+"<span class='undo glyphicon glyphicon-remove' data-name='"+name+"'></span>")
    else
      config = Config.findOne()
      duration = config.duration
      warning = config.warning
      tp = this[prevStep(name)]
      if tp
        dur = duration[prevStep(name)] * 60 * 1000
        elapsed = Session.get('time') - tp
        rest = dur - elapsed
        c = ''
        if rest < 0
          c = 'late'
        else if rest < 1000*60*warning.yellow # within 3 min.
          c = 'coming'
        new Handlebars.SafeString("<button class='do "+c+"' data-name='"+name+"'>"+formatMin(rest)+"</button>")
      else
        if Flowcells.findOne(this._id)[prevStep(name)]
          new Handlebars.SafeString("<button class='do "+c+"' data-name='"+name+"'>"+formatMin(rest)+"</button>")
        else
          "No!"

Template.list.events(
  'click button.do': (e) ->
    n = $(e.target).attr('data-name')
    fid = $(e.target).parents('tr').attr('data-id')
    obj = {}
    obj[n] = new Date()
    fc = Flowcells.findOne(fid)
    Flowcells.update(fid,{$set: obj})
    fc = Flowcells.findOne(fid)
 
  'click .undo': (e) ->
    n = $(e.target).attr('data-name')
    fid = $(e.target).parents('tr').attr('data-id')
    if window.confirm('Are you sure?: '+n)
      obj = {}
      obj[n] = ""
      Flowcells.update(fid,{$unset: obj})
      
  'click #newfc': () ->
    eid = Session.get('exp_active')
    num = Flowcells.find({exp: eid}).count() + 1
    e = Session.get('exp_active')
    Flowcells.insert({name: "FC"+num, createOn: new Date(), exp: e})
    
  'click .edit': (e,tmpl) ->
    Session.set('editing',this._id)

  'click .ok': (e,tmpl) ->
    n = $(tmpl.find('.name-input')).val()
    Flowcells.update(this._id,{$set: {name: n}})
    Session.set('editing',null)

  'click .cancel': (e,tmpl) ->
    Session.set('editing',null)

  'click .remove': (e,tmpl) ->
    if window.confirm('Are you sure you want to remove this? This cannot be undone.')
      Flowcells.remove(this._id)
    Session.set('editing',null)

  'keydown .name-input': (e,tmpl) ->
    if e.keyCode == 13
      n = $(tmpl.find('.name-input')).val()
      Flowcells.update(this._id,{$set: {name: n}})
      Session.set('editing',null)
    else if e.keyCode == 27
      Session.set('editing',null)
)

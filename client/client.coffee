Session.setDefault('editing',null)

Template.exps.exps = () -> Exps.find({},{sort: {createOn: 1}})

Template.exps.active = () -> if Session.equals('exp_active',this._id) then 'active' else ''

Template.exps.editing = () -> Session.equals('editing',this._id)


#
# Exps
#

Template.exps.events = 
  'click #add-exp': (e) ->
    d = new Date()
    s_base = ""+(d.getMonth()+1) + "/" + d.getDate() + "/" + +d.getFullYear()
    s = s_base;
    n = 2;
    while Exps.find({name: s}).count() > 0
      s = s_base + "-" + n
      n += 1
    Exps.insert({name: s, createOn: new Date()})
    
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
    if e.keyCode == 13
      s = $(tmpl.find('#nameinput')).val()
      Exps.update(this._id,{name: s})
      Session.set('editing',null)
    else if e.keyCode == 27
     Session.set('editing',null)


Template.right_pane.exp_selected = () -> Session.get('exp_active')?


#
# Utility functions
#

formatDate = (d) -> "" + d.getHours() + ":" + d.getMinutes() + ":" + d.getSeconds()

formatMin = (v) ->
  vv = Math.abs(v)
  s = Math.round(vv/1000)
  "" + Math.floor(s/60) + "'" + s % 60 + '"'


steps = ['dry','TBS','SUVmix','SUV','SUVwash','Ni','Niwash','HF','protein','proteinwash',
  'heating','cells','fix','fixwash']

 
prevStep = (n) ->
  i = steps.indexOf(n)
  if i > 0 then steps[i-1] else undefined


#
# Flowcells
#

Template.list.flowcells = () ->
  eid = Session.get('exp_active')
  Flowcells.find({exp: eid},{sort: {createOn: 1}})

Template.list.exp_name = () ->
  eid = Session.get('exp_active')
  exp = if eid then Exps.findOne(eid) else null
  exp?.name


Template.list.events(
  'click button.do': (e) ->
      n = $(e.target).attr('data-name')
      obj = {}
      obj[n] = new Date()
      Flowcells.update(this._id,{$set: obj})
  
  'click .undo': (e) ->
    n = $(e.target).attr('data-name')
    if window.confirm('Are you sure?: '+this.name)
      obj = {}
      obj[n] = ""
      console.log(obj,this._id)
      Flowcells.update(this._id,{$unset: obj})
      
  'click #newfc': () ->
    eid = Session.get('exp_active')      
    num = Flowcells.find({exp: eid}).count() + 1
    e = Session.get('exp_active')
    Flowcells.insert({name: "FC"+num, createOn: new Date(), exp: e})
    
  'click .edit': (e,tmpl) ->
    Session.set('editing',this._id)
#      activateInput(tmpl.find(".name-input"));    

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

Template.list.editing = () -> Session.get('editing') == this._id

Template.list.done = (name) -> if this[name]? then "done" else ""

Template.list.cell = (name) ->
  t = this[name]
  if t
    new Handlebars.SafeString(formatDate(t)+"<span data-name='"+name+"' class='undo glyphicon glyphicon-remove'></span>")
  else
    ps = prevStep(name)
    if name == "dry" || this[ps]
      new Handlebars.SafeString("<button class='do' data-name='"+name+"'>Do</button>");
    else
      ""

Template.list.celltime = (name) ->
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
      else ""



# You can choose "Fixing cell is not done" option.
Template.list.celltime_fixing =
  () ->
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



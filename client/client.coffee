Session.setDefault('editing',null)
Session.setDefault('showTime', false)

Template.exps.helpers
  exps: () -> Exps.find({},{sort: {createOn: -1}})

  active: () -> if Session.equals('exp_active',this._id) then 'active' else ''

  editing: () -> Session.equals('editing',this._id)

  protocols: () -> Protocols.find({})

Meteor.loginWithGoogle()

checkTimeLapse = ->
  d = new Date()
  Session.set('time',d)
  if Math.floor(d.valueOf()/1000) % 10 == 0
    renderProgress()

Session.setDefault('editing',null)

window.setInterval(checkTimeLapse,1000)

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
  'click .add-exp': (e) ->
    eid = Exps.insert({name: findName(), createOn: new Date(), expType: $(e.target).attr('data-exptype')})
    Session.set('exp_active',eid)
    
  'click .expentry': (e) ->
    Session.set('exp_active',this._id)
    renderProgress()
    
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

formatDate = (d) ->
  m = moment(d)
  m.format("H:mm") + "<small>:#{m.format('ss')}</small>"

formatMin = (v) ->
  vv = Math.abs(v)
  s = Math.round(vv/1000)
  "" + Math.floor(s/60) + "'" + s % 60 + '"'

prevStep = (n,typ) ->
  steps = Protocols.findOne({name: (typ || 'default')}).timepoints
  for v,i in steps
    if v.name == n
      break
  if i < steps.length and i > 0 then steps[i-1].name else undefined

#
# Flowcells
#

Template.list.helpers
  header1: () ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    Protocols.findOne({name: (exp?.expType || 'default')}).header1

  header2: () ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    Protocols.findOne({name: (exp?.expType || 'default')}).header2

  timepoints: () ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    Protocols.findOne({name: (exp?.expType || 'default')}).timepoints

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
    prot = Protocols.findOne({name: t})
    s = switch t
      when 'biotin' then 'warning'
      when 'pllpeg' then 'primary'
      else 'default'
    new Handlebars.SafeString('<span class="label label-'+s+'">'+(prot.fullname)+'</span>')

  editing: () -> Session.get('editing') == this._id

  done: (name,fc) -> if fc[name]? then "done undo" else ""

  cell: (name,fc) ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    typ = exp?.expType || 'default'
    t = fc[name]
    if t
      if Session.equals('showTime',true)
        new Handlebars.SafeString(formatDate(t)+"<span data-name='"+name+"' class='undo glyphicon glyphicon-remove'></span>")
      else
        ""
    else
      ps = prevStep(name,typ)
      timepoints = Protocols.findOne({name: typ}).timepoints
#      console.log(timepoints[0])
      if name == timepoints[0].name || fc[ps]
        new Handlebars.SafeString("<button class='do' data-name='"+name+"'>Do</button>");
      else
        ""

  celltime: (name,fc) ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    typ = exp?.expType || 'default'
    t = fc[name]
    if t
      if Session.equals('showTime',true)
        new Handlebars.SafeString(formatDate(t)+"<span data-name='"+name+"' class='undo glyphicon glyphicon-remove'></span>")
      else
        ""
    else
      config = Config.findOne()
      warning = {yellow: 3}
      tp = fc[prevStep(name,typ)]
      if tp
        timepoints = Protocols.findOne({name: (typ || 'default')}).timepoints
        dur = _.findWhere(timepoints,{name: prevStep(name,typ)}).duration * 60 * 1000
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
    Flowcells.update(fid,{$set: obj})
    renderProgress()
 
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
    renderProgress()

  'click #toggle-time': () ->
    Session.set('showTime',!Session.get('showTime'))
    
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

renderProgress = ->
  eid = Session.get('exp_active')
  exp = Exps.findOne(eid)
  fcs = Flowcells.find({exp: eid},{sort: {createOn: 1}}).fetch()
  svg = d3.select('svg')
  svg.selectAll('*').remove()
  console.log(fcs.length)
  color = d3.scale.category20()
  protocol = Protocols.findOne({name: exp.expType || 'default'})
  timepoints = protocol.timepoints
  totalTime = protocol.totalTime
  from = _.chain(fcs).map((fc)->_.min(_.values(fc))).min().value()
  to = _.max([d3.time.minute.offset(from, totalTime), _.chain(fcs).map((fc)->_.max(_.values(fc))).max().value()])
  console.log(from,to)
  x = d3.scale.linear().domain([from,to]).range([0,750])
  tn = _.map(timepoints,(t)->t.name)
  svg.selectAll('g').data(fcs,(d)->d._id).enter().append('g')
    .attr('transform',(d,i) -> 'translate (0,'+(i*25+100)+')')
    .selectAll('circle')
    .data(tn).enter()
    .append('circle')
    .attr('cx',(d,ti,fc_i)->
      x(if fcs[fc_i] then fcs[fc_i][d] else null) || -300
      )
    .attr({r:6, opacity: 0.6})
    .attr('fill',(d,i)->color(i))
  svg.append('g')
    .attr('transform',(d,i) -> 'translate ('+x(new Date())+',40)')
    .append('polygon')
    .attr('points',"0,0 -5,-10 5,-10")
    .attr('fill',(d,i)->'red')
  xAxis = d3.svg.axis().scale(x).orient('top').ticks(d3.time.seconds,10).tickFormat(d3.time.format('%H:%M')).tickSize(3)
  svg.append('g').attr('class','x axis')
    .attr('transform','translate(0,50)')
    .call(xAxis)

Template.list.rendered = ->
  renderProgress()

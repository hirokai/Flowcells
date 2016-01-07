Session.setDefault('editing', null)
Session.setDefault('showTime', false)
Session.setDefault('guideMode', false)
Session.setDefault('guideCurrentFC', 0)
Meteor.subscribe('exps')

@Flowcells = new Meteor.Collection('flowcells')
@Config = new Meteor.Collection('config')
@Exps = new Meteor.Collection('exps')
@Protocols = new Meteor.Collection('protocols')

Meteor.subscribe('exps')
Meteor.subscribe('flowcells')
Meteor.subscribe('config')
Meteor.subscribe('protocols')

moveSelectedFC = (delta) ->
  c = Session.get("guideCurrentFC")
  n = c + delta
  steps = get_mynextsteps()
  if n >= 0 and n < steps.length
    Session.set("guideCurrentFC",n)
  console.log(Session.get("guideCurrentFC"))


Meteor.startup () ->
  $(document).on 'keydown', (e) ->
    console.log(e)
    if e.keyCode == 38  # up arrow
      moveSelectedFC(-1)
      e.preventDefault()
    else if e.keyCode == 40  # down arrow
      moveSelectedFC(1)
      e.preventDefault()
    else if e.keyCode == 32  # space
      $('.nextstep .selected .btn').click()
      e.preventDefault()

UI.body.helpers
  hiddenOnGuide: () ->
    if Session.get('guideMode') then 'hidden' else ''
  colRight: () ->
    if Session.get('guideMode') then 'col-md-12' else 'col-md-10'
  classGuide: () ->
    if Session.get('guideMode') then 'guide' else ''


UI.body.events
  'click #toggle-guide': () ->
    Session.set('guideMode', !Session.get('guideMode'))
    $('body').toggleClass('guide')


Template.exps.helpers
  exps: () -> Exps.find({}, {sort: {createOn: -1}})

  active: () -> if Session.equals('exp_active', this._id) then 'active' else ''

  editing: () -> Session.equals('editing', this._id)

  protocols: () -> Protocols.find({})

checkTimeLapse = ->
  d = new Date()
  Session.set('time', d)
  if Math.floor(d.valueOf() / 1000) % 10 == 0
    renderProgress()

Session.setDefault('editing', null)

window.setInterval(checkTimeLapse, 1000)

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
    eid = Exps.insert({owner: Meteor.userId() || 'sandbox', name: findName(), createOn: new Date(), expType: $(e.target).attr('data-exptype')})
    Session.set('exp_active', eid)
    renderProgress()

  'click .expentry': (e) ->
    Session.set('exp_active', this._id)
    renderProgress()

  'click .edit': (e, tmpl) -> Session.set('editing', this._id)

  'click .ok': (e, tmpl) ->
    s = $(tmpl.find('#nameinput')).val()
    Exps.update(this._id, {name: s})
    Session.set('editing', null)

  'click .cancel': (e) -> Session.set('editing', null)

  'click .remove': (e) ->
    if window.confirm('Are you sure you want to remove this? This cannot be undone.')
      Exps.remove(this._id)

  'dblclick .active': (e) -> Session.set('editing', this._id)

  'keydown #nameinput': (e, tmpl) ->
    if e.keyCode == 13    # if Enter
      s = $(tmpl.find('#nameinput')).val()
      Exps.update(this._id, {name: s})
      Session.set('editing', null)
    else if e.keyCode == 27   #if Escape
      Session.set('editing', null)


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
  s = Math.round(vv / 1000)
  "" + Math.floor(s / 60) + "'" + s % 60 + '"'

prevStep = (n, typ) ->
  steps = Protocols.findOne({name: (typ || 'default')}).timepoints
  for v,i in steps
    if v.name == n
      break
  if i < steps.length and i > 0 then steps[i - 1].name else undefined

nextStep = (n, typ) ->
  steps = Protocols.findOne({name: (typ || 'default')}).timepoints
  for v,i in steps
    if v.name == n
      break
  if i < steps.length - 1 then steps[i + 1].name else undefined

findIndex = (vs, pred) ->
  r = -1
  for v,i in vs
    if pred(v)
      r = i
      break
  return r

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
    Flowcells.find({exp: eid}, {sort: {createOn: 1}})

  exp_name: () ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    exp?.name

  sample_name: () ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    Protocols.findOne({name: (exp?.expType || 'default')}).sample_name || 'FC'

  label_type: () ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    t = exp?.expType || 'default'
    prot = Protocols.findOne({name: t})
    s = switch t
      when 'biotin' then 'warning'
      when 'pllpeg' then 'primary'
      when 'pllpeg_onlyslb' then 'primary'
      when 'pllpeg_onlyprotein' then 'primary'
      else 'default'
    new Handlebars.SafeString('<span class="exptype exptype-' + s + '">' + (prot.fullname) + '</span>')

  editing: () -> Session.get('editing') == this._id

  done: (name, fc) -> if fc[name]? then "done" else ""

  cell: (name, fc) ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    typ = exp?.expType || 'default'
    t = fc[name]
    if t
      if Session.equals('showTime', true)
        new Handlebars.SafeString(formatDate(t))
      else
        steps = Protocols.findOne({name: (typ || 'default')}).timepoints
        idx = findIndex(steps, (s) -> s.name == name)
        new Handlebars.SafeString('<button class="btn undo btn-success" style="background:' + color(idx) + ';"><i class="fa fa-star"> </i></button>')
    else
      ps = prevStep(name, typ)
      timepoints = Protocols.findOne({name: typ}).timepoints
      #      console.log(timepoints[0])
      if name == timepoints[0].name || fc[ps]
        new Handlebars.SafeString("<button class='btn do btn-raised' data-name='" + name + "'>Do</button>");
      else
        ""

  celltime: (name, fc) ->
    eid = Session.get('exp_active')
    exp = if eid then Exps.findOne(eid) else null
    typ = exp?.expType || 'default'
    t = fc[name]
    if t
      if Session.equals('showTime', true)
        new Handlebars.SafeString(formatDate(t))
      else
        steps = Protocols.findOne({name: (typ || 'default')}).timepoints
        idx = findIndex(steps, (s) -> s.name == name)
        new Handlebars.SafeString('<button class="btn undo btn-success" style="background:' + color(idx) + ';"><i class="fa fa-star"> </i></button>')
    else
      config = Config.findOne()
      warning = {yellow: 3}
      tp = fc[prevStep(name, typ)]
      if tp
        timepoints = Protocols.findOne({name: (typ || 'default')}).timepoints
        dur = _.findWhere(timepoints, {name: prevStep(name, typ)}).duration * 60 * 1000
        elapsed = Session.get('time') - tp
        rest = dur - elapsed
        c = ''
        if rest < 0
          c = 'late'
        else if rest < 1000 * 60 * warning.yellow # within 3 min.
          c = 'coming'
        new Handlebars.SafeString("<button class='do btn btn-raised " + c + "' data-name='" + name + "'>" + formatMin(rest) + "</button>")
      else
        if Flowcells.findOne(fc._id)[prevStep(name, typ)]
          new Handlebars.SafeString("<button class='do btn btn-raised " + c + "' data-name='" + name + "'>" + formatMin(rest) + "</button>")
        else ""

# You can choose "Fixing cell is not done" option.
  celltime_fixing: () ->
    t = this[name]
    if t
      new Handlebars.SafeString(formatDate(t) + "<span class='undo glyphicon glyphicon-remove' data-name='" + name + "'></span>")
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
        else if rest < 1000 * 60 * warning.yellow # within 3 min.
          c = 'coming'
        new Handlebars.SafeString("<button class='do " + c + "' data-name='" + name + "'>" + formatMin(rest) + "</button>")
      else
        if Flowcells.findOne(this._id)[prevStep(name)]
          new Handlebars.SafeString("<button class='do " + c + "' data-name='" + name + "'>" + formatMin(rest) + "</button>")
        else
          "No!"

  guideDisplay: () ->
    console.log( Session.get('guideMode'))
    if Session.get('guideMode') then 'block' else 'none'

  hiddenOnGuide: () ->
    if Session.get('guideMode') then 'hidden' else ''


Template.list.events(
  'click button.do': (e) ->
    n = $(e.target).attr('data-name')
    fid = $(e.target).parents('tr').attr('data-id')
    obj = {}
    obj[n] = new Date()
    Flowcells.update(fid, {$set: obj})
    renderProgress()

  'click .undo': (e) ->
    n = $(e.target).parents('td').attr('data-name')
    console.log($(e.target), $(e.target).parents('td'))
    fid = $(e.target).parents('tr').attr('data-id')
    if window.confirm('Are you sure to undo this?: ' + n)
      obj = {}
      obj[n] = ""
      Flowcells.update(fid, {$unset: obj})
      renderProgress()

  'click #newfc': () ->
    eid = Session.get('exp_active')
    exp = Exps.findOne(eid)
    num = Flowcells.find({exp: eid}).count() + 1
    protocol = Protocols.findOne({name: exp.expType || 'default'})
    Flowcells.insert({owner: Meteor.userId() || 'sandbox', name: (protocol.sample_name ||'FC') + num, createOn: new Date(), exp: eid})
    renderProgress()

  'click #toggle-time': () ->
    Session.set('showTime', !Session.get('showTime'))

  'click .edit': (e, tmpl) ->
    Session.set('editing', this._id)

  'click .ok': (e, tmpl) ->
    n = $(tmpl.find('.name-input')).val()
    Flowcells.update(this._id, {$set: {name: n}})
    Session.set('editing', null)

  'click .cancel': (e, tmpl) ->
    Session.set('editing', null)

  'click .remove': (e, tmpl) ->
    if window.confirm('Are you sure you want to remove this? This cannot be undone.')
      Flowcells.remove(this._id)
    Session.set('editing', null)

  'keydown .name-input': (e, tmpl) ->
    if e.keyCode == 13
      n = $(tmpl.find('.name-input')).val()
      Flowcells.update(this._id, {$set: {name: n}})
      Session.set('editing', null)
    else if e.keyCode == 27
      Session.set('editing', null)
)

calcPlannedTime = (fc, n, steps) ->
  defaultInterval = 5
  for v,i in steps
    if not fc[v.name]
      break
  if i < steps.length - 1 and i >= 1
    t = 0
    for j in [i - 1..steps.length - 1]
      if n == steps[j].name
        break
      t += steps[j].duration || defaultInterval # 5 min as standard operation time.
    d3.time.minute.offset(fc[steps[i - 1].name], t)
  else defaultInterval

color = d3.scale.category20b()

renderProgress = ->
  eid = Session.get('exp_active')
  exp = Exps.findOne(eid)
  typ = exp?.expType || 'default'
  fcs = Flowcells.find({exp: eid}, {sort: {createOn: 1}}).fetch()
  svg = d3.select('svg')
  svg.selectAll('*').remove()
  protocol = Protocols.findOne({name: exp.expType || 'default'})
  timepoints = protocol.timepoints
  totalTime = protocol.totalTime
  from = _.chain(fcs).map((fc)-> _.min(_.values(fc))).min().value()
  to = _.max([d3.time.minute.offset(from, totalTime + 10), _.chain(fcs).map((fc)-> _.max(_.values(fc))).max().value()])
  console.log(from, to)
  x = d3.scale.linear().domain([from, to]).range([0, 900])
  tn = _.map(timepoints, (t)-> t.name)
  gs = svg.selectAll('g').data(fcs, (d)-> d._id).enter().append('g')
  .attr('transform', (d, i) ->
    'translate (0,' + (i * 25 + 100) + ')'
  )
  .selectAll('g')
  .data(tn).enter()
  .append('g')
  .attr('transform', (d, ti, fc_i) ->
    xx = x(if fcs[fc_i] then (fcs[fc_i][d] || calcPlannedTime(fcs[fc_i], d, timepoints)) else calcPlannedTime(fcs[fc_i],
      d, timepoints))
    'translate(' + xx + ',0)'
  )

  gs.append('circle').attr({cx: 0})
  .attr('r', (d, ti, fc_i) -> if fcs[fc_i][d] then 6 else 6)
  .style('opacity', (d, ti, fc_i) -> if fcs[fc_i][d] then 1 else 0.4)
  .attr('fill', (d, i)-> color(i))
  gs.append('line')
  .attr({x1: 0, y1: 0, y2: 0})
  .attr('x2', (d, ti, fc_i) ->
    et = fcs[fc_i][nextStep(d, typ)] || d3.time.minute.offset((fcs[fc_i][d] || calcPlannedTime(fcs[fc_i], d,
        timepoints)), timepoints[ti].duration)
    x(et) - x(fcs[fc_i][d] || calcPlannedTime(fcs[fc_i], d, timepoints))
  )
  .style({stroke: (d, i)-> color(i)})
  .style('opacity', (d, ti, fc_i) -> if fcs[fc_i][nextStep(d, typ)] then 1 else 0.4)
  .style('stroke-width', 2)
  svg.append('g')
  .attr('transform', (d, i) -> 'translate (' + x(new Date()) + ',40)')
  .append('polygon')
  .attr('points', "0,0 -5,-10 5,-10")
  .attr('fill', (d, i)-> 'red')
  xAxis = d3.svg.axis().scale(x)
  .ticks(10).tickFormat((d)->
    moment(d).format('H:mm')
  )
  #    .orient('top')


  svg.append('g').attr('class', 'x axis')
  .attr('transform', 'translate(0,50)')
  .call(xAxis)

Template.list.rendered = ->
  renderProgress()


get_mynextsteps = () ->
  eid = Session.get('exp_active')
  exp = if eid then Exps.findOne(eid) else null
  typ = exp?.expType || 'default'
  steps = []
  fcs = Flowcells.find({exp: eid}, {sort: {createOn: 1}}).fetch()
  timepoints = Protocols.findOne({name: (typ || 'default')}).timepoints
  for fc in fcs
    for tp2 in timepoints
      t = fc[tp2.name]
      config = Config.findOne()
      warning = {yellow: 3}
      tp = fc[prevStep(tp2.name, typ)]
      if !t and tp
        dur = (_.findWhere(timepoints, {name: prevStep(tp2.name, typ)})?.duration || 0) * 60 * 1000
        elapsed = Session.get('time') - tp
        if dur == 0
          steps.push({fc: fc,name: tp2.name, fullname: tp2.fullname || tp2.name , time: null, lasttime: tp})
        else
          rest = dur - elapsed
          c = ''
          #          console.log(dur,elapsed,rest)
          if rest < 0
            c = 'late'
          else if rest < 1000 * 60 * warning.yellow # within 3 min.
            c = 'coming'
          steps.push({fc: fc,name: tp2.name, fullname: tp2.fullname || tp2.name , time: rest, lasttime: tp})
  steps

Template.guide.helpers
  formatTime: (tp) ->
    t = tp.time
#    console.log(t)
    if t == null
      '('+Math.max(0,Math.floor((Session.get('time')-tp.lasttime)/(1000*60)))+' min since the last step)'
    else
      if t >= 1000*60*60
        # Subtract 9 hours (epoch is 9:00 am) to have correct hour.
        moment(t).subtract(9, 'hours').format('h:mm:ss') + ' from now'
      else if t < -1000*60*60
        moment(-t).format('h:mm:ss') + ' past'
      else if t < 0
        moment(-t).format('m:ss') + ' past!'
      else
        # Subtract 9 hours (epoch is 9:00 am) to have correct hour.
        moment(t).subtract(9, 'hours').format('m:ss') + ' from now.'

  mynextsteps: () ->
    get_mynextsteps()

  finishEstimate: () ->
    eid = Session.get('exp_active')
    exp = Exps.findOne(eid)
    protocol = Protocols.findOne({name: exp.expType || 'default'})
    fcs = Flowcells.find({exp: eid}, {sort: {createOn: 1}}).fetch()
    last = protocol.timepoints[protocol.timepoints.length-1].name
    ts = []
    for fc in fcs
      ts.push calcPlannedTime(fc,last,protocol.timepoints)
    moment(_.max(ts)).format('h:mm')

  blinking: (step) ->
    if step.time
      if step.time < -1000*60
        'step-late2'
      else if step.time < 0
        'step-late'
      else if step.time < 1000*60*3
        'step-coming'
      else
        ''
    else
      ''

  selected: (step) ->
    idx = _.indexOf(_.map(get_mynextsteps(),(s) -> s.fc._id), step.fc._id)
    if idx == Session.get("guideCurrentFC") then "selected" else ""

Template.guide.events
  'click button.do': (e) ->
    n = $(e.target).attr('data-name')
    fid = $(e.target).parents('tr').attr('data-id')
    obj = {}
    obj[n] = new Date()
    Flowcells.update(fid, {$set: obj})
    renderProgress()

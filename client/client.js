var formatDate = function(d) {
  return "" + d.getHours() + ":" + d.getMinutes() + ":" + d.getSeconds();
};

var formatMin = function(v) {
  var vv = Math.abs(v);
  var s = Math.round(vv/1000);
  return "" + Math.floor(s/60) + "'" + s % 60 +'"';
};

var steps = ['dry','TBS','SUVmix','SUV','SUVwash','Ni','Niwash','HF','protein','proteinwash',
  'heating','cells','fix','fixwash'];
 
var prevStep = function(n) {
  var i = steps.indexOf(n);
    return (i>0) ? steps[i-1] : undefined;
};

Session.setDefault('editing',null);

Template.exps.exps = function(){
  return Exps.find({},{sort: {createOn: 1}});
};

Template.exps.active = function() {
  return Session.equals('exp_active',this._id) ? 'active' : '';
};

Template.exps.editing = function() {
  return Session.equals('editing',this._id);
};


Template.exps.events = {
  'click #add-exp': function(e){
    var d = new Date();
    var s_base = d.getMonth() + "/" + d.getDate() + "/" + +d.getFullYear();
    var s = s_base;
    var n = 2;
    while(Exps.find({name: s}).count() > 0){
      s = s_base + "-" + n;
      n += 1;
    }
    Exps.insert({name: s, createOn: new Date()});
  },
  'click .expentry': function(e){
    Session.set('exp_active',this._id);
  },
  'click .edit': function(e,tmpl){
    Session.set('editing',this._id);    
  },
  'click .ok': function(e,tmpl) {
    var s = $(tmpl.find('#nameinput')).val();
    Exps.update(this._id,{name: s});
    Session.set('editing',null);
  },
  'click .cancel': function(e) {
    Session.set('editing',null);
  },
  'click .remove': function(e) {
    if(window.confirm('Are you sure you want to remove this? This cannot be undone.')){
      Exps.remove(this._id);
    }
  },
  'dblclick .active': function(e) {
    Session.set('editing',this._id);
  },
  'keydown #nameinput':function(e,tmpl){
    if(e.keyCode == 13){
      var s = $(tmpl.find('#nameinput')).val();
      Exps.update(this._id,{name: s});
      Session.set('editing',null);
    }else if(e.keyCode == 27){
     Session.set('editing',null);      
    }
  }
};


Template.right_pane.exp_selected = function() {
  return !!Session.get('exp_active');
};


//
// Template.list
//

Template.list.flowcells = function () {
  var eid = Session.get('exp_active');
  return Flowcells.find({exp: eid},{sort: {createOn: 1}});
};

Template.list.exp_name = function(){
  var eid = Session.get('exp_active');
  var exp = eid ? Exps.findOne(eid) : null;
  return exp ? exp.name : " ";
}

Template.list.events({
  'click button.do': function(e) {
      var n = $(e.target).attr('data-name');
      var obj = {};
      obj[n] = new Date();
      Flowcells.update(this._id,{$set: obj});
  },
  'click .undo': function(e) {
    var n = $(e.target).attr('data-name');
    if(window.confirm('Are you sure?: '+this.name)){
      var obj = {};
      obj[n] = "";
      console.log(obj,this._id);
      Flowcells.update(this._id,{$unset: obj});
    }
  },
  'click #newfc': function() {
    var eid = Session.get('exp_active');      
    var num = Flowcells.find({exp: eid}).count() + 1;
    var e = Session.get('exp_active');
    Flowcells.insert({name: "FC"+num, createOn: new Date(), exp: e});
  },
  'click .edit': function(e,tmpl) {
    Session.set('editing',this._id);
//      activateInput(tmpl.find(".name-input"));    
  },
  'click .ok': function(e,tmpl) {
    var n = $(tmpl.find('.name-input')).val();
    Flowcells.update(this._id,{$set: {name: n}});
    Session.set('editing',null);      
  },
  'click .cancel': function(e,tmpl) {
    Session.set('editing',null);
  },
  'click .remove': function(e,tmpl) {
    if(window.confirm('Are you sure you want to remove this? This cannot be undone.')){
      Flowcells.remove(this._id);
    }    
    Session.set('editing',null);
  },
  'keydown .name-input':function(e,tmpl){
    if(e.keyCode == 13){
      var n = $(tmpl.find('.name-input')).val();
      Flowcells.update(this._id,{$set: {name: n}});
      Session.set('editing',null);
    }else if(e.keyCode == 27){
     Session.set('editing',null);      
    }
  }

});

Template.list.editing = function() {
  return Session.get('editing') == this._id;
};
Template.list.done = function(name) {
  return (!!this[name] ? "done" : "");
};
Template.list.cell = function(name) {
  var t = this[name];
  if(t) {
    return new Handlebars.SafeString(formatDate(t)+"<span data-name='"+name+"' class='undo glyphicon glyphicon-remove'></span>");      
  }else {
    var ps = prevStep(name);
    if(name == "dry" || this[ps]){
      return new Handlebars.SafeString("<button class='do' data-name='"+name+"'>Do</button>");
    }else{
      return "";
    }
  }
};
Template.list.celltime = function(name){
  var t = this[name];
  if(t) {
    return new Handlebars.SafeString(formatDate(t)+"<span class='undo glyphicon glyphicon-remove' data-name='"+name+"'></span>");      
  }else {
    var config = Config.findOne();
    var duration = config.duration;
    var warning = config.warning;
    var tp = this[prevStep(name)];
    if(tp){
      var dur = duration[prevStep(name)] * 60 * 1000;
      var elapsed = Session.get('time') - tp;
      var rest = dur - elapsed;
      var c='';
      if(rest < 0){
        c = 'late';
      } else if(rest < 1000*60*warning.yellow){  // within 3 min.
        c = 'coming';
      }
      return new Handlebars.SafeString("<button class='do "+c+"' data-name='"+name+"'>"+formatMin(rest)+"</button>");
    }else{
      return (Flowcells.findOne(this._id)[prevStep(name)] ?
          new Handlebars.SafeString("<button class='do "+c+"' data-name='"+name+"'>"+formatMin(rest)+"</button>")
          : "");
    }
  }
};


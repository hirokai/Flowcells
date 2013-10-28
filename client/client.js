var formatDate = function(d) {
  return "" + d.getHours() + ":" + d.getMinutes() + ":" + d.getSeconds();
};

var formatMin = function(v) {
  var vv = Math.abs(v);
  var s = Math.round(vv/1000);
  return "" + Math.floor(s/60) + "m" + s % 60 +"s";
};

var steps = ['dry','TBS','SUVmix','SUV','SUVwash','Ni','Niwash','HF','protein','proteinwash'];
var prevStep = function(n) {
  var i = steps.indexOf(n);
    return (i>0) ? steps[i-1] : undefined;
};

Session.setDefault('editing',null);

Template.exps.exps = function(){
  return Exps.find();
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
    Exps.insert({name: s});
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
    Exps.remove(this._id);
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
  'click button.undo': function(e) {
    var n = $(e.target).attr('data-name');
    var obj = {};
    obj[n] = "";
    console.log(obj,this._id);
    Flowcells.update(this._id,{$unset: obj});
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
    Session.set('editing',null);
    Flowcells.remove(this._id);
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
    return new Handlebars.SafeString(formatDate(t)+"<button class='undo' data-name='"+name+"'>Undo</button>");      
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
    return new Handlebars.SafeString(formatDate(t)+"<button class='undo' data-name='"+name+"'>Undo</button>");      
  }else {
    var tp;
    var dur;
    var duration = Config.findOne().duration;
    if(name=='SUVwash'){
      tp = this['SUV'];
      dur = duration['SUV'] * 60 * 1000;
    }else if (name=='Niwash'){      
      tp = this['Ni'];
      dur = duration['Ni'] * 60 * 1000;        
    }else if (name=='proteinwash'){
      tp = this['protein'] * 60 * 1000;
      dur = duration['protein'];        
    }
    if(tp){
      var elapsed = Session.get('time') - tp;
      var rest = dur - elapsed;
      var c='';
      if(rest < 0){
        c = 'late';
      } else if(rest < 1000*60*3){  // within 3 min.
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


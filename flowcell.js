 Flowcells = new Meteor.Collection('flowcells');
 Config = new Meteor.Collection('config');
 Exps = new Meteor.Collection('exps');


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


////////// Helpers for in-place editing //////////

// Returns an event map that handles the "escape" and "return" keys and
// "blur" events on a text input (given by selector) and interprets them
// as "ok" or "cancel".
var okCancelEvents = function (selector, callbacks) {
  var ok = callbacks.ok || function () {};
  var cancel = callbacks.cancel || function () {};

  console.log('hey');
  var events = {};
  events['keyup '+selector+', keydown '+selector+', focusout '+selector] =
    function (evt) {
      if (evt.type === "keydown" && evt.which === 27) {
        // escape = cancel
        cancel.call(this, evt);

      } else if (evt.type === "keyup" && evt.which === 13 ||
                 evt.type === "focusout") {
        // blur/return/enter = ok/submit if non-empty
        var value = String(evt.target.value || "");
        if (value)
          ok.call(this, value, evt);
        else
          cancel.call(this, evt);
      }
    };

  return events;
};

var activateInput = function (input) {
  input.focus();
  input.select();
};

if (Meteor.isClient) {
  Meteor.loginWithGoogle();

  var checkTimeLapse = function(){
    Session.set('time',new Date());
  };  
  
  Session.setDefault('editing',null);
  
  Template.list.flowcells = function () {
    var eid = Session.get('exp_active');
    return Flowcells.find({exp: eid},{sort: {createOn: 1}});
  };

  Template.list.exp_name = function(){
    var eid = Session.get('exp_active');
    return eid ? Exps.findOne(eid).name : " ";
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
    'focusout .name-input':  function(e,tmpl) {
      Session.set('editing',null);
    },
    'click button.ok': function(e,tmpl) {
      var n = $(e.target).val();
      console.log(n,'hi');
      Flowcells.update(this._id,{$set: {name: n}});
      Session.set('editing',null);      
    },
    'click .ebtn.cancel': function(e,tmpl) {
      Session.set('editing',null);
    },
    'click .ebtn.remove': function(e,tmpl) {
      Session.set('editing',null);
      Flowcells.remove(this._id);
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
  window.setInterval(checkTimeLapse,1000);
}

var truef = function(){return true;};

if (Meteor.isServer) {
  Meteor.startup(function () {
    // code to run on server at startup
    
    // 
    Flowcells.allow({insert: truef, update: truef, remove: truef});


    Config.remove({});
    Config.insert({duration: {SUV: 40, Ni: 5, protein: 40}});

  });
}

function resetData(){
  
var sample_data = [
      {name: "FC1"}
    , {name: "FC2"}
    , {name: "FC3"}
    , {name: "FC4"}
    , {name: "FC5"}
];


    Flowcells.remove({});
    _.each(sample_data,function(d){
        Flowcells.insert(d);
    });
}


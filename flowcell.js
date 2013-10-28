 Flowcells = new Meteor.Collection('flowcells');
 Config = new Meteor.Collection('config');
 Exps = new Meteor.Collection('exps');


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
  
  window.setInterval(checkTimeLapse,1000);
}

var truef = function(){return true;};

if (Meteor.isServer) {
  Meteor.startup(function () {
    // code to run on server at startup
    
    // 
    Flowcells.allow({insert: truef, update: truef, remove: truef});


    Config.remove({});
    Config.insert({
      duration: {SUV: 40, Ni: 5, protein: 40, heating: 20, cells: 20, fix: 10},
      warning: {yellow: 3}
    });

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


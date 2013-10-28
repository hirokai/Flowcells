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

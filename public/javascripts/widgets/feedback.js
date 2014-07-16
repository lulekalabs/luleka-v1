if(typeof(Luleka) == "undefined")
	var Luleka = {};

if(typeof(Luleka.Feedback) == "undefined") 
	Luleka.Feedback = {
		/* closes the feedback dialog */
		close: function() {
			alert('close feedback');
		}
	}

/* DefaultFields */
Luleka.Feedback.DefaultFields = {
  initialize: function() {
    $$('label.prompted').each(function(label) {
  	  if (label.htmlFor) {
  	    input = $(label.htmlFor)
        if (input) {
          Luleka.Feedback.DefaultFields.hideLabelUnlessEmptyOf(input);
    	    Event.observe(input, "keypress", function(event) {
  	        if (this.value.length >= 0) Luleka.Feedback.DefaultFields.hideLabelOf(this);
    			});
    	    Event.observe(input, "keyup", function(event) {
    	      if (event.keyCode == 8 && this.value.length == 0) Luleka.Feedback.DefaultFields.showLabelOf(this, "#cccccc");
    			});
    	    Event.observe(input, "focus", function(event) {
    	      Luleka.Feedback.DefaultFields.lightenLabelOf(this)
    			});
      	  Event.observe(input, "blur", function(event) {
    	      Luleka.Feedback.DefaultFields.showLabelOf(this, "#cccccc");
    	      Luleka.Feedback.DefaultFields.darkenLabelOf(this);
    			});
    		}
  	  }
  	});
  },
	clear: function() {
    $$('label.prompted').each(function(label) {
  	  if (label.htmlFor) {
  	    input = $(label.htmlFor)
        if (input) {
					input = Element.extend(input);
					input.value = "";
					input.setStyle({backgroundColor: ''});
					Luleka.Feedback.DefaultFields.showLabelOf(input);
    		}
  	  }
  	});
	},
  hideLabelUnlessEmptyOf: function(input) {
    if (input != null && input.value.length != 0) {
      Luleka.Feedback.DefaultFields.hideLabelOf(input);
    }
  },
  hideLabelOf: function(input) {
    label = input.up().getElementsByTagName('label')[0]
    if (label) {
      Element.extend(label).setStyle({color: '#858585'}).hide();
    }
  },
  lightenLabelOf: function(input) {
    label = input.up().getElementsByTagName('label')[0]
    if (label) {
      Element.extend(label).morph('color: #cccccc;', {duration: 0.15});
    }
  },
  darkenLabelOf: function(input) {
    label = input.up().getElementsByTagName('label')[0]
    if (label) {
      Element.extend(label).morph('color: #858585;', {duration: 0.15});
    }
  },
  showLabelOf: function(input, color) {
    if (input.value == "") {
      label = input.up().getElementsByTagName('label')[0]
      if (label) {
        Element.extend(label).setStyle({color: color ? color : '#858585'}).show();
      }
    }
  }
};

/* Tabs */
Luleka.Feedback.Tabs = {
  select: function(kind) {
    id = $(Luleka.Feedback.Tabs.tabId(kind))

    active = id.up().getElementsByClassName('active')[0];
   
    // remove active class
    if (active) {
      if (active.hasClassName('first')) active.previous().addClassName('blank');
      active.previous().removeClassName('blankSolid');
      active.next().removeClassName('solidBlank');
      active.removeClassName('active');
    }

    // add active class to new active element id
    if (id.hasClassName('first')) {
      id.previous().removeClassName('blank');
      id.previous().addClassName('solid');
    } else {
      id.previous().addClassName('blankSolid');
    }
    id.next().addClassName('solidBlank');
    id.addClassName('active')

    // new header
    $$(".newHeader").each(function(element, index) {
      element.hide();
    });
    $(this.newHeaderId(kind)).show();

    // description
    $$(".description").each(function(element, index) {
      element.hide();
    });
    $(this.titleId(kind)).show();

    // list header
    $$(".listHeader").each(function(element, index) {
      element.hide();
    });
    $(this.listHeaderId(kind)).show();

    // list
    $$(".caseListContainer").each(function(element, index) {
      element.hide();
    });
    $(this.listId(kind)).show();

		// kind
    $('kase-kind').value = kind;
  },
  tabId: function(kind) {
    return "tab-" + kind;
  },
  newHeaderId: function(kind) {
    return "new-header-" + kind;
  },
  titleId: function(kind) {
    return "title-" + kind;
  },
  listHeaderId: function(kind) {
    return "list-header-" + kind;
  },
  listId: function(kind) {
    return "list-" + kind;
  }
};

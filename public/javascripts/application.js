/*
 * Registers a callback which copies the csrf token into the
 * X-CSRF-Token header with each ajax request.  Necessary to 
 * work with rails applications which have fixed
 * CVE-2011-0447
*/
Ajax.Responders.register({
  onCreate: function(request) {
    var csrf_meta_tag = $$('meta[name=csrf-token]')[0];

    if (csrf_meta_tag) {
      var header = 'X-CSRF-Token',
      token = csrf_meta_tag.readAttribute('content');

      if (!request.options.requestHeaders) {
        request.options.requestHeaders = {};
      }
      request.options.requestHeaders[header] = token;
    }
  }
});

var Luleka = {};

/* form */
Luleka.Form = {}
Luleka.Form.submit = function(id, key) {
	if (key && $('_property_key')) {
	  $('_property_key').value = key;
	}
	if (id) {
		if (isNaN(id)) {
			var form = document.forms[id];
		} else {
			var form = id
		}
	} else {
		var form = document.forms[0];
	}
	form.onsubmit ? (form.onsubmit() ? form.submit() : false) : form.submit();
}

Luleka.Form.scrollToFirstMessage = function() {
	if ($$('.boxRedTop')[0]) {
		Effect.ScrollTo($$('.boxRedTop')[0], {offset:-12});
	} else {
		if ($$('.boxYellowTop')[0]) {
			Effect.ScrollTo($$('.boxYellowTop')[0], {offset:-12});
		} else {
			if ($$('.boxTurquoisTop')[0]) {
				Effect.ScrollTo($$('.boxTurquoisTop')[0], {offset:-12});
			}
		}
	}
	return;
}

Luleka.Form.reset = function(id) {
	if (id == null || id == "") {
		document.forms.each(function(form) {
			form.reset();
		});
	} else {
		document.forms[id].reset();
	}
}

Luleka.Form.Field = {}
Luleka.Form.Field.encrypt = function(fromFieldId, toFieldId, publicModulus, publicExponent) {
  var rsa = new RSAKey();
  rsa.setPublic(publicModulus, publicExponent);
  var res = rsa.encrypt($(fromFieldId).value);
  if (res) {
    var encrypted = linebrk(hex2b64(res), 64);
    $(toFieldId).value = encrypted;
    $(fromFieldId).value = '';
    return true;
  }
  return false;
} 

Luleka.Form.Switcher = {}
Luleka.Form.Switcher.open = function(id, sticky) {
	var switcher = $(id);
	var action = switcher.getElementsByClassName('switcherAction')[0];
	var content = action.next();
	var icon = action.getElementsByClassName('actionIcon')[0]
	
	if (content.style.display == 'none') {
		content.visualEffect("blind_down", {"duration":0.3})
		if (sticky) {
	  	icon.removeClassName('closed');
    	icon.addClassName('opened');
		} else {
			action.hide();
		}
  }
}
Luleka.Form.Switcher.close = function(id, sticky) {
	var switcher = $(id);
	var action = switcher.getElementsByClassName('switcherAction')[0];
	var content = action.next();
	var icon = action.getElementsByClassName('actionIcon')[0]
	
	if (content.style.display != 'none') {
		content.visualEffect("blind_up", {"duration":0.3})
		if (sticky) {
	  	icon.removeClassName('opened');
    	icon.addClassName('closed');
		} else {
			action.show();
		}
  }
}

Luleka.VisiblePasswordField = Class.create({
  initialize: function(pwFieldId, clFieldId, ckBoxId) {
		this.passwordFieldId = pwFieldId;
		this.clearFieldId = clFieldId;
		this.checkBoxId = ckBoxId;
		
		this.passwordFieldElement = $(this.passwordFieldId)
		this.clearFieldElement = $(this.clearFieldId)
		this.checkBoxElement = $(this.checkBoxId)
		
		this.showFields();
		
		Event.observe(this.checkBoxId, "change", this.showFields.bind(this));
		
		Event.observe(this.passwordFieldId, "keyup", function() {
			if (this.checkBoxElement.checked) {
				this.passwordFieldElement.value = this.clearFieldElement.value;
			} else {
				this.clearFieldElement.value = this.passwordFieldElement.value;
			}
		}.bind(this));
		
		Event.observe(this.passwordFieldId, "keyup", function() {
			if (this.checkBoxElement.checked) {
				this.passwordFieldElement.value = this.clearFieldElement.value;
			} else {
				this.clearFieldElement.value = this.passwordFieldElement.value;
			}
		}.bind(this));

		Event.observe(this.clearFieldId, "keyup", function() {
			if (this.checkBoxElement.checked) {
				this.passwordFieldElement.value = this.clearFieldElement.value;
			} else {
				this.clearFieldElement.value = this.passwordFieldElement.value;
			}
		}.bind(this));

  },
	showFields: function() {
		if (this.checkBoxElement.checked) {
			this.passwordFieldElement.value = this.clearFieldElement.value;
			this.passwordFieldElement.hide();
			this.clearFieldElement.show();
		} else {
			this.clearFieldElement.value = this.passwordFieldElement.value;
			this.passwordFieldElement.show();
			this.clearFieldElement.hide();
		}
	}
});

/* facebook helpers */
Luleka.Facebook = Class.create({
	initialize: function(id, url, authtoken, options) {
		this.callbackURL = url;
		this.authenticityToken = authtoken;
		this.options = $H({
			'perms': 'email,publish_stream'
		}).update(options);
		
		if (id) {
			this.observe(id);
		}
	},
	observe: function(id) {
		Event.observe(id, "click", function() {
			this.session();
		}.bind(this));
	},
	session: function() {
		// FB.Connect.requireSession(this.acceptCallback.bind(this), this.cancelCallback.bind(this));
		FB.login(this.callback.bind(this), this.options.get('perms'));
	},
	callback: function(response) {
		this.response = response;
		if (response.session) {
			this.acceptCallback();
		} else {
			this.cancelCallback();
		}
	},
	acceptCallback: function() {
		new Ajax.Request(this.callbackURL, {
			asynchronous:true, 
			evalScripts:true, 
			method:'get',
			parameters:{
				'authenticity_token': encodeURIComponent(this.authenticityToken ? this.authenticityToken : ""),
				'perms': this.response.perms, 'status': this.response.status, 'redirect_to': this.options.get('redirect_to')
			}
		});
	},
	cancelCallback: function() {
	}
});
Luleka.Facebook.observe = function(id, url, authtoken, options) {
	var fbBtn = new Luleka.Facebook(id, url, authtoken, options);
};
Luleka.Facebook.session = function(url, authtoken, options) {
	var fbBtn = new Luleka.Facebook(null, url, authtoken, options);
	fbBtn.session();
};

/* search */
Luleka.Search = {}
Luleka.Search.prettify = function(element, useFake) {
	isSafari = (navigator.userAgent.indexOf("Safari") > 0);
	if (element instanceof Event) {
		elements = document.getElementsByClassName('search', null, 'input');
		for (var i = 0; i < elements.length; i++) {
			if (!isSafari || useFake) { 
				Luleka.Search.fakeSearchInput(elements[i]);
			} else { 
				Luleka.Search.makeSearchInput(elements[i]);
			}
		}
	} else if (element) {
		!isSafari || useFake ? Luleka.Search.fakeSearchInput(element) : Luleka.Search.makeSearchInput(element);
	}
}

Luleka.Search.makeSearchInput = function(element) {
	element.type = 'search';
	element.setAttribute('placeholder', element.value);
	element.setAttribute('autosave', 'luleka.com'); // change this to your own domain name or whatever else 
	element.setAttribute('results', '5');
}

Luleka.Search.fakeSearchInput = function(element) {
	if (element.parentNode.className.indexOf('prettySearch') != -1) return;
	if (element.type.indexOf('text') == -1) return;
	Event.observe(element, 'click', function() { if (element.value == 'Search') element.value = '' });
	Event.observe(element, 'focus', function() { element.parentNode.className = 'prettySearch prettySearchActive' });
	Event.observe(element, 'blur',  function() { element.parentNode.className = 'prettySearch' });
	Event.observe(element, 'keyup', function() {
		if (element.value == '') {
			Element.extend(element.parentNode).getElementsByClassName("reset")[0].style.display = 'none';
		} else {
			Element.extend(element.parentNode).getElementsByClassName("reset")[0].style.display = '';
		}
	});
	
	container = document.createElement('div');
	container.className = 'prettySearch';
	container.style.width = element.innerWidth + 'px';
	left = document.createElement('div');
	left.className = 'left';
	right = document.createElement('div');
	right.className = 'right';
	reset = document.createElement('div');
	reset.className = 'reset';
	if (element.value == '') reset.style.display = 'none';
	Event.observe(reset, 'click', function() {
		Element.extend(this.parentNode).getElementsBySelector('input')[0].value = '';
		Element.extend(this.parentNode).getElementsBySelector('input')[0].activate();
		this.style.display = 'none';
	});

	
	element.parentNode.insertBefore(container, element);
	element.parentNode.removeChild(element);
	container.appendChild(left);
	container.appendChild(right);
	container.appendChild(reset);
	if (element.className.indexOf('auto') != -1) {
		progress = document.createElement('div');
		progress.className = 'progress';
		spinner = document.createElement('img');
		spinner.src = "/images/css/spinner_grey.gif";
		progress.appendChild(spinner);
		container.appendChild(progress);
	}
	container.appendChild(element);
}
document.observe('dom:loaded', Luleka.Search.prettify);

/* global search */
Luleka.GlobalSearch = {}
Luleka.GlobalSearch.initialize = function(element) {
	var $field = $('globalsearch');
	if ($field) {
		var $reset = $($field.up(1)).getElementsByClassName("reset")[0];
		if ($field.value == '') $reset.style.display = 'none';
		Event.observe($field, 'keyup', function() {
			if (this.value == '') {
				$reset.style.display = 'none';
			} else {
				$reset.style.display = '';
			}
		});
		Event.observe($reset, 'click', function() {
			Element.extend(this.parentNode).getElementsBySelector('input')[0].value = '';
			Element.extend(this.parentNode).getElementsBySelector('input')[0].activate();
			this.style.display = 'none';
		});
	}
}
document.observe('dom:loaded', Luleka.GlobalSearch.initialize);

/* modal */
Luleka.Modal = {}
Luleka.Modal.instance = function() {
	return facebox ? facebox : fb;
}

Luleka.Modal.element = function() {
	return Luleka.Modal.instance() ? Luleka.Modal.instance().facebox : $('facebox');
}

Luleka.Modal.visible = function() {
	return Luleka.Modal.element() ? Luleka.Modal.element().visible() : false;
}

Luleka.Modal.close = function() {
	return Luleka.Modal.instance() ? Luleka.Modal.instance().close() : false;
}

Luleka.Modal.delayClose = function(seconds) {
	setTimeout(Luleka.Modal.close, seconds || 5);
}

/* tab header */
Luleka.TabHeader = Class.create({
  initialize: function(element) {
    this.setup(element);
	},
	setup: function(element) {
    var items = element.getElementsBySelector("li");
		for (var J = 0; J < items.length; J++) {
		  if (!items[J].hasClassName("separator")) {
  			Event.observe(items[J], "click", function(event) {
  			  this.removeClassName("active");
          var siblings = this.siblings();
      		for (var S = 0; S < siblings.length; S++) {
      	    siblings[S].removeClassName("active");
      	    siblings[S].removeClassName("activeInactive");
      	    siblings[S].removeClassName("inactiveActive");
      	  }

          // now set active
          this.previous().hasClassName("first") ? 
            this.previous().addClassName("active") : 
              this.previous().addClassName("inactiveActive");

          this.addClassName("active");

          this.next().hasClassName("last") ? 
            this.next().addClassName("active") : 
              this.next().addClassName("activeInactive");
          
  			});
		  }
		}
	}
});

Luleka.TabHeader.observe = function(id) {
  if ($(id)) {
    var tbHd = new Luleka.TabHeader($(id)); 
  } else {
    var headers = $$('.tabHeader');
		for (var J = 0; J < headers.length; J++) {
			var nwTbHd = new Luleka.TabHeader(headers[J]);
		}
  }
}

document.observe('dom:loaded', function() {
  Luleka.TabHeader.observe();
});

/* default fields */
Luleka.DefaultFields = {
  initialize: function() {
    $$('label.prompted').each(function(label) {
  	  if (label.htmlFor) {
  	    var input = $(label.htmlFor)
        if (input) {
    	    Event.observe(input, "keypress", function(event) {
  	        if (this.value.length >= 0) Luleka.DefaultFields.hideLabelOf(this);
    			});
    	    Event.observe(input, "keyup", function(event) {
    	      if (event.keyCode == 8 && this.value.length == 0) Luleka.DefaultFields.showLabelOf(this, "#cccccc");
    			});
    	    Event.observe(input, "focus", function(event) {
						var $wrap = this.up(".fieldwrap");
						if ($wrap) {
							Element.extend($wrap).morph('border-color: #008CDC;', {duration: 0.25});
						}
						if (this.value.length > 0) {
							Luleka.DefaultFields.hideLabelOf(input);
						} else {
							Luleka.DefaultFields.lightenLabelOf(this)
						}
    			});
      	  Event.observe(input, "blur", function(event) {
						var $wrap = this.up(".fieldwrap");
						if ($wrap) {
							Element.extend($wrap).morph('border-color: #A5E0F9;', {duration: 0.25});
						}
    	      Luleka.DefaultFields.showLabelOf(this, "#cccccc");
    	      Luleka.DefaultFields.darkenLabelOf(this);
    			});
          Luleka.DefaultFields.hideLabelUnlessEmptyOf(input);
    		}
  	  }
  	});
  },
	clear: function() {
    $$('label.prompted').each(function(label) {
  	  if (label.htmlFor) {
  	    var $input = $(label.htmlFor)
        if ($input) {
					$input = Element.extend($input);
					$input.value = "";
					$input.setStyle({backgroundColor: ''});
					Luleka.DefaultFields.showLabelOf($input);
    		}
  	  }
  	});
	},
  hideLabelUnlessEmptyOf: function(input) {
    if (input != null && input.value.length != 0) {
      Luleka.DefaultFields.hideLabelOf(input);
    }
  },
  hideLabelOf: function(input) {
    var $label = input.up().getElementsBySelector("label")[0] || input.up().previousSiblings("label").first();
    if ($label && $label.visible()) {
      Element.extend($label).setStyle({color: '#333'}).hide();
    }
  },
  lightenLabelOf: function(input) {
    var $label = input.up().getElementsBySelector("label")[0] || input.up().previousSiblings("label").first();
    if ($label) {
      Element.extend($label).morph('color: #ddd;', {duration: 0.25});
    }
  },
  darkenLabelOf: function(input) {
    var $label = input.up().getElementsBySelector("label")[0] || input.up().previousSiblings("label").first();
    if ($label) {
      Element.extend($label).morph('color: #333;', {duration: 0.25});
    }
  },
  showLabelOf: function(input, color) {
		var $input = $(input);
    if ($input.value == "") {
      var $label = input.up().getElementsBySelector("label")[0] || $input.up().previousSiblings("label").first();
      if ($label && !$label.visible()) {
        Element.extend($label).setStyle({color: color ? color : '#333'}).show();
      }
    }
  }
};
document.observe('dom:loaded', Luleka.DefaultFields.initialize);

/* pcard */
Luleka.Pcard = {}
Luleka.Pcard.observer = function() {
	/* pcard links */
  $$('a.pcard[rel]').each(function(element) {
		if (typeof(element.retrieve('pcardel')) == 'undefined') {
			var pcard = new Tip(element, {
				ajax: {
					url: element.rel,
					options: {method: 'get'}
				},
	      style: 'pcard',
	      showOn: 'mouseover',
				delay: 0.5,
				hook: {target: 'bottomLeft', tip: 'topLeft', mouse: false},
				hideOn: {element: 'tip', event: 'mouseleave'},
	      offset: {x: -66, y: -33},
	      hideOthers: true,
	      width: 'auto'
	    });
			element.store('pcardel', pcard);
		}
  });
}
document.observe('dom:loaded', Luleka.Pcard.observer);
document.observe('dom:updated', Luleka.Pcard.observer);

/* checkbox radio fixes */
document.observe('dom:loaded', function() {
	$$("input[type='radio']").each(function(el) {
		el.addClassName('inputTypeRadio');
	});

	$$("input[type='checkbox']").each(function(e) {
		el.addClassName('inputTypeCheckbox');
	});
});

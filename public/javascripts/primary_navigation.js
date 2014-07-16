/* primary Navigation */
var primaryNavigation = function() {
	var items;
	var shim;
	var shimId = "nav-primary-shim";

	var openItem = function(item) {
		if (!item.hasClassName("open")) {
			closeAllItems();
			item.addClassName("open")
			openShim(item);
		} else {
			item.removeClassName("open")
			closeShim();
		}
	};

	var closeAllItems = function() {
		var items = $("primaryNavi").getElementsBySelector("li");
		for (var J = 0; J < items.length; J++) {
			items[J].removeClassName("open");
		}
		closeShim();
	};

	var createShim = function(naviId) {
		frame = new Element('iframe', {
      style: 'position:absolute;display:none;',
      src: 'javascript:false;',
			id: shimId,
      frameborder: 0
    });
    $(naviId).insert(frame);
		return $(shimId);
	};

	var openShim = function(item) {
		if (typeof shim != "undefined") {
			var element = item.getElementsByTagName("ul")[0];
			element = Element.extend(element);
			offset = element.cumulativeOffset();
			dimensions = element.getDimensions();
			style = {
        left: offset[0] + 'px',
        top: offset[1] + 'px',
        width: dimensions.width + 'px',
        height: dimensions.height + 'px',
				visibility: 'visible',
        zIndex: element.getStyle('zIndex') + 1
      };
      shim.setStyle(style).show();
		}
	};

	var closeShim = function() {
		if (typeof shim != "undefined") {
			style = {
        left: '-9999px',
        top: '0px'
      };
      shim.setStyle(style).hide();
		}
	};
	
	var setupObservers = function() {
		for (var K = 0; K < items.length; K++) {
			var item = items[K]
			var anchor = item.firstDescendant() && item.firstDescendant().tagName == "A" && item.classNames().include("nav") ? item.firstDescendant() : null;
			var span = anchor && anchor.firstDescendant() && anchor.firstDescendant().tagName == "SPAN" ? anchor.firstDescendant() : null;

			if (anchor) {
				Event.observe(anchor, "click", function(event) {
					Event.stop(event)
					openItem(this.up(0))
				});

				Event.observe(anchor, "mouseover", function() {
					this.addClassName("hover");
				});

				Event.observe(anchor, "mouseout", function() {
					this.removeClassName("hover");
				});
			}

			if (span) {
				Event.observe(span, "click", function(event) {
					event.stopPropagation();
				});

				Event.observe(span, "mouseover", function(event) {
					this.addClassName("hover");
					event.stopPropagation();
				});

				Event.observe(span, "mouseout", function(event) {
					this.removeClassName("hover");
				});
			}

			Event.observe(item, "click", function(event) {
				event.stopPropagation();
			});
		}
		Event.observe(document, "click", function(element, event) {
			closeAllItems();
		});
	};
	return {
		init: function() {
			if (!$("primaryNavi")) {
				return;
			}
			items = $("primaryNavi").childElements();
			if (Prototype.Browser.IE6) {
				shim = createShim("primaryNavi");
			}
			setupObservers();
		}
	};
} ();
document.observe('dom:loaded', primaryNavigation.init);
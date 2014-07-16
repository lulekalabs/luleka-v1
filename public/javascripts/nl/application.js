/* index.js  */
//jQuery.noConflict();
var pnuts = null;
(function($) { 

	stampMaps = {};

	function Stamp(name) {
		var _this = this;
		stampMaps[name] = stampMaps[name] || 1;

		this.get = function() {
			var index = ++stampMaps[name];
			return function() {
				return index == stampMaps[name];
			}
		};

		this.toggle = function() {
			isShow ? _this.show() : _this.hide;
		};
	};



	function Pane() {
		var _this = this;

		var q_outer = $('#pane-outer');
		var q_shell = $('#pane-shell');
		var q_base = $('#pane-base');
		var q_components = $('.pane-components');

		var q_closeButton = $('.pane-close', q_outer).click(function() {
			_this.hide();
		});

		$(window).scroll(function() {
			q_shell.css('left', -q_outer.offset().left);
		});

		var isShow = false;

		var stamp = null;

		this.setTitle = function() {
		};

		var clearHandlers = [];

		var handleClear = function() {
			$(clearHandlers).each(function() {
				this();
			});
			clearHandlers = [];
		};

		this.clear = function() {
			handleClear();
			q_components.html('');
		};	

		this.addComponent = function(component, clearHandler) {
			clearHandlers.push(clearHandler);

			return $('<div class="component"></div>')
			.append(component)
			.appendTo(q_components);
		};

		var pane_type = hostucan_pane_type || 'slide-right';

		var show_animate = function(callback) {

			var all_callback = function() {
				stamp() && callback && callback();
			};
			q_base.stop(true, true);
			switch(pane_type) {
				case "none":
				q_base.css('width', 540);
				q_outer.css('display', 'block');
				all_callback();
				break;
				case "fade":
				q_base.css('width', 540);
				q_outer.css('display', 'none');
				q_outer.fadeIn('fast', all_callback);
				break;
				default:
				q_outer.css('display', 'block');
				q_base
				.animate({ width: 540 }, 'fast', all_callback);
				break;
			}
		};

		var hide_animate = function(callback) {
			q_base
			.stop(true, true);

			var all_callback = function() {
				q_base.css('width', 0);
				q_outer.css('display', 'none');
				handleClear();
				stamp() && callback && callback();
			};

			switch(pane_type) {
				case "none":
				all_callback();
				break;
				case "fade":
				q_outer.fadeOut('fast', all_callback);
				break;
				default:		
				q_base.animate({ width: 0 }, 'fast', all_callback);
				break;
			}
		};



		this.show = function(callback) {		
			stamp = (new Stamp('Pane')).get();

			isShow || show_animate(callback);
			isShow = true;
		}

		this.hide = function(callback) {
			stamp = (new Stamp('Pane')).get();

			isShow && hide_animate(callback);
			isShow = false;
		}

		this.getComponents = function() {
			return q_components;
		};

		this.toggle = function(callback) {
			isShow ? this.hide(callback) : this.show(callback);
		}
	}

	var TeaserEntity = function(pane, entity) {
		var url = $(entity).find('.entry-title a, a.response-permalink').attr('href');

		var showContent = function(callback, position) {
			pane.clear();
			pane.show();		
			$(entity).addClass('focused');
			return pane.addComponent(
				$('<div></div>').load(url + ' #content .entries',
				function() {
					if(position && $(position, comp).length) {
						var paneComp = pane.getComponents();
						paneComp.scrollTop($(position, comp).offset().top - paneComp.offset().top);
					}
					callback();
				}
			), 
			function() {
				$(entity).removeClass('focused');
			});
		};

		var entity_show = function(position) {
			if(!url) { return false; }

			var refresh_callback = function() {
				$('form', comp).each(function() {
					$(this).submit(function() {
						$(this).ajaxSubmit({
							success: function() {
								comp = showContent(refresh_callback, '#comments');
							}
						});
						$(this).find('input, textarea').attr('disabled', 'disabled');
						return false;
					});
				});
			};

			comp = showContent(refresh_callback, position);
			return false;
		};		

		$(entity).click(function(event) {
			if($(event.target).is('.entry-date, .entry-meta a, .entry-utility a')) { return true; }
			if($(entity).hasClass('focused')) {
				pane.clear();
				pane.hide();
				return;
			}
			entity_show();
			return false;
		});

		$(entity).find('.comments-link a').click(function() {
			entity_show('#comments');
			return false;
		});	
	};

	$(function() {	

		var resize = function() {
			$("#container").css('min-height', Math.max($(window).height() - 60, $('#dashboard').height() + 20));
		}

		resize();
		$(window).resize(resize);

		var pane = new Pane();
		$('#container .post, #container .page').each(function() {
			new TeaserEntity(pane, this);
		});
		var lastMenu = $('#content .page_item:last');
		var menus = $('#content .menu');
		if(lastMenu.offset()) menus.height(lastMenu.offset().top - menus.offset().top + 31);
	});	
}(jQuery));

/* tipsy */
$(function() {
	$('.following15 img').tipsy({fade: true, gravity: 's'});
});

/* admin  */
(function($) {
	$(function() {
		var index = 1;
		var colorSchemes = [
		{
			"link_color": "#0084B4", 
			"sidebar_border_color": "#C0DEED", 
			"background_color": "#C0DEED", 
			"text_color": "#333333", 
			"name": "Default", 
			"sidebar_fill_color": "#DDEEF6", 
		}, 
		{
			"link_color": "#0084B4", 
			"sidebar_border_color": "#BDDCAD", 
			"background_color": "#9AE4E8", 
			"text_color": "#333333", 
			"name": "Classic Twitter", 
			"sidebar_fill_color": "#DDFFCC", 
		}, 
		{
			"link_color": "#1F98C7", 
			"sidebar_border_color": "#C6E2EE", 
			"background_color": "#C6E2EE", 
			"text_color": "#663B12", 
			"sidebar_fill_color": "#DAECF4", 
		}, 
		{
			"link_color": "#088253", 
			"sidebar_border_color": "#D3D2CF", 
			"background_color": "#EDECE9", 
			"text_color": "#634047", 
			"sidebar_fill_color": "#E3E2DE", 
		}, 
		{
			"link_color": "#0099B9", 
			"sidebar_border_color": "#5ED4DC", 
			"background_color": "#0099B9", 
			"text_color": "#3C3940", 
			"sidebar_fill_color": "#95E8EC", 
		}, 
		{
			"link_color": "#D02B55", 
			"sidebar_border_color": "#829D5E", 
			"background_color": "#352726", 
			"text_color": "#3E4415", 
			"sidebar_fill_color": "#99CC33", 
		}, 
		{
			"link_color": "#FF3300", 
			"sidebar_border_color": "#86A4A6", 
			"background_color": "#709397", 
			"text_color": "#333333", 
			"sidebar_fill_color": "#A0C5C7", 
		}, 
		{
			"link_color": "#990000", 
			"sidebar_border_color": "#DFDFDF", 
			"background_color": "#EBEBEB", 
			"text_color": "#333333", 
			"sidebar_fill_color": "#F3F3F3", 
		}, 
		{
			"link_color": "#9D582E", 
			"sidebar_border_color": "#D9B17E", 
			"background_color": "#8B542B", 
			"text_color": "#333333", 
			"sidebar_fill_color": "#EADEAA", 
		}, 
		{
			"link_color": "#2FC2EF", 
			"sidebar_border_color": "#181A1E", 
			"background_color": "#1A1B1F", 
			"text_color": "#666666", 
			"sidebar_fill_color": "#252429", 
		}, 
		{
			"link_color": "#FF0000", 
			"sidebar_border_color": "#65B0DA", 
			"background_color": "#642D8B", 
			"text_color": "#3D1957", 
			"sidebar_fill_color": "#7AC3EE", 
		}, 
		{
			"link_color": "#B40B43", 
			"sidebar_border_color": "#CC3366", 
			"background_color": "#FF6699", 
			"text_color": "#362720", 
			"sidebar_fill_color": "#E5507E", 
		}, 
		{
			"link_color": "#FF0000", 
			"sidebar_border_color": "#F2E195", 
			"background_color": "#BADFCD", 
			"text_color": "#0C3E53", 
			"sidebar_fill_color": "#FFF7CC", 
		}, 
		{
			"link_color": "#93A644", 
			"sidebar_border_color": "#eeeeee", 
			"background_color": "#B2DFDA", 
			"text_color": "#333333", 
			"sidebar_fill_color": "#ffffff", 
		}, 
		{
			"link_color": "#009999", 
			"sidebar_border_color": "#eeeeee", 
			"background_color": "#131516", 
			"text_color": "#333333", 
			"sidebar_fill_color": "#efefef", 
		}, 
		{
			"link_color": "#0084B4", 
			"sidebar_border_color": "#a8c7f7", 
			"background_color": "#022330", 
			"text_color": "#333333", 
			"sidebar_fill_color": "#C0DFEC", 
		}, 
		{
			"link_color": "#CC3366", 
			"sidebar_border_color": "#DBE9ED", 
			"background_color": "#DBE9ED", 
			"text_color": "#333333", 
			"sidebar_fill_color": "#E6F6F9", 
		}, 
		{
			"link_color": "#038543", 
			"sidebar_border_color": "#EEEEEE", 
			"background_color": "#ACDED6", 
			"text_color": "#333333", 
			"sidebar_fill_color": "#F6F6F6", 
		}, 
		{
			"link_color": "#0099CC", 
			"sidebar_border_color": "#fff8ad", 
			"background_color": "#FFF04D", 
			"text_color": "#333333", 
			"sidebar_fill_color": "#f6ffd1", 
		}, 
		{
			"link_color": "#BF1238", 
			"sidebar_border_color": "#FFFFFF", 
			"background_color": "#BF1238", 
			"text_color": "#333333", 
			"sidebar_fill_color": "#EFEFEF", 
		}
		];

		$(colorSchemes).each(function() {
			var themeName = this.name || "Theme " + index++;
			var button = [ 
			'<div class="built-in-theme">',
			themeName,
			'<ul>',
			'<li class="background-c" style="background: ',
			this.background_color,
			'"></li>',
			'<li class="text-c" style="background: ',
			this.text_color,
			'"></li>',
			'<li class="links-c" style="background: ',
			this.link_color,
			'"></li>',
			'<li class="sidebar-c" style="background: ',
			this.sidebar_fill_color,
			'"></li>',
			'<li class="sidebar-border-c" style="background: ',
			this.sidebar_border_color,
			'"></li>',
			'<div>'
			];

			var _this = this;
			$('#built-in-themes').append(
				$(button.join('')).click(function() {
					$('#hostucan_background_color').val(_this.background_color).focus().blur();
					$('#hostucan_text_color').val(_this.text_color).focus().blur();
					$('#hostucan_links_color').val(_this.link_color).focus().blur();
					$('#hostucan_sidebar_color').val(_this.sidebar_fill_color).focus().blur();
					$('#hostucan_sidebar_border_color').val(_this.sidebar_border_color).focus().blur();
				})
			);
		});

	});
	}(jQuery));

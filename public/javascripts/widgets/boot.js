if(typeof(Luleka) == "undefined")
	var Luleka = {};


Luleka.Util = {
	sslAssetHost: "https://www.luleka.com",
	assetHost: "http://www.luleka.com",
	locales: {"en": "en-US", "us": "en-US", "de": "de-DE", "es": "es-ES", "fr": "fr-FR", "ar": "es-AR", "mx": "es-MX", "cl": "es-CL", "ch": "de-CH", "br": "pt-BR", "pt": "pt-PT", "uk": "en-UK"},
	getAssetHost: function() {
		return ("https:" == document.location.protocol) ? this.sslAssetHost: this.assetHost;
	},
	setAssetHost: function(host) {
		this.sslAssetHost = "https://" + host;
		this.assetHost = "http://" + host;
	},
	render: function(template, params) {
		return template.replace(/\#{([^{}]*)}/g,
		function(a, b) {
			var r = params[b];
			return typeof r === 'string' || typeof r === 'number' ? r: a;
		})
	},
	toQueryString: function(params) {
		var pairs = [];
		for (key in params) {
			if (params[key] != null && params[key] != '') {
				pairs.push([key, params[key]].join('='));
			}
		}
		return pairs.join('&');
	},
	isIE6: function() {
		if (/MSIE (\d+\.\d+);/.test(navigator.userAgent)) {
			var version = new Number(RegExp.$1);
			return version < 7;
		} else {
			return false;
		}
	},
	includeCss: function(css) {
		var styleElement = document.createElement('style');
		styleElement.setAttribute('type', 'text/css');
		styleElement.setAttribute('media', 'screen');
		if (styleElement.styleSheet) {
			styleElement.styleSheet.cssText = css;
		} else {
			styleElement.appendChild(document.createTextNode(css));
		}
		document.getElementsByTagName('head')[0].appendChild(styleElement);
	},
	shortToLongLocaleCode: function(short) {
		return this.locales[short];
	},
	localeToLanguageCode: function(locale) {
		if (matchLang = /^([a-z]*)[-]{0,1}/i.exec((this.shortToLongLocaleCode(locale) || locale) + ' ')) {
			return matchLang[1].toLowerCase();
    }
	}
}

Luleka.Logger = {
	_log: function(message) {
		if (typeof console !== "undefined" && typeof console.log !== "undefined") {
			try {
				console.log(message);
			} catch(e) {}
		}
	},
	warning: function(message) {
		this._log("Luleka WARNING: " + message);
	},
	error: function(message) {
		this._log("Luleka ERROR: " + message);
		alert("Luleka ERROR: " + message);
	}
}

Luleka.Element = {
	getDimensions: function(element) {
		var display = element.display;
		if (display != 'none' && display != null) {
			return {
				width: element.offsetWidth,
				height: element.offsetHeight
			};
		}
		var els = element.style;
		var originalVisibility = els.visibility;
		var originalPosition = els.position;
		var originalDisplay = els.display;
		els.visibility = 'hidden';
		els.position = 'absolute';
		els.display = 'block';
		var originalWidth = element.clientWidth;
		var originalHeight = element.clientHeight;
		els.display = originalDisplay;
		els.position = originalPosition;
		els.visibility = originalVisibility;
		return {
			width: originalWidth,
			height: originalHeight
		};
	},
	hasClassName: function(element, className) {
		var elementClassName = element.className;
		return (elementClassName.length > 0 && (elementClassName == className || new RegExp("(^|\\s)" + className + "(\\s|$)").test(elementClassName)));
	},
	addClassName: function(element, className) {
		if (!this.hasClassName(element, className)) {
			element.className += (element.className ? ' ': '') + className;
		}
		return element;
	},
	removeClassName: function(element, className) {
		element.className = element.className.replace(new RegExp("(^|\\s+)" + className + "(\\s+|$)"), ' ');
		return element;
	}
}

Luleka.Page = {
	getDimensions: function() {
		var de = document.documentElement;
		var width = window.innerWidth || self.innerWidth || (de && de.clientWidth) || document.body.clientWidth;
		var height = window.innerHeight || self.innerHeight || (de && de.clientHeight) || document.body.clientHeight;
		return {
			width: width,
			height: height
		};
	}
}

Luleka.Dialog = {
	preload: function(id_or_html) {
		if (!this.preloaded) {
			var element = document.getElementById(id_or_html);
			var html = (element == null) ? id_or_html : element.innerHTML;
			this.setContent(html);
			this.preloaded = true;
		}
	},
	show: function(id_or_html) {
		if (!this.preloaded) {
			this.preload(id_or_html);
		}
		this.Overlay.show();
		this.setPosition();
		Luleka.Element.addClassName(this.htmlElement(), 'dialog-open');
		this.displayLoading();
		this.element().style.display = 'block';
		this.preloaded = false;
	},
	displayLoaded: function() {
		if (!this.loaded) {
			document.getElementById("lulekaDialogLoading").style.display = "none";
			document.getElementById("lulekaDialogOuter").style.display = "block";
			this.loaded = true;
		}
	},
	displayLoading: function() {
		if (!this.loaded) {
			document.getElementById("lulekaDialogLoading").style.display = "block";
			document.getElementById("lulekaDialogOuter").style.display = "none"
		}
		this.loaded = false;
	},
	close: function() {
		var change = Luleka.needsConfirm;
		if (change) {
			var answer = confirm(change);
			if (!answer) {
				return
			}
		}
		this.element().style.display = 'none';
		Luleka.Element.removeClassName(this.htmlElement(), 'dialog-open');
		this.Overlay.hide();
		Luleka.onClose();
	},
	id: 'lulekaDialog',
	css_template: "\
	#lulekaDialog {\
		display:block;\
		text-align:left;\
		margin:0 auto;\
		position:absolute;\
		z-index:100006;\
	}\
	\
	#lulekaDialogContent {\
		padding:0;\
		margin:0;\
		position:relative;\
		z-index:100006;\
		display:block;\
		width:auto;\
		height:auto;\
	}\
	\
	#lulekaOverlay {\
		z-index:100002;\
		position:absolute;\
		width:100%;\
		height:100%;\
		left:0;\
		top:0;\
		background-color:#000;\
		opacity:.3;\
		filter:alpha(opacity=70);\
	}\
	\
	#lulekaDialog[id],\
	#lulekaOverlay[id] {\
		position:fixed;\
	}\
	\
	#lulekaOverlay p {\
		padding:5px;\
		color:#ddd;\
		font:bold 14px arial, sans-serif;\
		margin:0;\
		letter-spacing:-1px;\
	}\
	\
	#lulekaDialog #lulekaDialogClose {\
		position:absolute;\
		height:30px;\
		width:30px;\
		top:-11px;\
		right:-12px;\
		color:#06c;\
		cursor:pointer;\
		background-position:0 0;\
		background-repeat:no-repeat;\
		background-color:transparent;\
		z-index:100007;\
	}\
	\
	#lulekaDialogLoading {\
		position:absolute;\
		top:0;\
		left:0;\
		width:40px;\
		height:40px;\
		padding:0;\
		margin:0;\
		cursor:pointer;\
		overflow:hidden;\
		background:transparent;\
		z-index:100003;\
	}\
	\
	#lulekaDialogLoading div {\
		top:0;\
		left:0;\
		width:40px;\
		height:40px;\
		background:transparent url(#{images_url}/widgets/dialog_progress.gif) no-repeat;\
	}\
	\
	#lulekaDialogOuter {\
		background:transparent none repeat scroll 0 0;\
		left:0;\
		margin:0;\
		overflow:hidden;\
		padding:18px 18px 33px;\
	}\
	\
	#lulekaDialogInner {\
		background:#FFFFFF none repeat scroll 0 0;\
		height:100%;\
		position:relative;\
		width:100%;\
	}\
	\
	#lulekaDialogBg {\
		z-index: 100003;\
		border:0 none;\
		height:100%;\
		left:0;\
		margin:0;\
		padding:0;\
		position:absolute;\
		top:0;\
		width:100%;\
	}\
	\
	div.lulekaDialogBg {\
		z-index:100003;\
		border:0 none;\
		display:block;\
		margin:0;\
		padding:0;\
		position:absolute;\
	}\
	\
	div.lulekaDialogBgN {\
		background:transparent url(#{images_url}/widgets/dialog_bg_shadow_hz.png) repeat-x scroll 0 0;\
		height:18px;\
		top:-18px;\
		width:100%;\
	}\
	\
	div.lulekaDialogBgNE {\
		background:transparent url(#{images_url}/widgets/dialog_bg_shadow_hz.png) no-repeat scroll -20px -43px;\
		height:18px;\
		right:-13px;\
		top:-18px;\
		width:13px;\
	}\
	\
	div.lulekaDialogBgE {\
		background:transparent url(#{images_url}/widgets/dialog_bg_shadow_vt.png) repeat-y scroll -20px 0;\
		height:100%;\
		right:-13px;\
		width:13px;\
	}\
	\
	div.lulekaDialogBgSE {\
		background:transparent url(#{images_url}/widgets/dialog_bg_shadow_hz.png) no-repeat scroll -20px -60px;\
		bottom:-18px;\
		height:18px;\
		right:-13px;\
		width:13px;\
	}\
	\
	div.lulekaDialogBgS {\
		background:transparent url(#{images_url}/widgets/dialog_bg_shadow_hz.png) repeat-x scroll 0 -20px;\
		bottom:-18px;\
		height:18px;\
		width:100%;\
	}\
	\
	div.lulekaDialogBgSW {\
		background:transparent url(#{images_url}/widgets/dialog_bg_shadow_hz.png) no-repeat scroll 0 -60px;\
		bottom:-18px;\
		height:18px;\
		left:-13px;\
		width:13px;\
	}\
	\
	div.lulekaDialogBgW {\
		background:transparent url(#{images_url}/widgets/dialog_bg_shadow_vt.png) repeat-y scroll 0 0;\
		height:100%;\
		left:-13px;\
		width:13px;\
	}\
	\
	div.lulekaDialogBgNW {\
		background:transparent url(#{images_url}/widgets/dialog_bg_shadow_hz.png) no-repeat scroll 0 -43px;\
		height:18px;\
		left:-13px;\
		top:-18px;\
		width:13px;\
	}\
	\
	* html div.lulekaDialogBgN {\
		background:none;\
		filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='#{images_url}/widgets/dialog_bg_shadow_n.png');\
	}\
	\
	* html div.lulekaDialogBgNE {\
		background:none;\
		filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='#{images_url}/widgets/dialog_bg_shadow_ne.png');\
	}\
	\
	* html div.lulekaDialogBgE {\
		background:none;\
		filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='#{images_url}/widgets/dialog_bg_shadow_e.png');\
	}\
	\
	* html div.lulekaDialogBgSE {\
		background:none;\
		filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='#{images_url}/widgets/dialog_bg_shadow_se.png');\
	}\
	\
	* html div.lulekaDialogBgS {\
		background:none;\
		filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='#{images_url}/widgets/dialog_bg_shadow_s.png');\
	}\
	\
	* html div.lulekaDialogBgSW {\
		background:none;\
		filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='#{images_url}/widgets/dialog_bg_shadow_sw.png');\
	}\
	\
	* html div.lulekaDialogBgW {\
		background:none;\
		filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='#{images_url}/widgets/dialog_bg_shadow_w.png');\
	}\
	\
	* html div.lulekaDialogBgNW {\
		background:none;\
		filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='#{images_url}/widgets/dialog_bg_shadow_nw.png');\
	}\
	\
	* html.dialog-open body {\
		height:100%;\
	}\
	\
	* html.dialog-open,\
	* html.dialog-open body {\
		overflow:hidden;\
	}\
	\
	html.dialog-open object,\
	html.dialog-open embed,\
	* html.dialog-open select {\
		visibility:hidden;\
	}\
	\
	* html #lulekaOverlay {\
		width:110%;\
	}\
	\
	* html #lulekaDialog #lulekaDialogClose {\
		background:none;\
		filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='#{images_url}/widgets/dialog_close.png');\
	}\
	\
	a#lulekaDialogClose {background-image: url(#{images_url}/widgets/dialog_close.png);}",
	element: function() {
		if (!document.getElementById(this.id)) {
			var dummy = document.createElement('div');
			dummy.innerHTML = '<div id="' + this.id + '" class="lulekaComponent" style="display:none;">' +
				'<div id="lulekaDialogLoading" style="display:none;"><div></div></div>' + 
			  '<div id="lulekaDialogOuter">' +
					'<div id="lulekaDialogInner">' +
				    '<a href="#" onclick="Luleka.Dialog.close();return false;" id="' + this.id + 'Close"><span style="display:none;">Close</span></a>' +
						'<div id="lulekaDialogBg">' +
							'<div class="lulekaDialogBg lulekaDialogBgN"></div>' +
							'<div class="lulekaDialogBg lulekaDialogBgNE"></div>' +
							'<div class="lulekaDialogBg lulekaDialogBgE"></div>' +
							'<div class="lulekaDialogBg lulekaDialogBgSE"></div>' +
							'<div class="lulekaDialogBg lulekaDialogBgS"></div>' +
							'<div class="lulekaDialogBg lulekaDialogBgSW"></div>' +
							'<div class="lulekaDialogBg lulekaDialogBgW"></div>' +
							'<div class="lulekaDialogBg lulekaDialogBgNW"></div>' +
						'</div>' +
				    '<div id="' + this.id + 'Content"></div>' +
					'</div>' +
				'</div>' +
			'</div>';
			document.body.insertBefore(dummy.firstChild, document.body.firstChild);
		}
		return document.getElementById(this.id);
	},
	setContent: function(html) {
		this.element();
		if (typeof(Prototype) != 'undefined') {
			document.getElementById(this.id + "Content").innerHTML = html.stripScripts();
			setTimeout(function() {
				html.evalScripts()
			},
			100);
		} else {
			document.getElementById(this.id + "Content").innerHTML = html;
		}
	},
	setPosition: function() {
		var dialogDimensions = Luleka.Element.getDimensions(this.element());
		var pageDimensions = Luleka.Page.getDimensions();
		var els = this.element().style;
		
		els.width = 'auto';
		els.height = 'auto';
		
		var left = Math.round((pageDimensions.width - dialogDimensions.width) / 2);
		els.left = left + "px";
		var top = Math.round((pageDimensions.height - dialogDimensions.height) / 2);
		top = top < 20 ? 20 : top;
		if (Luleka.Util.isIE6()) {
			top += document.documentElement ? document.documentElement.scrollTop: document.body.scrollTop
		}
		els.top = top + "px";
		
		var dls = document.getElementById("lulekaDialogLoading").style;
		dls.left = Math.round((dialogDimensions.width - 40) / 2) + "px";
		dls.top = Math.round((dialogDimensions.height - 40) / 2) + "px";
	},
	htmlElement: function() {
		return document.getElementsByTagName('html')[0];
	}
}	

Luleka.Dialog.Overlay = {
	show: function() {
		this.element().style.display = 'block';
		if (Luleka.Util.isIE6()) {
			this.element().style.top = document.documentElement ? document.documentElement.scrollTop: document.body.scrollTop
		}
	},
	hide: function() {
		this.element().style.display = 'none';
	},
	id: 'lulekaOverlay',
	element: function() {
		if (!document.getElementById(this.id)) {
			var dummy = document.createElement('div');
			dummy.innerHTML = '<div id="' + this.id + '" class="lulekaComponent" onclick="Luleka.Dialog.close(); return false;" style="display:none;"></div>';
			document.body.insertBefore(dummy.firstChild, document.body.firstChild);
		}
		return document.getElementById(this.id);
	}
}

Luleka.Popin = {
	content_template: '<iframe id="lulekaDialogFrame" src="#{url}/widgets/#{dialog}.html?#{query}" style="margin-bottom:-3px;" frameborder="0" scrolling="no" allowtransparency="true" marginheight="0" marginwidth="0" hspace="0" vspace="0" width="#{width}" height="#{height}" style="height: #{height}; width: #{width};" onload="Luleka.Dialog.displayLoaded()"></iframe>',
	setup: function(options) {
		this.setupOptions(options);
	},
	setupOptions: function(options) {
		if (typeof(options) === 'undefined') {
			return;
		}
		if (options.key == null) {
			Luleka.Logger.warning("'key' must be set for the widget to work.");
		}
		if (options.domain == null) {
			options.domain = "luleka.com";
		}
		if (options.locale == null) {
			options.locale = "us";
		}
		if (!options.params) {
			options.params = {};
		}
		this.options = options;
	},
	preload: function(options) {
		this.setupOptions(options);
		Luleka.Dialog.preload(Luleka.Util.render(this.content_template, this.getContext()));
	},
	show: function(options) {
		this.setupOptions(options);
		Luleka.Dialog.show(Luleka.Util.render(this.content_template, this.getContext()));
	},
	getContext: function() {
		var context = {
			dialog: 'feedback',
			width: '500px',
			height: '450px',
			locale: 'us',
			lang: 'en'
		};
		for (attr in this.options) {
			context[attr] = this.options[attr]
		};
		context.url = this.url();
		context.params.lang = this.options.lang;
		context.params.referer = this.getReferer();
		context.query = Luleka.Util.toQueryString(context.params);
		return context;
	},
	getReferer: function() {
		var referer = window.location.href;
		if (referer.indexOf('?') != -1) {
			referer = referer.substring(0, referer.indexOf('?'));
		}
		return referer;
	},
	url: function() {
		if ("https:" == document.location.protocol && this.options.key != null) {
			var url = 'https://' + this.options.locale + '.' + this.options.domain + '/communities/' + this.options.key + (this.options.topic ? '/topics/' + this.options.topic : '');
		} else {
			var url = 'http://' + this.options.locale + '.' + this.options.domain + '/communities/' + this.options.key + (this.options.topic ? '/topics/' + this.options.topic : '');
		}
		return url;
	}
}

Luleka.Tab = {
	id: "lulekaDialogTab",
	css_template: "\
	body a#lulekaDialogTab,\
	body a#lulekaDialogTab:link {\
		background-position: 2px 50% !important;\
		position: fixed !important;\
		top: #{tab_top} !important;\
		display: block !important;\
		width: 25px !important;\
		height: 98px !important;\
		margin: -45px 0 0 0 !important;\
		padding: 0 !important;\
		z-index: 100001 !important;\
		background-position: 2px 50% !important;\
		background-repeat: no-repeat !important;\
		text-indent: -9000px;\
		-moz-border-radius-top#{tab_radius_alignment}:5px;\
		-moz-border-radius-bottom#{tab_radius_alignment}:5px;\
	  -webkit-border-top-#{tab_radius_alignment}-radius:5px;\
	  -webkit-border-bottom-#{tab_radius_alignment}-radius:5px;\
	}\
	\
	body a#lulekaDialogTab:hover {\
		cursor: pointer;\
	}\
	\
	body a#lulekaDialogTab:active {\
		outline: none;\
	}\
	\
	body a#lulekaDialogTab:focus {\
		-moz-outline-style: none;\
	}\
	\
	* html a#lulekaDialogTab,\
	* html a#lulekaDialogTab:link {\
		position: absolute !important;\
		background-image: none !important;\
	}\
	\
	a##{id} { \
		#{tab_alignment}: 0; \
		background-repeat: no-repeat; \
		background-color: #{tab_background_color}; \
		background-image: url(#{text_url}); \
		border: outset 1px #{tab_background_color}; \
		border-#{tab_alignment}: none; \
	}\
	\
	a##{id}:hover { \
		background-color: #{tab_hover_color}; \
		border: outset 1px #{tab_hover_color}; \
		border-#{tab_alignment}: none; \
	}\
	\
	* html a##{id} { filter: progid:DXImageTransform.Microsoft.AlphaImageLoader(src='#{text_url}'); }",
	show: function(options) {
		this.setupOptions(options || {});
		Luleka.Popin.setup(options);
		var html = '<a id="' + this.id + '"';
		if (!this.options.no_dialog) {
			html += '" onclick="Luleka.Popin.show(); return false;"';
			if (this.options.preload) {
				html += '" onmouseover="Luleka.Popin.preload();"';
			}
		}
		html += ' href="' + Luleka.Popin.url() + '">' + (this.options.tab_string[this.options.locale] ? this.options.tab_string[this.options.locale] : 'Feedback') + '</a>';
		var tab = document.createElement('div');
		tab.setAttribute('id', 'luleka-feedback');
		tab.innerHTML = html;
		document.body.insertBefore(tab, document.body.firstChild);
		if (!this.options.no_styles) {
			Luleka.Util.includeCss(Luleka.Util.render(this.css_template, this.options));
		}
	},
	setupOptions: function(options) {
		this.options = {
			tab_type: 'feedback',
			tab_alignment: 'left',
			tab_top: '45%',
			asset_host: 'www.luleka.com',
			tab_background_color: '#f00',
			tab_text_color: 'white',
			tab_hover_color: '#06C',
			locale: 'us',
			lang: 'en',
			no_styles: false,
			no_dialog: false,
			preload: true
		}
		for (attr in options) {
			this.options[attr] = options[attr];
		}
		this.options.tab_string = {
			de: "Feedback",
			es: "Sugerencias"
		};
		Luleka.Util.setAssetHost(this.options.asset_host);
		this.options.lang = Luleka.Util.localeToLanguageCode(this.options.locale) || this.options.lang;
		this.options.text_url = Luleka.Util.getAssetHost() + '/images/widgets/' + this.options.lang + '/' + this.options.tab_type +'_tab_' + this.options.tab_text_color + '.png';
		this.options.tab_radius_alignment = this.options.tab_alignment == 'left' ? 'right' : 'left'
		this.options.id = this.id;
	}
}

Luleka.needsConfirm = false;
Luleka.onClose = function() {};
if(typeof(lulekaOptions) != "undefined") Luleka.Tab.setupOptions(lulekaOptions);
Luleka.Util.includeCss(Luleka.Util.render(Luleka.Dialog.css_template, {
	images_url: Luleka.Util.getAssetHost() + '/images'
}));

if (typeof(lulekaOptions) !== 'undefined' && lulekaOptions.show_tab == true) {
	Luleka.Tab.show(lulekaOptions);
}

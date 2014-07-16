/* Prototype extensions */
if (Prototype.Browser.IE) {
	Prototype.Browser.IE6 = Prototype.Browser.IE && parseInt(navigator.userAgent.substring(navigator.userAgent.indexOf("MSIE")+5)) == 6;
	Prototype.Browser.IE7 = Prototype.Browser.IE && parseInt(navigator.userAgent.substring(navigator.userAgent.indexOf("MSIE")+5)) == 7;
	Prototype.Browser.IE8 = Prototype.Browser.IE && !Prototype.Browser.IE6 && !Prototype.Browser.IE7;
} else {
	Prototype.Browser.IE6 = false;
	Prototype.Browser.IE7 = false;
	Prototype.Browser.IE8 = false;
}

Ajax.Replacer = Class.create(Ajax.Updater, {
	updateContent: function(responseText) {
		var receiver = this.container[this.success() ? 'success' : 'failure'], options = this.options;

		if (!options.evalScripts) responseText = responseText.stripScripts();
		if (receiver = $(receiver)) receiver.update(responseText); 
	}
});	


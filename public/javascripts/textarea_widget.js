/* autogrow and max characters textareas */
if (window.Widget == undefined) window.Widget = {};
Widget.Textarea = Class.create({
	initialize: function(textarea, options) {
		this.textarea = Element.extend($(textarea));
		this.options = $H({
			'max_height': 450,
			'max_length': null,
			'length_id': 'lengthSpan'
		}).update(options);

		this.textarea.observe('keyup', this.refresh.bind(this));

		this._shadow = new Element('div').setStyle({
			lineHeight: this.textarea.getStyle('lineHeight'),
			fontSize: this.textarea.getStyle('fontSize'),
			fontFamily: this.textarea.getStyle('fontFamily'),
			paddingTop: this.textarea.getStyle('paddingTop'),
			paddingRight: this.textarea.getStyle('paddingRight'),
			paddingBottom: this.textarea.getStyle('paddingBottom'),
			paddingLeft: this.textarea.getStyle('paddingLeft'),
			position: 'absolute',
			top: '-10000px',
			left: '-10000px',
			display: 'none',
			width: this.textarea.getWidth() + 'px'
		});
		
		this.initialHeight = this.textarea.getHeight();
		this.currentHeight = -1;

		if (this.options.get('line_height')) {
			this.lineHeight = this.options.get('line_height');
		} else {
			if (parseInt(this.textarea.getStyle('lineHeight')) > 0) {
				this.lineHeight = parseInt(this.textarea.getStyle('lineHeight'));
			} else {
				this.lineHeight = 16;
			}
		}
		
		this.textarea.insert({
			after: this._shadow
		});

		if (this.options.get('max_length')) {
			if (this.options.get('length_id')) {
				this._remainingCharacters = $(Element.extend(this.options.get('length_id')));
			} else {
				this._remainingCharacters = new Element('p').addClassName('remainingCharacters');
				this.textarea.insert({
					after: this._remainingCharacters
				});
			}
		}
		this.refresh();
	},

	refresh: function() {
		if (navigator.appVersion.indexOf("Win")!=-1) {
			this._shadow.update($F(this.textarea).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/\r\n/g, '<br />'));
		} else {
			this._shadow.update($F(this.textarea).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/\n/g, '<br />'));
		}

		if (this.initialHeight == 0) this.initialHeight = this.textarea.getHeight();
		var newHeight = Math.max(this.initialHeight, this._shadow.getHeight() + this.lineHeight);
		newHeight = Math.min(newHeight, parseInt(this.options.get('max_height')))
		if (newHeight != this.currentHeight && newHeight != 0) {
			this.textarea.setStyle({overflow: 'hidden'});
			this.textarea.morph('height: ' + newHeight + 'px;', {duration: 0.1});
			this.currentHeight = newHeight;
		} else {
			this.textarea.setStyle({
				overflow: 'auto'
			});
		}
		
		if (this._remainingCharacters) {
			var remaining = this.options.get('max_length') - $F(this.textarea).length;
			this._remainingCharacters.update(Math.abs(remaining));
		}
	}
});
Widget.Textarea.observe = function(id) {
	var elements = id && typeof(id) == "string" ? $(id).getElementsBySelector('textarea.autogrow') : $$('textarea.autogrow');
	elements.each(function(textarea) {
		if (typeof(textarea.retrieve('widget')) == 'undefined') {
			textarea.store('widget', new Widget.Textarea(textarea));
		}
	});
}
document.observe('dom:loaded', Widget.Textarea.observe);
document.observe('dom:updated', Widget.Textarea.observe);
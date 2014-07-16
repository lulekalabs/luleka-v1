Autocompleter.MultiValue.prototype.addEntry = function(id, title) {
  title = title || id;
  if (!this.selectedEntries().include('' + id)) {
		// begin patch
		if (this.options.beforeAddEntry) this.options.beforeAddEntry(id);
		// end patch
		
    this.searchFieldItem.insert({before: this.createSelectedElement(id, title)});

		// begin patch
		if (this.options.afterAddEntry) this.options.afterAddEntry(id);
		// end patch
  };
  var emptyValueField = this.emptyValueElement();
  if (emptyValueField) {
    emptyValueField.remove();
  };
};


Autocompleter.MultiValue.prototype.removeEntry = function(entryElement) {
	entryElement = Object.isElement(entryElement) ? entryElement : this.holder.down("li[choice_id=" + entryElement + "]");
	if (entryElement) {
		var entryValue = entryElement.down("input").value;
		// begin patch
		if (this.options.beforeRemoveEntry) this.options.beforeRemoveEntry(entryValue);
		// end patch
		entryElement.remove();
		if (this.selectedEntries().length == 0) {
			this.setEmptyValue();
		};
		// begin patch
		if (this.options.afterRemoveEntry) this.options.afterRemoveEntry(entryValue);
		// end patch
	};
}
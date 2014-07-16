/* scriptaculous slider extensions */
/* http://wiki.script.aculo.us/scriptaculous/show/EffectsTreasureChest */
Effect.BlindRight = function(element) {
  element = $(element);
    var elementDimensions = element.getDimensions();
  return new Effect.Scale(element, 100, Object.extend({ 
    scaleContent: false, 
    scaleY: false,
    scaleFrom: 0,
    scaleMode: {originalHeight: elementDimensions.height, originalWidth: elementDimensions.width},
    restoreAfterFinish: true,
    afterSetup: function(effect) {
      effect.element.makeClipping().setStyle({width: '0px'}).show(); 
    },  
    afterFinishInternal: function(effect) {
      effect.element.undoClipping();
    }
  }, arguments[1] || {}));
}

Effect.BlindLeft = function(element) {
  element = $(element);
  element.makeClipping();
  return new Effect.Scale(element, 0,
    Object.extend({ scaleContent: false, 
      scaleY: false,                     
      restoreAfterFinish: true,
      afterFinishInternal: function(effect) {
        effect.element.hide().undoClipping();
      } 
    }, arguments[1] || {})
  );
}

Effect.SlideRight = function(element) {
  element = $(element);
  Element.cleanWhitespace(element);
  var oldInnerRight = Element.getStyle(element.firstChild, 'right');
  var elementDimensions = Element.getDimensions(element);
  return new Effect.Scale(element, 100, Object.extend({ 
    scaleContent: false, 
    scaleY: false, 
    scaleFrom: 0,
    scaleMode: {originalHeight: elementDimensions.height, originalWidth: elementDimensions.width},
    restoreAfterFinish: true,
    afterSetup: function(effect) { with(Element) {
      makePositioned(effect.element);
      makePositioned(effect.element.firstChild);
      if(window.opera) setStyle(effect.element, {top: ''});
      makeClipping(effect.element);
      setStyle(effect.element, {width: '0px'});
      show(element); }},
    afterUpdateInternal: function(effect) { with(Element) {
      setStyle(effect.element.firstChild, {right:
        (effect.dims[0] - effect.element.clientWidth) + 'px' }); }},
    afterFinishInternal: function(effect) { with(Element) {
      undoClipping(effect.element); 
      undoPositioned(effect.element.firstChild);
      undoPositioned(effect.element);
      setStyle(effect.element.firstChild, {right: oldInnerRight}); }}
    }, arguments[1] || {})
  );
}

Effect.SlideLeft = function(element) {
  element = $(element);
  Element.cleanWhitespace(element);
  var oldInnerRight = Element.getStyle(element.firstChild, 'right');
  return new Effect.Scale(element, 0, 
   Object.extend({ scaleContent: false, 
    scaleY: false, 
    scaleMode: 'box',
    scaleFrom: 100,
    restoreAfterFinish: true,
    beforeStartInternal: function(effect) { with(Element) {
      makePositioned(effect.element);
      makePositioned(effect.element.firstChild);
      if(window.opera) setStyle(effect.element, {top: ''});
      makeClipping(effect.element);
      show(element); }},  
    afterUpdateInternal: function(effect) { with(Element) {
      setStyle(effect.element.firstChild, {right:
        (effect.dims[0] - effect.element.clientWidth) + 'px' }); }},
    afterFinishInternal: function(effect) { with(Element) {
        [hide, undoClipping].call(effect.element); 
        undoPositioned(effect.element.firstChild);
        undoPositioned(effect.element);
        setStyle(effect.element.firstChild, {right: oldInnerRight}); }}
   }, arguments[1] || {})
  );
}

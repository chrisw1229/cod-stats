(function($) {

$.widget("ui.meter", {

  _init: function() {
    var self = this;

    // Build the document model
    this.element.addClass("ui-meter");
    this.barDiv = $('<div class="ui-progressbar ui-widget ui-widget-content ui-corner-all ui-meter-bar"/>').appendTo(this.element);
    this.valueDiv = $('<div class="ui-progressbar-value ui-widget-header ui-corner-left ui-meter-value"/>').appendTo(this.barDiv);
    this.markerDiv = $('<div class="ui-meter-marker"/>').appendTo(this.barDiv);

    // Bind the event handlers
    $(window).bind("resize.meter", function() { self._resize(); });

    this._resize();
  },

  destroy: function() {

    // Clear the event handlers
    $(window).unbind("resize.meter");

    // Destroy the document model
    this.element.removeClass("ui-meter");
    this.barDiv.remove();

    $.widget.prototype.destroy.apply(this, arguments);
  },

  start: function() {
    if (!this.running) {
      var self = this;
      var dur = (this.options.max / this.maxW) * 60000;
      this.running = setInterval(function() { self._animate(); }, dur);
    }
  },

  stop: function() {
    if (this.running) {
      clearInterval(this.running);
      this.running = undefined;
    }
  },

  _resize: function() {

    // Only recompute the meter bounds if the width changed
    var maxW = this.element.width();
    if (this.maxW == maxW) {
      return;
    }

    // Stop the current meter animation if applicable
    this.stop();

    var markerW = this.markerDiv.width();
    var barW = (maxW - markerW);
    this.barDiv.css("left", (markerW / 2) + "px");
    this.barDiv.css("width", barW + "px");
    this.markerDiv.css("left", (markerW / -2) + "px");
    this.markerDiv.hide();
    this.maxW = maxW;

    // Configure and start the meter animation
    var value = barW * (this.options.value / this.options.max);
    this.anim = { valuePos: value, offset: (markerW / 2), maxW: barW };
    this.start();
  },

  _animate: function() {
    if (!this.running) {
      return;
    }

    // Adjust the position of the progress bar value and marker
    var leftPos = this.anim.valuePos++;
    this.valueDiv.css("width", leftPos + "px");
    this.markerDiv.css("left", (leftPos - this.anim.offset) + "px");
    this.markerDiv.show();

    if (this.anim.valuePos > this.anim.maxW) {
      this.stop();
    }
  }

});

$.extend($.ui.meter, {
  version: "1.7.2",
  defaults: {
    max: 5,
    value: 0
  }
});

})(jQuery);
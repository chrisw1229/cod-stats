(function($) {

$.widget("ui.logger", {

  _init: function() {
    var self = this;

    // Build the document model
    this.element.addClass("ui-logger");
    this.bodyDiv = $('<div class="ui-widget-content ui-corner-all ui-logger-body" />').appendTo(this.element);
    this.iconDiv = $('<div class="ui-icon ui-logger-icon" />').appendTo(this.bodyDiv);
    this.msgDiv = $('<div class="ui-logger-message" />').appendTo(this.bodyDiv);

    // Bind the event handlers
    $.logger.listener = function(event) { self.log(event); };
  },

  destroy: function() {

    // Clear the event handlers
    $.logger.listener = undefined;

    // Destroy the document model
    this.element.removeClass("ui-logger");
    this.bodyDiv.remove();

    $.widget.prototype.destroy.apply(this, arguments);
  },

  log: function(event) {

    // Construct the log statement
    var text = event.msg + (event.exc ? "\n" + event.exc : "");

    // Display debug statements as alerts
    if (event.type == "debug") {
      alert("DEBUG: " + text);
      return;
    }

    if (event.type == "error") {
      this.bodyDiv.removeClass("ui-state-highlight");
      this.iconDiv.removeClass("ui-icon-info");
      this.bodyDiv.addClass("ui-state-error");
      this.iconDiv.addClass("ui-icon-alert");
    } else {
      this.bodyDiv.removeClass("ui-state-error");
      this.iconDiv.removeClass("ui-icon-alert");
      this.bodyDiv.addClass("ui-state-highlight");
      this.iconDiv.addClass("ui-icon-info");
    }

    // Set the log message text
    this.msgDiv.text(text);

    // Position the log dialog
    this.element.css({ left: ($(window).width() - this.element.width()) - 5,
        top: ($(window).height() - this.element.height()) - 5 });
    this.element.show("slide", { direction: "down" }, "slow" );
    this.hide();
  },

  hide: function() {
    var self = this;
    var logId = setTimeout(function() {
      if (self.logId == logId) {
        self.element.hide("slide", { direction: "down" }, "slow");
      }
    }, 5000);
    this.logId = logId;
  }

});

$.extend($.ui.logger, {
  version: "1.7.2",
  defaults: { }
});

})(jQuery);
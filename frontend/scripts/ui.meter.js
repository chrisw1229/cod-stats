(function($) {

$.widget("ui.meter", {

  _init: function() {
    var self = this;

    // Initialize the component attributes
    this.value = this.options.value;
    this.max = this.options.max;
    this.milestones = [];

    // Build the document model
    this.element.addClass("ui-meter");
    this.barDiv = $('<div class="ui-progressbar ui-widget ui-widget-content ui-corner-all ui-meter-bar"/>').appendTo(this.element);
    this.valueDiv = $('<div class="ui-progressbar-value ui-widget-header ui-corner-left ui-meter-value"/>').appendTo(this.barDiv);
    this.markerDiv = $('<div class="ui-meter-marker"/>').appendTo(this.barDiv);

    // Bind the event handlers
    $(window).bind("resize.meter", function() { self._resize(); });

    // Set the initial meter appearance and add any default markers
    this._resize();
    this.addMilestones(this.options.milestones);
  },

  destroy: function() {

    // Clear the event handlers
    $(window).unbind("resize.meter");

    // Destroy the document model
    this.element.removeClass("ui-meter");
    this.barDiv.remove();

    $.widget.prototype.destroy.apply(this, arguments);
  },

  addEvent: function(event) {
    this.value = event.time;
    if (event.team) {
      this.addMilestones(event);
    } else {
      this._update();
    }
  },

  addMilestones: function(milestones) {
    milestones = ($.isArray(milestones) ? milestones : [ milestones ]);

    for (var i = 0; i < milestones.length; i++) {
      this._createMilestone(milestones[i]);
      this.milestones.push(milestones[i]);
    }
    this._update();
  },

  reset: function(max) {
    this.value = 0;
    this.max = (max != undefined ? max : this.max);

    for (var i = 0; i < this.milestones.length; i++) {
      this.milestones[i].div.remove();
    }

    this.milestones = [];
    this._update();
  },

  _resize: function() {

    // Only recompute the meter bounds if the width changed
    var maxW = this.element.width();
    if (this.maxW == maxW) {
      return;
    }

    // Compute the initial element dimensions
    var markerW = this.markerDiv.width();
    var barW = (maxW - markerW);
    this.barDiv.css({ left: (markerW / 2), width: barW });
    this.markerDiv.css("left", (markerW / -2));
    this.markerDiv.hide();
    this.maxW = maxW;
    this.barW = barW;
    this._update();
  },

  _update: function() {

    // Adjust the position of the progress bar value and marker
    this.markerL = this.barW * (this.value / this.max);
    this.valueDiv.css("width", this.markerL);
    this.markerDiv.css("left", this.markerL - (this.markerDiv.width() / 2));
    this.markerDiv.show();

    // Display any milestones that have occurred
    for (var i = 0; i < this.milestones.length; i++) {
      var milestone = this.milestones[i];
      if (this.value >= milestone.time) {
        var pos = this.barW * (milestone.time / this.max) - (milestone.div.width() / 2);
        milestone.div.css("left", pos);
        milestone.div.show();
      } else {
        milestone.div.hide();
      }
    }

    // Update the time remaining tool tip
    var mins = this.value >= 60 ? (this.value / 60) : 0;
    var secs = (this.value % 60);
    var time = mins + ":" + (secs < 10 ? "0" : "") + secs;
    this.barDiv.attr("title", "Time Remaining: " + time);
  },

  _createMilestone: function(milestone) {
    milestone.div = $('<div class="ui-meter-milestone icon-team icon-team-'
        + milestone.team + '"/>').appendTo(this.barDiv);
    milestone.div.attr("title", milestone.desc);
    milestone.div.hide();
  }

});

$.extend($.ui.meter, {
  version: "1.7.2",
  defaults: {
    max: 100,
    value: 0,
    milestones: []
  }
});

})(jQuery);
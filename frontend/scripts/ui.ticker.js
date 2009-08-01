(function($) {

$.widget("ui.ticker", {

  _init: function() {
    var self = this;
    this.index = 0;

    // Build the document model
    this.element.addClass("ui-widget-content ui-ticker");
    this.shadowDiv = $('<div class="ui-ticker-shadow"/>').appendTo(this.element);
    this.itemsDiv = $('<div class="ui-ticker-items"/>').appendTo(this.element);

    // Bind the event handlers
    this.itemsDiv.bind("mouseenter", function() { self.stop(); });
    this.itemsDiv.bind("mouseleave", function() { self.start(); });
    $(window).bind("resize", function() { self._resize(); });

    this._resize();
  },

  destroy: function() {

    // Clear the event handlers
    this.itemsDiv.unbind();
    this._unbindItems($("div.ui-ticker-item", this.itemsDiv));

    // Destroy the document model
    this.element.removeClass("ui-widget-content ui-ticker");
    this.shadowDiv.remove();
    this.itemsDiv.remove();

    $.widget.prototype.destroy.apply(this, arguments);
  },

  start: function() {
    if (!this.running) {
      var self = this;
      this.running = setInterval(function() { self._animate(); }, 50);
    }
  },

  stop: function() {
    if (this.running) {
      clearInterval(this.running);
      this.running = undefined;
    }
  },

  _resize: function() {

    // Only recompute the ticker bounds if the width changed
    var maxW = this.element.width();
    if (this.maxW == maxW) {
      return;
    }

    // Stop the current ticker animation if applicable
    this.stop();

    // Clear any previous ticker items
    this._unbindItems();
    this.itemsDiv.empty();

    // Calculate the number of ticker items that will fit on screen at once
    this.maxW = maxW;
    var prototype = this._createItem();
    var itemW = prototype.outerWidth(true);
    var count = Math.ceil(maxW / itemW);

    // Generate a group to hold a set of ticker items
    this.group1 = $('<div class="ui-ticker-slider"/>').appendTo(this.itemsDiv);
    this.group1.css("width", (itemW * count) + "px");
    this.group1.css("left", maxW + "px");

    // Generate the ticker items
    prototype.appendTo(this.group1);
    for (var i = 1; i < count; i++) {
      var item = prototype.clone().appendTo(this.group1);
      item.css("left", i * itemW);
    }

    // Make a copy of the group to rotate through the ticker
    this.group2 = this.group1.clone().appendTo(this.itemsDiv);
    this.group2.hide();

    // Bind events to all the ticker items
    this._bindItems($("div.ui-ticker-item", this.itemsDiv));

    // Configure the ticker animation
    var groupW = this.group1.outerWidth(true);
    this.anim = {
      maxW: maxW, groupW: groupW,
      inPos: (maxW - groupW), outPos: (-1 * groupW),
      x1: maxW, x2: groupW, move: 2, state: 0
    };

    // Fill the first group with data and start
    this._loadGroup(this.group1);
    this.start();
  },

  _animate: function() {
    if (!this.running) {
      return;
    }

    // Move the group 1 until it surpasses the left screen bounds
    if (this.anim.x1 > this.anim.outPos) {
      this.anim.x1 -= this.anim.move;
      this.group1.css("left", this.anim.x1 + "px");
    }

    // Reset group 2 once group 1 reaches the left screen bounds
    if (this.anim.state != 1) {
      if (this.anim.x1 + this.anim.groupW <= this.anim.maxW) {
        this.anim.x2 = this.anim.x1 + this.anim.groupW + this.anim.move;
        this._loadGroup(this.group2);
        this.group2.show();
        this.anim.state = 1;
      }
    }

    // Move group 2 until it surpasses the left screen bounds
    if (this.anim.state != 0) { 
      if (this.anim.x2 > this.anim.outPos) {
        this.anim.x2 -= this.anim.move;
        this.group2.css("left", this.anim.x2 + "px");
      }
    }

    // Reset group 1 once group 2 reaches the left screen bounds
    if (this.anim.state != 2 && this.anim.x2 + this.anim.groupW <= this.anim.maxW) {
      this.anim.x1 = this.anim.x2 + this.anim.groupW;
      this._loadGroup(this.group1);
      this.anim.state = 2;
    }
  },

  _createItem: function() {
    var itemDiv = $('<div class="ui-ticker-item"/>').appendTo(this.itemsDiv);
    var shadowDiv = $('<div class="ui-widget-shadow ui-ticker-item-shadow"/>').appendTo(itemDiv);
    var nameDiv = $('<div class="ui-state-default ui-corner-top ui-ticker-item-name"/>').appendTo(itemDiv);
    var contDiv = $('<div class="ui-widget-content ui-corner-bottom ui-ticker-item-content"/>').appendTo(itemDiv);
    var photoDiv = $('<div class="ui-widget-content ui-corner-br ui-ticker-item-photo"/>').appendTo(contDiv);

    var iconsDiv = $('<div class="ui-ticker-item-icons"/>').appendTo(contDiv);
    var placeDiv = $('<div class="ui-widget-header ui-corner-bl ui-ticker-place"/>').appendTo(iconsDiv);
    $('<div class="ui-ticker-place-label">RANK</div>').appendTo(placeDiv);
    $('<div class="ui-ticker-place-value"/>').appendTo(placeDiv);
    $('<div class="icon-rank ui-ticker-rank"/>').appendTo(iconsDiv);
    $('<div class="icon-team ui-ticker-team"/>').appendTo(iconsDiv);

    var statsTbl = $('<table class="ui-ticker-stats"/>').appendTo(contDiv);
    $('<tr class="ui-ticker-kills"><td class="ui-ticker-stat-value"></td><td>Kills</td></tr>').appendTo(statsTbl);
    $('<tr class="ui-ticker-deaths"><td class="ui-ticker-stat-value"></td><td>Deaths</td></tr>').appendTo(statsTbl);
    $('<tr class="ui-ticker-inflicted"><td class="ui-ticker-stat-value"></td><td>Inflicted</td></tr>').appendTo(statsTbl);
    $('<tr class="ui-ticker-received"><td class="ui-ticker-stat-value"></td><td>Received</td></tr>').appendTo(statsTbl);
    return itemDiv;
  },

  _bindItems: function() {
    $("div.ui-ticker-item", this.itemsDiv).each(function() {
      var nameDiv = $("div.ui-ticker-item-name", this);
      $(this).bind("mouseenter", function() { nameDiv.addClass("ui-state-hover"); });
      $(this).bind("mouseleave", function() { nameDiv.removeClass("ui-state-hover"); });
    });
  },

  _unbindItems: function() {
    $("div.ui-ticker-item", this.itemsDiv).each(function() {
      $(this).unbind();
    });
  },

  _loadGroup: function(group) {
    var self = this;
    $("div.ui-ticker-item", group).each(function() {
      self._loadItem(this, self.options.items[self.index++]);
      if (self.index >= self.options.items.length) {
        self.index = 0;
      }
    });
  },

  _loadItem: function(itemDiv, item) {
    $("div.ui-ticker-item-name", itemDiv).text(item.name)
    $("div.ui-ticker-item-photo", itemDiv).css("background-image",
        "url(players/" + item.photo + ")");
    $("div.ui-ticker-place-value", itemDiv).text(item.place)
    $("div.icon-rank", itemDiv).attr("class",
        "icon-rank icon-rank-" + item.rank + " ui-ticker-rank");
    $("div.icon-team", itemDiv).attr("class",
        "icon-team icon-team-" + item.team + " ui-ticker-team");

    $("tr.ui-ticker-kills td.ui-ticker-stat-value", itemDiv).text(item.kills)
    $("tr.ui-ticker-deaths td.ui-ticker-stat-value", itemDiv).text(item.deaths)
    $("tr.ui-ticker-inflicted td.ui-ticker-stat-value", itemDiv).text(item.inflicted)
    $("tr.ui-ticker-received td.ui-ticker-stat-value", itemDiv).text(item.received)
  }

});

$.extend($.ui.ticker, {
  version: "1.7.2",
  defaults: {
    items: [
      { name: "A Figment of Your Imagination", photo: "player0.jpg", place: "4", rank: "4", team: "a", kills: "79", deaths: "57", inflicted: "14,722", received: "8,353" },
      { name: "Bazooka John", photo: "player1.jpg", place: "7", rank: "3", team: "g", kills: "48", deaths: "57", inflicted: "8,834", received: "7,149" },
      { name: "CDJ Wobbly Wiggly", photo: "player2.jpg", place: "10", rank: "2", team: "b", kills: "32", deaths: "43", inflicted: "5,475", received: "9,252" },
      { name: "CHUCKNORRISCOUNTEDTOINFINITY...", photo: "player3.jpg", place: "11", rank: "2", team: "r", kills: "27", deaths: "55", inflicted: "4,085", received: "6,768" },
      { name: "Colonel Billiam", photo: "player4.jpg", place: "9", rank: "3", team: "a", kills: "44", deaths: "55", inflicted: "5,294", received: "6,245" },
      { name: "GOMER PYLE", photo: "player5.jpg", place: "2", rank: "5", team: "g", kills: "108", deaths: "55", inflicted: "18,475", received: "7,809" },
      { name: "Jaymz", photo: "player6.jpg", place: "6", rank: "4", team: "b", kills: "58", deaths: "53", inflicted: "3,119", received: "2,090" },
      { name: "Luda", photo: "player7.jpg", place: "8", rank: "3", team: "r", kills: "45", deaths: "50", inflicted: "10,572", received: "10,978" },
      { name: "Note To Self", photo: "player8.jpg", place: "5", rank: "4", team: "a", kills: "68", deaths: "53", inflicted: "11,222", received: "8,376" },
      { name: "Scope", photo: "player9.jpg", place: "3", rank: "4", team: "g", kills: "82", deaths: "57", inflicted: "9,161", received: "9,162" },
      { name: "ThePine", photo: "player10.jpg", place: "1", rank: "5", team: "b", kills: "143", deaths: "80", inflicted: "18,590", received: "11,193" },
      { name: "Tim - Target Drone", photo: "player11.jpg", place: "12", rank: "1", team: "r", kills: "18", deaths: "50", inflicted: "2,879", received: "9,257" },
      { name: "Turn Left Nower", photo: "player12.jpg", place: "13", rank: "1", team: "a", kills: "12", deaths: "31", inflicted: "2,741", received: "5,515" }
    ]
  }
});

})(jQuery);
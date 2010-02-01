(function($) {

$.widget("ui.ticker", {

  _init: function() {
    var self = this;
    this.items = [];
    this.loadIndex = 0;

    // Build the document model
    this.element.addClass("ui-widget-content ui-ticker");
    this.shadowDiv = $('<div class="ui-ticker-shadow"/>').appendTo(this.element);
    this.itemsDiv = $('<div class="ui-ticker-items"/>').appendTo(this.element);

    // Bind the event handlers
    this.itemsDiv.bind("mouseenter", function() { self.stop(); });
    this.itemsDiv.bind("mouseleave", function() { self.start(); });
    $(window).bind("resize.ticker", function() { self._resize(); });

    // Set the initial ticker appearance and add any default items
    this.updateItems(this.options.items);
    this._resize();
  },

  destroy: function() {

    // Clear the event handlers
    this.itemsDiv.unbind();
    $(window).unbind("resize.ticker");
    this._unbindItems();

    // Destroy the document model
    this.element.removeClass("ui-widget-content ui-ticker");
    this.shadowDiv.remove();
    this.itemsDiv.remove();

    $.widget.prototype.destroy.apply(this, arguments);
  },

  start: function() {
    if (!this.running) {
      var self = this;

      // Start the slide animation after the pause interval
      this.running = setTimeout(function() { 
        self.sliding = setInterval(function() {
          self._animate();
        }, self.anim.rate);
      }, this.anim.pause);
    }
  },

  stop: function() {
    if (this.running) {
      clearInterval(this.running);
      this.running = undefined;
      clearInterval(this.sliding);
      this.sliding = undefined;
    }
  },

  updateItems: function(items) {
    items = ($.isArray(items) ? items : [ items ]);

    // Apply the item updates to the stored model
    var count = this.items.length;
    for (var i = 0; i < items.length; i++) {
      var newItem = items[i];

      var updated = false;
      for (var j = 0; j < this.items.length; j++) {
        var oldItem = this.items[j];

        // Check if the stored items matches the updated items
        if (newItem.id == oldItem.id) {

          // Check if the item should be updated or removed
          if (newItem.team == "") {

            // Remove the item from the list
            this.items.splice(j, 1);

            // Dim the associated element if it is being displayed
            this._unloadItem(oldItem);

            // Adjust the last loaded index if needed
            if (j < this.loadIndex) {
              this.loadIndex = (this.loadIndex > 0 ? this.loadIndex - 1 : 0);
            } else if (this.loadIndex >= this.items.length) {
              this.loadIndex = 0;
            }
            updated = true;
            break;
          } else {

            // Merge the updated item into the stored item
            $.extend(oldItem, newItem);

            // Update the associated element if it is being displayed
            this._refreshItem(oldItem);
            updated = true;
            break;
          }
        }
      }

      // Add the new item if it was not updated or removed
      if (!updated) {
        this.items.push(newItem);
      }
    }

    // Load new items into the displayed group if it has room
    if (this.group && this.anim && count < this.anim.count) {
      this._loadGroup(this.group);
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
    this.group1.css({ left: 0, width: (itemW * count) });

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
    this.itemDivs = $("div.ui-ticker-item", this.itemsDiv);
    this._bindItems();

    // Fill the first group with data
    this._loadGroup(this.group1);

    // Configure the ticker animation
    var groupW = this.group1.outerWidth(true);
    this.anim = {
      rate: 100, speed: 52, pause: 4000,
      maxW: maxW, groupW: groupW, itemW: itemW,
      inPos: (maxW - groupW), outPos: (-1 * groupW),
      x1: 0, x2: groupW, moved: 0, state: 0, count: count
    };

    // Start the ticker animation
    this.start();
 },

  _animate: function() {
    if (!this.running) {
      return;
    }

    // Move the group 1 until it surpasses the left screen bounds
    if (this.anim.x1 > this.anim.outPos) {
      this.anim.x1 -= this.anim.speed;
      this.group1.css("left", this.anim.x1);
      this.group = this.group1;
    }

    // Reset group 2 once group 1 reaches the left screen bounds
    if (this.anim.state != 1) {
      if (this.anim.x1 + this.anim.groupW <= this.anim.maxW) {
        this.anim.x2 = this.anim.x1 + this.anim.groupW + this.anim.speed;
        this._loadGroup(this.group2);
        this.group2.show();
        this.anim.state = 1;
      }
    }

    // Move group 2 until it surpasses the left screen bounds
    if (this.anim.state != 0) { 
      if (this.anim.x2 > this.anim.outPos) {
        this.anim.x2 -= this.anim.speed;
        this.group2.css("left", this.anim.x2);
        this.group = this.group2;
      }
    }

    // Reset group 1 once group 2 reaches the left screen bounds
    if (this.anim.state != 2 && this.anim.x2 + this.anim.groupW <= this.anim.maxW) {
      this.anim.x1 = this.anim.x2 + this.anim.groupW;
      this._loadGroup(this.group1);
      this.anim.state = 2;
    }

    // Pause for a few seconds after sliding one full item
    this.anim.moved += this.anim.speed;
    if (this.anim.moved >= this.anim.itemW) {
      this.anim.moved = 0;
      this.stop();
      this.start();
    }
  },

  _createItem: function() {

    // Create the document model for a single ticker item
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
    $('<div class="ui-ticker-spec">SPECTATOR</div>').appendTo(contDiv);
    return itemDiv;
  },

  _bindItems: function() {

    // Highlight the ticker item name upon mouse hover
    if (this.itemDivs) {
      this.itemDivs.each(function() {
        var nameDiv = $("div.ui-ticker-item-name", this);
        $(this).bind("mouseenter", function() { nameDiv.addClass("ui-state-hover"); });
        $(this).bind("mouseleave", function() { nameDiv.removeClass("ui-state-hover"); });
      });
    }
  },

  _unbindItems: function() {

    // Remove ticker item name highlights
    if (this.itemDivs) {
      this.itemDivs.each(function() {
        $(this).unbind();
      });
    }
  },

  _loadGroup: function(group) {

    // Load all the ticker item data for the given group
    var self = this;
    var count = 0;
    $("div.ui-ticker-item", group).each(function() {
      var itemDiv = $(this);

      // Check if there is enough data to display the item
      if (count < self.items.length) {

        // Make sure the element is fully visible
        itemDiv.show();
        itemDiv.fadeTo(0, 1.0);

        // Load the item into the element
        var item = self.items[self.loadIndex++];
        self._loadItem(this, item);

        // Remember the index of the next item to load
        if (self.loadIndex >= self.items.length) {
          self.loadIndex = 0;
        }
        count++;
      } else {

        // Hide the element since it will be empty
        itemDiv.hide();
      }
    });
  },

  _loadItem: function(itemDiv, item) {

    // Load all the basic values for the given ticker item
    $("div.ui-ticker-item-name", itemDiv).text(item.name);
    $("div.ui-ticker-item-photo", itemDiv).css("background-image",
        "url(players/" + item.photo + ")");

    // Check whether the current item is a spectator
    var team = (item.team && item.team.length > 0 ? item.team.charAt(0) : "").toLowerCase();
    if (team != "s") {

      // Load all the icon content
      $("div.ui-ticker-place-value", itemDiv).text(item.place);
      $("div.icon-rank", itemDiv).attr("class",
          "icon-rank icon-rank-" + item.rank + " ui-ticker-rank");
      $("div.icon-team", itemDiv).attr("class",
          "icon-team icon-team-" + item.team + " ui-ticker-team");
      $("div.ui-ticker-item-icons", itemDiv).show();

      // Load all the numeric content
      $("tr.ui-ticker-kills td.ui-ticker-stat-value", itemDiv).text(item.kills);
      $("tr.ui-ticker-deaths td.ui-ticker-stat-value", itemDiv).text(item.deaths);
      $("tr.ui-ticker-inflicted td.ui-ticker-stat-value", itemDiv).text(item.inflicted);
      $("tr.ui-ticker-received td.ui-ticker-stat-value", itemDiv).text(item.received);
      $("table.ui-ticker-stats", itemDiv).show();
      $("div.ui-ticker-spec", itemDiv).hide();
    } else {

      // Just show the spectator label
      $("div.ui-ticker-item-icons", itemDiv).hide();
      $("table.ui-ticker-stats", itemDiv).hide();
      $("div.ui-ticker-spec", itemDiv).show();
    }

    // Update the mapping between element and item
    itemDiv.item = item;
  },

  _unloadItem: function(item) {
    if (this.itemDivs) {
      this.itemDivs.each(function() {
        if (this.item && this.item.id == item.id) {
          $(this).fadeTo("slow", 0.3);
          this.item = undefined;
        }
      });
    }
  },

  _refreshItem: function(item) {
    var self = this;
    if (this.itemDivs) {
      this.itemDivs.each(function() {
        if (this.item && this.item.id == item.id) {
          self._loadItem(this, item);
        }
      });
    }
  }

});

$.extend($.ui.ticker, {
  version: "1.7.2",
  defaults: {
    items: []
  }
});

})(jQuery);
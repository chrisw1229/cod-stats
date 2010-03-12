(function($) {

$.widget("ui.message", {

  _init: function() {
    var self = this;

    this.messages = [];

    // Build the document model
    this.element.addClass("ui-message");
    this.bodyDiv = $('<div class="ui-message-body"/>').appendTo(this.element);
    this.listDiv = $('<ol class="ui-message-list"/>').appendTo(this.bodyDiv);

    // Build the list items to hold the messages
    for (var i = 0; i < this.options.count; i++) {
      this._createItem(i).appendTo(this.listDiv);
    }

    // Start a timer to clean up old items
    this.running = setInterval(function() { self._cleanItems(); }, 2000);
  },

  destroy: function() {

    // Stop the clean up timer
    clearInterval(this.running);
    this.running = undefined;

    // Destroy the document model
    this.element.removeClass("ui-message");
    this.bodyDiv.remove();

    $.widget.prototype.destroy.apply(this, arguments);
  },

  addMessages: function(messages) {
    messages = ($.isArray(messages) ? messages : [ messages ]);

    // Set a time stamp for each message
    var ts = new Date().getTime();
    for (var i = 0; i < messages.length; i++) {
      messages[i].ts = ts;
    }

    // Add all the new messages
    this.messages = messages.concat(this.messages);

    // Remove the oldest messages that will no longer fit
    if (this.messages.length > this.options.count) {
      this.messages.splice(this.options.count,
          this.messages.length - this.options.count); 
    }

    // Update the displayed messages
    var itemDivs = this.listDiv.children();
    for (var i = 0; i < this.messages.length; i++) {
      this._loadItem(itemDivs.eq(i), this.messages[i]);
    }
  },

  clear: function() {

    // Hide all the list elements
    for (var i = 0; i < this.messages.length; i++) {
      if (this.messages[i]) {
        this._unloadItem(this.messages[i]);
      }
    }

    // Clear the message packets from memory
    this.messages = [];
  },

  _createItem: function(index) {
    var itemDiv = $('<li class="ui-message-item"/>');

    // Set the opacity based on the list position
    if (index > 0) {
      var percent = 1.0 / (this.options.count + 1);
      itemDiv.css("opacity", 1 - percent * index);
    }

    $('<span class="ui-message-name"/>').appendTo(itemDiv);
    $('<span class="ui-message-icon"/>').appendTo(itemDiv);
    $('<span class="ui-message-name"/>').appendTo(itemDiv);
    return itemDiv;
  },

  _loadItem: function(itemDiv, item) {

    // Get the name elements
    var nameDivs = $(".ui-message-name", itemDiv);
    var name1Div = nameDivs.eq(0);
    var name2Div = nameDivs.eq(1);

    // Update the name 1 display
    var name1 = (item.sname ? item.sname : item.kname);
    name1Div.text(name1);

    // Update the name 1 team color
    var team1 = (item.steam ? item.steam : item.kteam);
    name1Div.attr("class", "ui-message-name ui-message-team-" + team1);

    // Update the name 2 display
    var name2 = (item.sname ? "" : item.dname);
    name2Div.text(name2);

    // Update the name 2 team color
    var team2 = (item.steam ? "" : item.dteam);
    name2Div.attr("class", "ui-message-name ui-message-team-" + team2);

    // Update the kill type symbol
    var iconDiv = $(".ui-message-icon", itemDiv);
    iconDiv.text(name2.length > 0 ? "->" : "");

    // Store the mapping for future use
    item.div = itemDiv;
  },

  _unloadItem: function(item) {
    if (item.div) {
      $(".ui-message-name", item.div).text("");
      $(".ui-message-icon", item.div).text("");
      item.div = undefined;
    }
  },

  _cleanItems: function() {

    // Get the current time stamp
    var now = new Date().getTime();

    // Check for any expired messages
    for (var i = this.messages.length - 1; i >= 0; i--) {

      // Check if the message is older than 10 seconds
      if (now - this.messages[i].ts >= 10000) {
        this._unloadItem(this.messages[i]);
        this.messages.splice(i, 0);
      }
    }
  }

});

$.extend($.ui.message, {
  version: "1.7.2",
  defaults: {
    count: 4
  }
});

})(jQuery);
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
  },

  destroy: function() {

    // Destroy the document model
    this.element.removeClass("ui-message");
    this.bodyDiv.remove();

    $.widget.prototype.destroy.apply(this, arguments);
  },

  addMessages: function(messages) {
    messages = ($.isArray(messages) ? messages : [ messages ]);

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
    this.messages = [];
    var self = this;
    this.listDiv.children().each(function() {
      self._unloadItem(this);
    });
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
    var nameDivs = $(".ui-message-name", itemDiv);

    var name1 = (item.sname ? item.sname : item.kname);
    var team1 = (item.steam ? item.steam : item.kteam);

    var name1Div = nameDivs.eq(0);
    name1Div.text(name1);
    name1Div.attr("class", "ui-message-name ui-message-team-" + team1);

    var name2 = (item.sname ? "" : item.dname);
    var team2 = (item.steam ? "" : item.dteam);

    var name2Div = nameDivs.eq(1);
    name2Div.text(name2);
    name2Div.attr("class", "ui-message-name ui-message-team-" + team2);

    var iconDiv = $(".ui-message-icon", itemDiv);
    iconDiv.text(name2.length > 0 ? "->" : "");
  },

  _unloadItem: function(itemDiv) {
    $(".ui-message-name", itemDiv).text("");
    $(".ui-message-icon", itemDiv).text("");
  }

});

$.extend($.ui.message, {
  version: "1.7.2",
  defaults: {
    count: 4
  }
});

})(jQuery);
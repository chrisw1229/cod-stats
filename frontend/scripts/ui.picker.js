(function($) {

$.widget("ui.picker", {

  _init: function() {
    var self = this;

    // Build the document model
    this.element.addClass("ui-picker");
    this.bodyDiv = $('<div class="ui-widget-header ui-corner-all'
        + ' ui-picker-body" />').appendTo(this.element);
    $('<div class="ui-picker-title">' + this.options.title
        + '</div>').appendTo(this.bodyDiv);

    this.comboDiv = $('<div class="ui-picker-combo" />').appendTo(this.bodyDiv);
    this.inputDiv = $('<input class="ui-widget-content ui-corner-tl'
        + ' ui-corner-bl ui-picker-combo-input" />').appendTo(this.comboDiv);
    this.buttonDiv = $('<div class="ui-state-default ui-corner-tr ui-corner-br'
        + ' ui-picker-combo-button">').appendTo(this.comboDiv);
    $('<span class="ui-icon ui-icon-circle-triangle-s" />').appendTo(this.buttonDiv);
    this.listDiv = $('<div class="ui-picker-list"></div>').appendTo($("body"));

    // Bind the event handlers
    this.comboDiv.bind("mouseenter", function() { self._toggleButton(); });
    this.comboDiv.bind("mouseleave", function() { self._toggleButton(); });
    this.comboDiv.bind("click", function(e) { e.stopPropagation(); self._toggleList(true); });
    this.inputDiv.bind("keyup", function(e) { self._inputChanged(e); });
    $("html").bind("click", function() { self._toggleList(false); });
    $(window).bind("resize", function() { self._toggleList(false); });

    // Fetch the remote content
    this._requestIndex();
  },

  destroy: function() {

    // Clear the event handlers
    this.comboDiv.unbind();

    // Destroy the document model
    this.element.removeClass("ui-picker");
    this.bodyDiv.remove();
    this.listDiv.remove();

    $.widget.prototype.destroy.apply(this, arguments);
  },

  _enabled: function(enabled) {
    this.enabled = enabled;
    if (enabled) {
      this.inputDiv.val("");
      this.inputDiv.removeClass("ui-state-disabled ui-picker-combo-loading");
      this.buttonDiv.removeClass("ui-state-disabled");
    } else {
      this.listDiv.hide();
      this.inputDiv.val("Loading...");
      this.inputDiv.addClass("ui-state-disabled ui-picker-combo-loading");
      this.buttonDiv.addClass("ui-state-disabled");
    }
  },

  _requestIndex: function() {

    // Disable user interaction
    this._enabled(false);

    // Fetch the index elements
    $.getJSON(this.options.type + "/index.json", $.call(this, "_processIndex"));
  },

  _processIndex: function(items, status) {

    // Check if the request was successful
    if (status != "success") {
      $.logger.error("Error retrieving list index: " + this.options.type, status);
      return;
    }

    // Clear any previous list items
    $("li", this.listDiv).unbind();
    $("ul", this.listDiv).remove();

    // Create elements for each list item entry
    this.items = items;
    var list = $('<ul/>').appendTo(this.listDiv);
    for (var i = 0; i < items.length; i++) {
      this._createItem(items[i]).appendTo(list);
    }

    // Bind event handlers to the list items
    var self = this;
    $("li", this.listDiv).each(function(i) {
      $(this).bind("click", function() { self._itemSelected(i); });
      $(this).bind("mouseenter", function() { $(this).addClass("ui-state-hover"); });
      $(this).bind("mouseleave", function() { $(this).removeClass("ui-state-hover"); });
    });

    // Enable user interaction
    this._enabled(true);
  },

  _createItem: function(item) {
    var itemDiv = $('<li class="ui-state-default ui-corner-all" />');
    var nameDiv = $('<div class="item-name">' + item.name + '</div>').appendTo(itemDiv);
    var descDiv = $('<div class="item-desc">' + item.tip + '</div>').appendTo(itemDiv);
    item.div = itemDiv;
    return itemDiv;
  },

  _toggleButton: function() {
    if (!this.enabled || this.buttonDiv.hasClass("ui-state-hover")) {
      this.buttonDiv.removeClass("ui-state-hover");
    } else {
      this.buttonDiv.addClass("ui-state-hover");
    }
  },

  _toggleList: function(visible) {
    if (!this.enabled || visible != true) {

      // Hide the list of items
      this.listDiv.stop().slideUp("fast");
      this.inputDiv.addClass("ui-corner-bl");
      this.buttonDiv.addClass("ui-corner-br");
    } else if (!this.listDiv.is(":visible")){

      // Find the height of a single item while the list is off-screen
      var listW = this.comboDiv.width() - 1;
      this.listDiv.css({ width: listW, left: -listW });
      this.listDiv.show();
      var itemH = $("li:first", this.listDiv).outerHeight(true);
      this.listDiv.hide();

      // Calculate the position and dimensions for the list
      var offset = this.comboDiv.offset();
      var listT = offset.top + this.comboDiv.height() + 2;
      var maxH = $(window).height() - listT;
      var listH = Math.floor(maxH / itemH) * itemH; 
      this.listDiv.css({ left: offset.left, top: listT });
      this.listDiv.css({ height: listH });

      // Store the dimensions for use during dynamic filtering
      this.listDiv.maxHeight = listH;
      this.listDiv.itemHeight = itemH;

      // Display the list of items
      this.listDiv.stop().slideDown("fast");
      this.inputDiv.removeClass("ui-corner-bl");
      this.buttonDiv.removeClass("ui-corner-br");
    }
  },

  _inputChanged: function(e) {
    if (e.keyCode == 27) {

      // Hide the list when escape is pressed
      this._toggleList(false);
    } else {
      var filter = this.inputDiv.val().toLowerCase();
      if (this.filter != filter) {
        this.filter = filter;
        this._filterList(filter);
      }
    }
  },

  _filterList: function(filter) {

    // Show only items that match the given filter
    var count = 0;
    for (var i = 0; i < this.items.length; i++) {
      var item = this.items[i];
      var matches = (filter.length == 0
          || item.name.toLowerCase().indexOf(filter) >= 0
          || item.tip.toLowerCase().indexOf(filter) >= 0);
      item.div.toggle(matches);
      count += (matches ? 1 : 0);
    }

    // Re-size the list if the number of matched items changed
    if (this.listDiv.count != count) {
      var prefH = count * this.listDiv.itemHeight;
      if (prefH > this.listDiv.maxHeight) {
        this.listDiv.css({ height: this.listDiv.maxHeight, overflowY: "scroll" });
      } else if (prefH != this.listDiv.height()) {
        this.listDiv.css({ height: prefH, overflowY: "hidden" });
      }
      this.listDiv.count = count;
    }
  },

  _itemSelected: function(index) {
    this.selection = this.items[index];

    // Update the appearance of the widget
    this.inputDiv.val(this.selection.name);

    // Fetch the details for the selected item
    $.getJSON(this.options.type + "/" + this.selection.name + ".json",
        $.call(this, "_processItem"));
  },

  _processItem: function(data, status) {
    if (status == "success") {
      if (this.options.callback) {
        this.options.callback(this.selection, data);
      }
    } else {
      $.logger.error("Error selecting list item: " + this.selection.name, status);
    }
  }
});

$.extend($.ui.picker, {
  version: "1.7.2",
  defaults: {
    title: "",
    type: "",
    callback: undefined
  }
});

})(jQuery);
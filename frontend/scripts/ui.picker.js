(function($) {

$.widget("ui.picker", {

  _init: function() {
    var self = this;
    this.filter = "";
    this.selection = undefined;
    this.selectionIndex = -1;

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

    this.popupDiv = $('<div class="ui-picker-popup"></div>').appendTo($("body"));
    this.popupContentDiv = $('<div class="ui-corner-bottom ui-picker-popup-content"/>').appendTo(this.popupDiv);
    this.listDiv = $('<div class="ui-picker-list"/>').appendTo(this.popupContentDiv);
    this.shadowDiv = $('<div class="ui-widget-shadow ui-corner-all ui-picker-shadow"/>').appendTo(this.popupDiv);

    // Bind the event handlers
    this.comboDiv.bind("mouseenter", function() { self._toggleButton(); });
    this.comboDiv.bind("mouseleave", function() { self._toggleButton(); });
    this.comboDiv.bind("click", function(e) { e.stopPropagation(); self._toggleList(true); });
    this.inputDiv.bind("keyup", function(e) { self._inputKeyUp(e); });
    this.inputDiv.bind("keydown", function(e) { self._inputKeyDown(e); });
    $("html").bind("click.picker", function() { self._undoChanges(); });
    $(window).bind("resize.picker", function() { self._toggleList(false); });

    // Fetch the remote content
    this._requestIndex();
  },

  destroy: function() {

    // Clear the event handlers
    this.comboDiv.unbind();
    this.inputDiv.unbind();
    $("li", this.listDiv).unbind();
    $("html").unbind("click.picker");
    $(window).unbind("resize.picker");

    // Destroy the document model
    this.element.removeClass("ui-picker");
    this.bodyDiv.remove();
    this.popupDiv.remove();

    $.widget.prototype.destroy.apply(this, arguments);
  },

  // Enables/disables user input
  _enabled: function(enabled) {
    this.enabled = enabled;
    if (enabled) {
      this.inputDiv.val("");
      this.inputDiv.removeClass("ui-state-disabled ui-picker-combo-loading");
      this.buttonDiv.removeClass("ui-state-disabled");
    } else {
      this.popupDiv.hide();
      this.inputDiv.val("Loading...");
      this.inputDiv.addClass("ui-state-disabled ui-picker-combo-loading");
      this.buttonDiv.addClass("ui-state-disabled");
    }
  },

  // Fetches the picker index file from the server
  _requestIndex: function() {

    // Disable user interaction
    this._enabled(false);

    // Configure the request options
    var options = {
      url: this.options.type + "/index.json",
      dataType: "json",
      cache: false,
      success: $.call(this, "_handleIndexSuccess"),
      error: $.call(this, "_handleIndexError"),
    };

    // Fetch the index elements
    $.ajax(options);
  },

  // Handles picker index file responses from the server
  _handleIndexSuccess: function(items, status) {

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
    this.inputDiv.focus();
  },

  // Handles picker index file error responses from the server
  _handleIndexError: function(request, status, error) {
    $.logger.error("Error retrieving list index: " + this.options.type, status);
  },

  // Creates a single item in the picker list
  _createItem: function(item) {
    var itemDiv = $('<li class="ui-state-default ui-corner-all" />');
    var nameDiv = $('<div class="item-name">' + item.name + '</div>').appendTo(itemDiv);
    var descDiv = $('<div class="item-desc">' + item.tip + '</div>').appendTo(itemDiv);
    return itemDiv;
  },

  // Toggles whether the picker button is activated
  _toggleButton: function() {
    if (!this.enabled || this.buttonDiv.hasClass("ui-state-hover")) {
      this.buttonDiv.removeClass("ui-state-hover");
    } else {
      this.buttonDiv.addClass("ui-state-hover");
    }
  },

  // Toggles whether a list item is highlighted
  _toggleItem: function(item) {
    this.hovered = item;
    if (this.hovered == undefined) {
      return;
    }

    // Check if the item should no longer be hovered
    if (item.hasClass("ui-state-hover")) {
      item.removeClass("ui-state-hover");
      this.hovered = undefined;
      return;
    }

    // Find the offset of the new item to hover
    var top = item.offset().top;
    var offset = Math.ceil(top / this.listDiv.itemHeight) * this.listDiv.itemHeight;

    // Check whether the item is currently visible
    if (top < this.listDiv.itemHeight - 1) {

      // Move the list down because the item is scrolled off the top
      offset -= this.listDiv.itemHeight;
      var newTop = this.listDiv.scrollTop() + offset;
      newTop -= (newTop % this.listDiv.itemHeight);
      this.listDiv.scrollTop(newTop > 0 ? newTop : 0);
    } else if (top > this.listDiv.maxHeight - 1) {

      // Move the list up because the item is scrolled off the bottom
      offset -= this.listDiv.maxHeight;
      var newTop = this.listDiv.scrollTop() + offset;
      newTop -= (newTop % this.listDiv.itemHeight);
      var maxHeight = this.listDiv.attr("scrollHeight");
      this.listDiv.scrollTop(newTop < maxHeight ? newTop : maxHeight);
    }
    item.addClass("ui-state-hover");
  },

  // Toggles whether the picker list is visible
  _toggleList: function(visible) {
    var oldVisible = this.popupDiv.is(":visible");
    if (!this.enabled || visible != true) {

      // Hide the list of items
      this.listDiv.scrollTop(0);
      this.popupDiv.hide();
      this.inputDiv.addClass("ui-corner-bl");
      this.buttonDiv.addClass("ui-corner-br");

      // Check if the list was visible
      if (oldVisible) {
        this._toggleItem(this.hovered);
        this.inputDiv.focus();
      }
    } else if (!oldVisible) {

      // Find the height of a single item while the list is off-screen
      var listW = this.comboDiv.width() - 3;
      this.popupDiv.css({ width: listW, left: -2 * listW });
      this.popupDiv.show();
      var itemH = $("li:first", this.listDiv).outerHeight(true);
      this.popupDiv.hide();

      // Calculate the position and dimensions for the list
      var offset = this.comboDiv.offset();
      var listT = offset.top + this.comboDiv.height() + 2;
      var maxH = ($(window).height() / 2) - listT;
      var listH = Math.floor(maxH / itemH) * itemH; 
      this.popupDiv.css({ left: offset.left, top: listT });
      this.listDiv.css({ height: listH });

      // Set the position of the shadow
      this.shadowDiv.width(listW);
      this.shadowDiv.height(listH);

      // Store the dimensions for use during dynamic filtering
      this.listDiv.maxHeight = listH;
      this.listDiv.itemHeight = itemH;
      this.listDiv.pageSize = (listH / itemH);

      // Display the list of items
      this.popupDiv.show();
      this.inputDiv.removeClass("ui-corner-bl");
      this.buttonDiv.removeClass("ui-corner-br");

      // Attempt to move the list to the last selection
      if (this.selectionIndex >= 0) {
        this._toggleItem($("li", this.listDiv).eq(this.selectionIndex));
      }

      this.inputDiv.focus();
    }
  },

  // Handles keyboard input from the picker box
  _inputKeyDown: function(e) {
    if (!this.popupDiv.is(":visible")) {
      return;
    }

    if (e.keyCode == 38) {

      // Move the list to the previous item when up is pressed
      if (this.hovered) {
        var prevItem = this.hovered.prevAll(":visible").eq(0);
        if (prevItem.length > 0) {
          this._toggleItem(this.hovered);
          this._toggleItem(prevItem);
        }
      } else {
        this._toggleItem($("li:visible", this.listDiv).eq(0));
      }
    } else if (e.keyCode == 40) {

      // Move the list to the next item when down is pressed
      if (this.hovered) {
        var nextItem = this.hovered.nextAll(":visible").eq(0);
        if (nextItem.length > 0) {
          this._toggleItem(this.hovered);
          this._toggleItem(nextItem);
        }
      } else {
        this._toggleItem($("li:visible", this.listDiv).eq(0));
      }
    } else if (e.keyCode == 33) {

      // Move the list to the previous page when page up is pressed
      var page = this.listDiv.pageSize;
      var visItems = $("li:visible", this.listDiv);
      var offset = (this.listDiv.scrollTop() / this.listDiv.itemHeight) - page;
      var index = (offset > 0 ? offset : 0);

      this._toggleItem(this.hovered);
      this._toggleItem(visItems.eq(index));
    } else if (e.keyCode == 34) {

      // Move the list to the next page when page down is pressed
      var page = this.listDiv.pageSize;
      var visItems = $("li:visible", this.listDiv);
      var offset = (this.listDiv.scrollTop() / this.listDiv.itemHeight) + (2 * page) - 1;
      var index = (offset < visItems.length ? offset : visItems.length - 1);

      this._toggleItem(this.hovered);
      this._toggleItem(visItems.eq(index));
    }

    if (this.hovered && e.keyCode >= 33 && e.keyCode <= 40) {
      this.inputDiv.val($("div.item-name", this.hovered).text());
    }
  },

  // Handles keyboard input from the picker box
  _inputKeyUp: function(e) {

    // Reset the list when escape is pressed
    if (e.keyCode == 27) {
      this._undoChanges();
      return;
    }

    // Ignore keys used for navigation
    if (e.keyCode >= 33 && e.keyCode <= 40) {
      this._toggleList(true);
      return;
    }

    if (e.keyCode == 13) {

      // Find the index of the item that matches the input when enter is pressed
      var index = -1;
      var input = this.inputDiv.val().toLowerCase();
      for (var i = 0; i < this.items.length; i++) {
        if (this.items[i].name.toLowerCase() == input) {
          index = i;
          break;
        }
      }

      // Update the selection
      this._itemSelected(index);
    } else {

      // Update the filter based on the new text input
      var filter = this.inputDiv.val().toLowerCase();
      if (this.filter != filter) {
        this.filter = filter;

        // Clear the last hover focus
        this._toggleItem(this.hovered);

        // Update the list to show only items that match
        this._filterList(filter);
      }
    }
  },

  // Filters the list of picker list items based on user input
  _filterList: function(filter) {

    // Show only items that match the given filter
    var count = 0;
    var itemDivs = $("li", this.listDiv);
    for (var i = 0; i < this.items.length; i++) {
      var item = this.items[i];
      var matches = (filter.length == 0
          || item.name.toLowerCase().indexOf(filter) >= 0
          || item.tip.toLowerCase().indexOf(filter) >= 0);
      itemDivs.eq(i).toggle(matches);
      count += (matches ? 1 : 0);
    }

    if (count == 0) {

      // Simply hide the list if there are matching items
      this._toggleList(false);
    } else if (this.listDiv.count != count) {

      // Re-size the list if the number of matched items changed
      this.listDiv.count = count;
      var prefH = count * this.listDiv.itemHeight;

      if (prefH > this.listDiv.maxHeight) {
        this.listDiv.css({ height: this.listDiv.maxHeight, overflowY: "scroll" });
        this.shadowDiv.height(this.listDiv.maxHeight);
        this._toggleList(true);
      } else if (prefH != this.listDiv.height()) {
        this._toggleList(true);
        this.listDiv.css({ height: prefH, overflowY: "scroll" });
        this.shadowDiv.height(prefH);
      }
    }
  },

  // Reverts the filter input box to its previous value
  _undoChanges: function() {
    this._filterList("");
    this.inputDiv.val(this.selection ? this.selection.name : "");
    this._toggleList(false);
  },

  // Fetches the content associated with the picker selection
  _itemSelected: function(index) {

    // Clear the old selected item
    if (this.selection) {
      $("li", this.listDiv).eq(this.selectionIndex).removeClass("ui-state-highlight");
    }

    // Store the selection for future use
    this.selection = (index >= 0 ? this.items[index] : undefined);
    this.selectionIndex = index;

    // Clear the last hovered item
    this._toggleItem(this.hovered);
    this._filterList("");
    this._toggleList(false);

    // Notify listeners if the selection was cleared
    if (!this.selection) {
      if (this.options.callback) {
        this.options.callback();
      }
      return;
    }

    // Update the appearance of the widget
    this.inputDiv.val(this.selection.name);
    $("li", this.listDiv).eq(this.selectionIndex).addClass("ui-state-highlight");

    // Configure the request options
    var options = {
      url: this.selection.url,
      dataType: "json",
      cache: false,
      success: $.call(this, "_handleContentSuccess"),
      error: $.call(this, "_handleContentError"),
    };

    // Fetch the content for the selected item
    $.ajax(options);
  },

  // Handles picker content file responses from the server
  _handleContentSuccess: function(data, status) {

    // Notify the listener of the selection
    if (this.options.callback) {
      this.options.callback(this.selection, data);
    }
  },

  // Handles picker content file error responses from the server
  _handleContentError: function(request, status, error) {
    $.logger.error("Error selecting list item: " + this.selection.name, status);

    // Notify the listener of the failure
    if (this.options.callback) {
      this.options.callback();
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
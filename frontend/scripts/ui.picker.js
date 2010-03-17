(function($) {

$.widget("ui.picker", {

  _init: function() {
    var self = this;
    this.items = [];
    this.filter = "";
    this.input = "";
    this.selection = undefined;
    this.selIndex = -1;
    this.navIndex = -1;

    // Build the document model
    this.element.addClass("ui-picker");
    this.bodyDiv = $('<div class="ui-widget-header ui-corner-all'
        + ' ui-picker-body"/>').appendTo(this.element);
    $('<div class="ui-picker-title">' + this.options.title
        + '</div>').appendTo(this.bodyDiv);

    this.comboDiv = $('<div class="ui-picker-combo"/>').appendTo(this.bodyDiv);
    this.inputDiv = $('<input class="ui-widget-content ui-corner-tl'
        + ' ui-corner-bl ui-picker-combo-input"/>').appendTo(this.comboDiv);
    this.buttonDiv = $('<div class="ui-state-default ui-corner-tr ui-corner-br'
        + ' ui-picker-combo-button" title="Click to choose from a list of '
        + this.options.title.toLowerCase() + '"/>').appendTo(this.comboDiv);
    $('<span class="ui-icon ui-icon-circle-triangle-s"/>').appendTo(this.buttonDiv);
    if (this.options.selection) {
      this.comboDiv.hide();
    }

    this.popupDiv = $('<div class="ui-picker-popup"/>').appendTo($("body"));
    this.popupContentDiv = $('<div class="ui-corner-bottom ui-picker-popup-content"/>').appendTo(this.popupDiv);
    this.listDiv = $('<div class="ui-picker-list"/>').appendTo(this.popupContentDiv);
    this.shadowDiv = $('<div class="ui-widget-shadow ui-corner-all ui-picker-shadow"/>').appendTo(this.popupDiv);
    this.popupDiv.hide();

    // Bind the event handlers
    this.comboDiv.bind("mouseenter", function(e) { self._toggleButton(); });
    this.comboDiv.bind("mouseleave", function(e) { self._toggleButton(); });
    this.buttonDiv.bind("click", function(e) { e.stopPropagation(); self._toggleList(true); });
    this.inputDiv.bind("keyup", function(e) { self._inputKeyUp(e); });
    this.inputDiv.bind("keydown", function(e) { self._inputKeyDown(e); });
    $("html").bind("click.picker", function(e) { self._undoChanges(e); });
    $(window).bind("resize.picker", function(e) { self._resize(); });
    $(window).bind("hashchange.picker", function(e) { self._addressChanged(e); });

    // Fetch the remote content
    if (this.options.selection) {
      this.selection = { id: this.options.selection };
      this._requestSelection(this.selection);
    } else {
      this._requestIndex();
    }
  },

  destroy: function() {

    // Clear the event handlers
    this.comboDiv.unbind();
    this.inputDiv.unbind();
    $("li", this.listDiv).unbind();
    $("html").unbind("click.picker");
    $(window).unbind("resize.picker");
    $(window).unbind("hashchange.picker");

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

    // Check whether the list dimensions need to be calculated
    if (this.listDiv.maxHeigh == undefined) {
      this._resize();
    }

    // Bind event handlers to the list items
    var self = this;
    $("li", this.listDiv).each(function(i) {
      $(this).bind("mouseenter", function() {
        if (!$(this).hasClass("ui-state-highlight")) {
          $(this).addClass("ui-state-hover");
        }
      });
      $(this).bind("mouseleave", function() {
        $(this).removeClass("ui-state-hover");
      });
    });

    // Enable user interaction
    this._enabled(true);
    this.inputDiv.focus();

    // Apply the current selection id in the address fragment
    $(window).trigger("hashchange");
  },

  // Handles picker index file error responses from the server
  _handleIndexError: function(request, status, error) {
    $.logger.error("Error retrieving list index: " + this.options.type, status);
  },

  // Creates a single item in the picker list
  _createItem: function(item) {
    var itemDiv = $('<li class="ui-state-default ui-corner-all" />');
    var linkDiv = $('<a href="#' + item.id + '"/>').appendTo(itemDiv);
    var nameDiv = $('<span class="item-name">' + item.name + '</span>').appendTo(linkDiv);
    var descDiv = $('<span class="item-desc">' + item.tip + '</span>').appendTo(linkDiv);
    return itemDiv;
  },

  _resize: function() {

    // Hide the list if it is currently displayed
    this._toggleList(false);

    // Check whether there any prototype list items available yet
    if (this.items.length == 0) {
      this.listDiv.maxHeight = 0;
      this.listDiv.itemHeight = 0;
      this.listDiv.pageSize = 0;
      return;
    }

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

    var currentH = Math.min(this.items.length * itemH, listH);
    this.listDiv.css("height", currentH);

    // Set the position of the shadow
    this.shadowDiv.width(listW);
    this.shadowDiv.height(currentH);

    // Store the dimensions for use during dynamic filtering
    this.listDiv.maxHeight = listH;
    this.listDiv.itemHeight = itemH;
    this.listDiv.pageSize = (listH / itemH);
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

    // Remove the hover state of the old item
    if (this.hovered) {
      this.hovered.removeClass("ui-state-hover");
    }

    // Check whether a new hover item was given
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

    if (!item.hasClass("ui-state-highlight")) {
      item.addClass("ui-state-hover");
    }
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
        this._toggleItem();
        this.inputDiv.focus();
      }
    } else if (!oldVisible) {

      // Display the list of items
      this.popupDiv.show();
      this.inputDiv.removeClass("ui-corner-bl");
      this.buttonDiv.removeClass("ui-corner-br");

      // Attempt to move the list to the last selection
      if (this.selIndex >= 0) {
        this._toggleItem($("li", this.listDiv).eq(this.selIndex));
      }

      this.inputDiv.focus();
    }
  },

  // Handles keyboard input from the picker box
  _inputKeyDown: function(e) {
    var navSelect = (this.navIndex >= 0 && !this.popupDiv.is(":visible"));

    if (e.keyCode == 38) {

      // Move the list to the previous item when up is pressed
      if (this.hovered) {
        var prevItem = this.hovered.prevAll(":visible").eq(0);
        if (prevItem.length > 0) {
          this._toggleItem(prevItem);
        }
      } else if (navSelect) {
        this.navIndex = (this.navIndex > 0 ? this.navIndex - 1 : this.items.length - 1);
        this.inputDiv.val(this.items[this.navIndex].name);
      } else {
        this._toggleList(true);
        this._toggleItem($("li:visible", this.listDiv).eq(0));
      }
    } else if (e.keyCode == 40) {

      // Move the list to the next item when down is pressed
      if (this.hovered) {
        var nextItem = this.hovered.nextAll(":visible").eq(0);
        if (nextItem.length > 0) {
          this._toggleItem(nextItem);
        }
      } else if (navSelect) {
        this.navIndex = (this.navIndex < this.items.length - 1 ? this.navIndex + 1 : 0);
        this.inputDiv.val(this.items[this.navIndex].name);
      } else {
        this._toggleList(true);
        this._toggleItem($("li:visible", this.listDiv).eq(0));
      }
    } else if (e.keyCode == 33) {

      // Move the list to the previous page when page up is pressed
      var page = this.listDiv.pageSize;
      if (navSelect) {
        this.navIndex -= page;
        this.navIndex += (this.navIndex < 0 ? this.items.length : 0);
        this.inputDiv.val(this.items[this.navIndex].name);
      } else {
        this._toggleList(true);
        var visItems = $("li:visible", this.listDiv);
        var offset = (this.listDiv.scrollTop() / this.listDiv.itemHeight) - page;
        var index = (offset > 0 ? offset : 0);
        this._toggleItem(visItems.eq(index));
      }
    } else if (e.keyCode == 34) {

      // Move the list to the next page when page down is pressed
      var page = this.listDiv.pageSize;
      if (navSelect) {
        this.navIndex += page;
        this.navIndex -= (this.navIndex >= this.items.length ? this.items.length : 0);
        this.inputDiv.val(this.items[this.navIndex].name);
      } else {
        this._toggleList(true);
        var visItems = $("li:visible", this.listDiv);
        var offset = (this.listDiv.scrollTop() / this.listDiv.itemHeight) + (2 * page) - 1;
        var index = (offset < visItems.length ? offset : visItems.length - 1);
        this._toggleItem(visItems.eq(index));
      }
    }

    // Update the input box based on the current hovered item name
    if (this.hovered && e.keyCode >= 33 && e.keyCode <= 40) {
      this.inputDiv.val($("span.item-name", this.hovered).text());
    }
  },

  // Handles keyboard input from the picker box
  _inputKeyUp: function(e) {

    // Reset the list when escape is pressed
    if (e.keyCode == 27) {
      this._undoChanges();
      return;
    }

    // Check whether a navigation key was pressed
    var navPressed = (e.keyCode >= 33 && e.keyCode <= 40);

    // Check whether the selection should be adjusted based on key navigation
    var navSelect = (navPressed && this.selIndex >= 0
        && !this.popupDiv.is(":visible"));

    if (e.keyCode == 13 || navSelect) {

      // Select the item that matches the current input when enter is pressed
      this._selectName(this.inputDiv.val());
    } else if (!navPressed) {

      // Update the filter based on the new text input
      var filter = this.inputDiv.val().toLowerCase();
      if (this.filter != filter) {

        // Clear the last hover focus
        this._toggleItem();

        // Update the list to show only items that match
        this._filterList(filter);
      }
    }
  },

  // Filters the list of picker list items based on user input
  _filterList: function(filter) {
    this.filter = filter;
    if (filter == undefined) {
      return;
    }

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

    // Simply hide the list if there are matching items
    if (count == 0) {
      this._toggleList(false);
      return;
    }

    if (this.listDiv.count != count) {

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
    } else {
      this._toggleList(true);
    }
    this.listDiv.scrollTop(0);
  },

  // Reverts the filter input box to its previous value
  _undoChanges: function(e) {

    // Make sure the list visible
    if (this.popupDiv.is(":visible")) {

      // Ignore click events on the input box
      if (e && $(e.target).parents(".ui-picker-combo").length > 0) {
        return;
      }

      // Reset the input box content and hide the list
      this._filterList("");
      this.inputDiv.val(this.selection ? this.selection.name : "");
      this._toggleList(false);
    } else {

      // Restore the last selection name
      this.inputDiv.val(this.selection ? this.selection.name : "");

      // Reset the filter if the user ever entered one
      if (this.filter) {
        this._filterList(this.inputDiv.val().toLowerCase());
      }
    }
  },

  // Selects the content associated with the given id
  _selectId: function(id) {
    id = (id ? $.trim(id).toLowerCase() : "");
    for (var i = 0; i < this.items.length; i++) {
      if (this.items[i].id == id) {
        this._selectIndex(i);
        break;
      }
    }
  },

  // Selects the content associated with the given name
  _selectName: function(name) {
    name = (name ? $.trim(name).toLowerCase() : "");
    if (this.selection && this.selection.name.toLowerCase() == name) {
      this._filterList();
      this._toggleList(false);
      return;
    }
    for (var i = 0; i < this.items.length; i++) {
      if (this.items[i].name.toLowerCase() == name) {
        window.location.assign("#" + this.items[i].id);
        break;
      }
    }
  },

  // Fetches the content associated with the given selection
  _selectIndex: function(index) {
    if (index == this.selIndex) {
      return;
    }

    // Clear the old selected item
    if (this.selection) {
      var selectedDiv = $("li", this.listDiv).eq(this.selIndex);
      selectedDiv.removeClass("ui-state-highlight");
      selectedDiv.addClass("ui-state-default");
    }

    // Store the selection for future use
    this.selection = (index >= 0 && index < this.items.length ? this.items[index] : undefined);
    this.selIndex = (this.selection ? index : -1);
    this.navIndex = this.selIndex;

    // Clear the last hovered item
    this._toggleItem();
    this._filterList();
    this._toggleList(false);

    // Notify listeners if the selection was cleared
    if (!this.selection) {
      if (this.options.callback) {
        this.options.callback({ selection: undefined });
      }
      return;
    }

    // Update the appearance of the widget
    this.inputDiv.val(this.selection.name);
    var selectedDiv = $("li", this.listDiv).eq(this.selIndex);
    selectedDiv.removeClass("ui-state-default");
    selectedDiv.addClass("ui-state-highlight");

    this._requestSelection(this.selection);
  },

  _requestSelection: function(selection) {
    if (this.loading) {
      this.nextLoad = selection;
      return;
    }
    this.loading = selection;

    // Notify listeners that the data is being loaded
    if (this.options.callback) {
      this.options.callback({ loading: true });
    }

    // Configure the request options
    var options = {
      url: this.options.type + "/" + selection.id + ".json",
      dataType: "json",
      cache: false,
      success: $.call(this, "_handleContentSuccess"),
      error: $.call(this, "_handleContentError"),
      complete: $.call(this, "_handleContentComplete")
    };

    // Fetch the content for the selected item
    $.ajax(options);
  },

  // Handles picker content file responses from the server
  _handleContentSuccess: function(data, status) {

    // Notify the listener of the selection
    if (this.options.callback && this.nextLoad == undefined) {
      this.options.callback({ selection: this.selection, data: data });
    }
  },

  // Handles picker content file error responses from the server
  _handleContentError: function(request, status, error) {

    // Notify the listener of the failure
    if (this.options.callback && this.nextLoad == undefined) {
      this.options.callback({ error: true });
    }
  },

  _handleContentComplete: function(request, status) {
    this.loading = undefined;
    if (this.nextLoad) {
      this._requestSelection(this.nextLoad);
      this.nextLoad = undefined;
    }
  },

  // Callback when the browser address changes
  _addressChanged: function(e) {

    // Select the item based on the id from the anchor fragment
    var id = $.param.fragment();
    if (id.length > 0) {
      this._selectId(id);
    } else {
      this.inputDiv.val("");
      this._selectIndex(-1);
    }
  }

});

$.extend($.ui.picker, {
  version: "1.7.2",
  defaults: {
    title: "",
    type: "",
    selection: undefined,
    callback: undefined
  }
});

})(jQuery);
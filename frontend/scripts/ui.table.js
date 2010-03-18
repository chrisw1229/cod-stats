(function($) {

$.widget("ui.table", {

  _init: function() {
    var self = this;
    this.columns = [];
    this.rows = [];
    this.sortIndex = this.options.sortIndex;
    this.sortAsc = this.options.sortAsc;

    // Build the document model
    this.containerDiv = $('<div class="ui-table"/>').appendTo(this.element);
    this.tableDiv = $('<table class="ui-table-content" />').appendTo(this.containerDiv);
    this.bodyDiv = $('<tbody class="ui-table-body"/>').appendTo(this.tableDiv);
    this.headerDiv = $('<tr class="ui-table-header"/>').appendTo(this.bodyDiv);
    this.footerDiv = $('<tr class="ui-table-footer"><td class="ui-state-default ui-corner-bottom" colspan="0">&nbsp;</td></tr>').appendTo(this.bodyDiv);
    this.emptyDiv = $('<tr class="ui-state-active ui-table-empty"><td colspan="0">No Records Available</td></tr>');
    this.loadDiv = $('<tr class="ui-state-active ui-table-load"><td colspan="0"><span class="ui-icon"/>Loading...</td></tr>');
    this.errorDiv = $('<tr class="ui-state-error ui-table-error"><td colspan="0"><span class="ui-icon ui-icon-alert"/>ERROR - Records Not Found</td></tr>');

    this.setColumns(this.options.columns);
  },

  destroy: function() {

    // Clear the event handlers
    this.headerDiv.children().unbind();

    // Destroy the document model
    this.containerDiv.remove();

    $.widget.prototype.destroy.apply(this, arguments);
  },

  setColumns: function(columns) {
    var self = this;

    // Reset the table to clear previous columns and rows
    this.reset();

    // Make sure there are columns to display
    if (columns == undefined || columns.length <= 0) {
      return;
    }

    // Create a column element to store the row number
    this.headerDiv.children().remove();
    $('<th class="ui-state-default ui-corner-tl ui-table-cell-num">#</th>').appendTo(this.headerDiv);

    // Add the new table column header elements
    var sortIndex = -1;
    for (var i = 0; i < columns.length; i++) {

      // Store the column data for future use
      var column = columns[i];
      this.columns.push(column);

      // Check if this is the default sort column
      sortIndex = (column.sort != undefined ? i : sortIndex);

      // Create an element to represent the column header
      column.div = $('<th class="ui-state-default ui-table-header'
          + (i == this.sortIndex ? "-sorted" : "") + '">'
          + column.name + '</th>').appendTo(this.headerDiv);
      $('<span class="ui-icon ui-icon-triangle-1-' + (this.sortAsc ? "n" : "s")
          + ' ui-table-sort-icon"/>').appendTo(column.div);

      // Bind event listeners to the column
      column.div.hover(function() { $(this).addClass("ui-state-hover"); },
          function() { $(this).removeClass("ui-state-hover"); });
      column.div.bind("click", { index: i },
          function(e) { self.setSort(e.data.index); });
    }

    // Align the various message and footer row elements
    this.emptyDiv.children(":first").attr("colspan", columns.length + 1);
    this.loadDiv.children(":first").attr("colspan", columns.length + 1);
    this.errorDiv.children(":first").attr("colspan", columns.length + 1);
    this.footerDiv.children(":first").attr("colspan", columns.length + 1);

    // Style the table boundaries
    this.columns[this.columns.length - 1].div.addClass("ui-corner-tr");

    // Update the default sort if applicable
    if (sortIndex >= 0) {
      this.setSort(sortIndex, this.columns[sortIndex].sort);
    }
  },

  setRows: function(rows) {
    rows = ($.isArray(rows) ? rows : [ rows ]);

    // Clear the current table data
    this.clear();

    // Add all the new rows to the model
    this.rows = this.rows.concat(rows);

    // Sort the rows based on the current sort column
    this._sort();

    // Create table elements for each row of values
    for (var i = 0; i < this.rows.length; i++) {
      this._createRow(i);
    }

    // Fill the table elements with row values
    this._display();
  },

  setSort: function(index, asc) {

    // Check whether the sort actually changed
    if (this.sortIndex == index && this.sortAsc == asc) {
      return;
    }

    // Set the sort direction based on the input
    if (this.sortIndex == index) {
      this.sortAsc = (asc != undefined ? asc : !this.sortAsc);
      this.rows.reverse();
    } else {
      this.sortIndex = index;
      this.sortAsc = (asc != undefined ? asc : true);

      this._sort();
    }

    // Update the sort direction icon
    $(".ui-table-header-sorted", this.headerDiv).removeClass(
        "ui-table-header-sorted").addClass("ui-table-header");
    $(".ui-table-header", this.headerDiv).eq(this.sortIndex).removeClass(
        "ui-table-header").addClass("ui-table-header-sorted");
    $(".ui-table-sort-icon", this.headerDiv).attr("class",
        "ui-icon ui-icon-triangle-1-" + (this.sortAsc ? "n" : "s")
        + " ui-table-sort-icon");

    // Fill the table elements with row values
    this._display();
  },

  clear: function() {
    this.rows = [];
    $(".ui-table-row", this.bodyDiv).remove();

    // Display the empty table message
    this.loadDiv.remove();
    this.errorDiv.remove();
    this.emptyDiv.insertBefore(this.footerDiv);
  },

  reset: function() {

    // Clear the current table data
    this.clear();

    // Cleanup any previous table columns
    this.columns = [];
    var oldColumns = this.headerDiv.children();
    oldColumns.unbind();
    oldColumns.remove();

    // Add a default column to display
    $('<th class="ui-state-default ui-corner-top ui-table-cell-empty">&nbsp;</th>').appendTo(this.headerDiv);
  },

  loading: function() {
    this.reset();
    this.emptyDiv.remove();
    this.errorDiv.remove();
    this.loadDiv.insertBefore(this.footerDiv);
  },

  error: function() {
    this.reset();
    this.emptyDiv.remove();
    this.loadDiv.remove();
    this.errorDiv.insertBefore(this.footerDiv);
  },

  _sort: function() {
    var index = this.sortIndex;
    var asc = this.sortAsc;

    // Check if the sort index is valid
    if (index != undefined && index >= 0 && index < this.rows.length) {

      // Use the standard sort function with custom comparator
      this.rows.sort(function(row1, row2) {

        // Make sure string comparisons are case-insensitive
        var val1 = row1[index];
        val1 = (typeof(val1) == "string" ? val1.toLowerCase() : val1);
        var val2 = row2[index];
        val2 = (typeof(val2) == "string" ? val2.toLowerCase() : val2);

        // Adjust the result based on the sort direction
        if (val1 < val2) {
          return (asc ? -1 : 1);
        } else if (val1 > val2) {
          return (asc ? 1 : -1);
        }
        return 0;
      });
    }
  },

  _display: function() {

    // Check if the table contains row data
    if (this.rows.length == 0) {
      return;
    }

    // Remove the loading and empty table messages
    this.emptyDiv.remove();
    this.loadDiv.remove();

    // Fill in each row of values
    var rowDivs = this.bodyDiv.children();
    for (var i = 1; i < rowDivs.length - 1; i++) {
      var cellDivs = $(rowDivs[i]).children();

      // Fill in each cell of values
      var r = i - 1;
      for (var j = 1; j < cellDivs.length; j++) {
        var c = j - 1;

        // Check if there is a value defined for the cell
        if (r < this.rows.length && c < this.rows[r].length) {
          $(cellDivs[j]).text(this.rows[r][c]);
        } else {
          $(cellDivs[j]).text("");
        }
      }
    }
  },

  _createRow: function(index) {

    // Create a new table row to store the data
    var sequence = (index % 2 == 0 ? "even" : "odd");
    var rowDiv = $('<tr class="ui-table-row ui-table-row-' + sequence + '"/>').insertBefore(this.footerDiv);

    // Create a cell to display the row number
    $('<td class="ui-table-cell ui-table-cell-num">' + (index + 1) + '</td>').appendTo(rowDiv);

    // Add all the values as cells to the table row
    for (var i = 0; i < this.columns.length; i++) {
      $('<td class="ui-table-cell"/>').appendTo(rowDiv);
    }
  }

});

$.extend($.ui.table, {
  version: "1.7.2",
  defaults: {
    columns: [],
    sortIndex: -1,
    sortAsc: undefined
  }
});

})(jQuery);
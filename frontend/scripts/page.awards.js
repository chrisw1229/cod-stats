// Handles all the controller logic for the awards page
$(function() {

// Register the page manager as a jQuery extension
$.extend({ mgr: {

  // Callback when the user selects an award
  itemSelected: function(selection, data) {
    if (selection && data) {
      $("#table").table("setColumns", data.columns);
      $("#table").table("setRows", data.rows);
    } else {
      $("#table").table("reset");
    }
  }

}});

  // Load the custom jQuery user interface components
  $("#nav").navigation();
  $("#picker").picker({ type: "awards", title: "Player Awards",
      callback: $.mgr.itemSelected });
  $("#table").table({ sortIndex: 1, sortAsc: false });
});
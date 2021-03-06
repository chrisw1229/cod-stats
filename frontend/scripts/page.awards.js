// Handles all the controller logic for the awards page
$(function() {

// Register the page manager as a jQuery extension
$.extend({ mgr: {

  // Callback when the user selects an award
  itemSelected: function(e) {
    if (e.selection && e.data) {
      $("#table").table("setColumns", e.data.columns);
      $("#table").table("setRows", e.data.rows);
    } else if (e.loading) {
      $("#table").table("loading");
    } else if (e.error) {
      $("#table").table("error");      
    } else {
      $("#table").table("reset");
    }
  }

}});

  // Load the custom jQuery user interface components
  $("#nav").navigation();
  $("#table").table();
  $("#picker").picker({ type: "awards", title: "Player Awards",
      callback: $.mgr.itemSelected });
});
// Handles all the controller logic for the awards page
$(function() {

// Register the page manager as a jQuery extension
$.extend({ mgr: {

  // Callback when the user selects an award
  itemSelected: function(selection, data) {
    $("#table tbody tr").remove();
    var table = $("#table tbody");
    for (var i = 0; i < data.length; i++) {
      $('<tr><td>' + data[i].player + '</td><td>' + data[i].value
          + '</td></tr>').appendTo(table);
    }
  }

}});

  // Load the custom jQuery user interface components
  $("#nav").navigation();
  $("#picker").picker({ type: "awards", title: "Player Awards",
      callback: $.mgr.itemSelected });
});
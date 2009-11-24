// Handles all the controller logic for the live front page
$(function() {

// Register the page manager as a jQuery extension
$.extend({ mgr: {

  update: (location.href.match(/(.*\?update.*)|(.*&update.*)/i) != null),

  randMarkers: function(count) {
    var markers = [];
    for (var i = 0; i < count; i++) {
      var dx = ((parseInt(Math.random() * 3700))) + 200;
      var dy = ((parseInt(Math.random() * 2700))) + 700;
      var kx = ((parseInt(Math.random() * 3700))) + 200;
      var ky = ((parseInt(Math.random() * 2700))) + 700;
      markers.push({ dx: dx, dy: dy, kx: kx, ky: ky });
    }
    return markers;
  }
}});

  // Load the custom jQuery user interface components
  $("#nav").navigation();
  $("#ticker").ticker();
  $("#meter").meter();

  // Load the map component with a default map
  Map.load("#map", { map: "carentan" });

  // Check whether dynamic updates are enabled
  if ($.mgr.update) {

    // Configure the network processors
    $.comm.bind("map", Map.addMarkers);

    // Start fetching data from the server
    setTimeout(function() { $.comm.update(); }, 2000);
  } else {

    // Fill the map with random markers if dynamic updates are disabled
    setTimeout(function() { Map.addMarkers($.mgr.randMarkers(10)); }, 1000);
    setInterval(function() { Map.addMarkers($.mgr.randMarkers(2)); }, 2000);
  }
});
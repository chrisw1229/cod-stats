// Handles all the controller logic for the live front page
$(function() {

// Register the page manager as a jQuery extension
$.extend({ mgr: {

  // Indicates whether or not live updates should be retrieved
  update: ($.getParam(location.href, "update") != null),

  // Indicates whether or not the test service should be used
  test: $.getParam(location.href, "test"),

  // TODO Remove this function that generates random map markers
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
  },

  // Server callback when the game changes
  gameChanged: function(data) {
    Map.setTiles(data.map);
  },

  // Server callback when map markers change
  mapChanged: function(data) {
    Map.addMarkers(data);
  },

  // Server callback when a log message is generated
  logReceived: function(data) {
    if (data.error) {
      $.logger.error(data.msg, data.error);
    } else {
      $.logger.info(data.msg);
    }
  }
}});

  // Load the custom jQuery user interface components
  $("#nav").navigation();
  $("#ticker").ticker();
  $("#meter").meter();

  // Check whether dynamic updates are enabled
  if ($.mgr.update) {

    // Load the map component with an empty map
    Map.load("#map");

    // Configure the network processors
    $.comm.service = ($.mgr.test ? "test" : "live");
    $.comm.params = ($.mgr.test ? { test: $.mgr.test } : { });
    $.comm.bind("game", $.mgr.gameChanged);
    $.comm.bind("map", $.mgr.mapChanged);
    $.comm.bind("log", $.mgr.logReceived);

    // Start fetching data from the server
    setTimeout(function() { $.comm.update(); }, 2000);
  } else {

    // Load the map component with a default set of tiles
    Map.load("#map", { tiles: "carentan" });

    // Fill the map with random markers if dynamic updates are disabled
    setTimeout(function() { Map.addMarkers($.mgr.randMarkers(10)); }, 1000);
    setInterval(function() { Map.addMarkers($.mgr.randMarkers(2)); }, 2000);
  }
});
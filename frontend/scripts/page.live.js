// Handles all the controller logic for the live front page
$(function() {

// Register the page manager as a jQuery extension
$.extend({ mgr: {

  // Indicates whether or not the test service should be used
  test: $.getParam(location.href, "test"),

  // Callback from the server when the game changes
  gameChanged: function(data) {
    $("#meter").meter("reset", data.time);
    Map.clearMarkers();
    Map.setTiles(data.map);
  },

  // Callback from the server when a player changes
  playerChanged: function(data) {
    $("#ticker").ticker("updateItems", data);
  },

  // Callback from the server when an event changes
  eventChanged: function(data) {
    $("#meter").meter("addEvent", data);
  },

  // Callback from the server when map markers change
  mapChanged: function(data) {
    Map.addMarkers(data);
  }

}});

  // Load the custom jQuery user interface components
  $("#nav").navigation();
  $("#ticker").ticker();
  $("#meter").meter();
  $("#logger").logger();

  // Load the map component with an empty map
  Map.load("#map");

  // Configure the network processors
  $.comm.service = ($.mgr.test ? "test" : "live");
  $.comm.params = ($.mgr.test ? { test: $.mgr.test } : { });
  $.comm.bind("game", $.mgr.gameChanged);
  $.comm.bind("player", $.mgr.playerChanged);
  $.comm.bind("event", $.mgr.eventChanged);
  $.comm.bind("map", $.mgr.mapChanged);
  $.comm.bind("log", $.logger.listen);

  // Start fetching data from the server
  setTimeout(function() { $.comm.update(); }, 2000);
});
// Handles all the controller logic for the live front page in test mode
$(function() {

// Register the page manager as a jQuery extension
$.extend({ mgr: {

  // Produces synthetic packets to simulate an interesting demo
  packetProducer: function(options) {
    var ts = options.data.ts;
    var packets = [ { type: "ts", data: ts + 1 } ];

    if (ts == 0 || ts % 60 == 0) {
      packets.push({ type: "game", data: { map: "carentan", type: "tdm", time: 30 } });
    } else if (ts % 30 == 0) {
      packets.push({ type: "game", data: { map: "peaks", type: "tdm", time: 30 } });
    } else {
      packets.push({ type: "map", data: $.mgr.randMarkers(1) });
    }

    if (ts == 0 || ts % 30 == 0) {
      packets.push({ type: "event", data: { value: 0 } });
    } else {
      var data = { value: (ts % 30) };
      if (Math.floor(Math.random() * 100) > 80) {
        data.type = "abrg".charAt(Math.floor(Math.random() * 4));
      }
      packets.push({ type: "event", data: data });
    }
    return packets;
  },

  // Generates random markers for the map
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
    $("#meter").meter("reset", data.time);
    Map.clearMarkers();
    Map.setTiles(data.map);
  },

  // Callback from the server when an event changes
  eventChanged: function(data) {
    $("#meter").meter("addEvent", data);
  },

  // Server callback when map markers change
  mapChanged: function(data) {
    Map.addMarkers(data);
  }
}});

  // Load the custom jQuery user interface components
  $("#nav").navigation();
  $("#ticker").ticker();
  $("#meter").meter();

  // Load the map component with an empty map
  Map.load("#map");

  // Configure the network processors
  $.comm.producer = $.mgr.packetProducer;
  $.comm.bind("game", $.mgr.gameChanged);
  $.comm.bind("event", $.mgr.eventChanged);
  $.comm.bind("map", $.mgr.mapChanged);

  // Start generating synthetic packets
  setTimeout(function() { $.comm.update(); }, 2000);
});
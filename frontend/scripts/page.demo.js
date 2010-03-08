// Handles all the controller logic for the live front page in test mode
$(function() {

// Register the page manager as a jQuery extension
$.extend({ mgr: {

  teams: "abrg",
  
  players: [
    { id: 1, name: "A Figment of Your Imagination", photo: "player0.jpg", place: "4", rank: "3", team: "a", trend: "+", kills: "79", deaths: "57", inflicted: "14,722", received: "8,353" },
    { id: 2, name: "Bazooka John", photo: "player1.jpg", place: "7", rank: "2", team: "g", trend: "-", kills: "48", deaths: "57", inflicted: "8,834", received: "7,149" },
    { id: 3, name: "CDJ Wobbly Wiggly", photo: "player2.jpg", place: "10", rank: "1", team: "b", trend: "-", kills: "32", deaths: "43", inflicted: "5,475", received: "9,252" },
    { id: 4, name: "CHUCKNORRISCOUNTEDTOINFINITY...", photo: "player3.jpg", place: "11", rank: "1", team: "r", trend: "-", kills: "27", deaths: "55", inflicted: "4,085", received: "6,768" },
    { id: 5, name: "Colonel Billiam", photo: "player4.jpg", place: "9", rank: "2", team: "a", trend: "-", kills: "44", deaths: "55", inflicted: "5,294", received: "6,245" },
    { id: 6, name: "GOMER PYLE", photo: "player5.jpg", place: "2", rank: "4", team: "g", trend: "+", kills: "108", deaths: "55", inflicted: "18,475", received: "7,809" },
    { id: 7, name: "Jaymz", photo: "player6.jpg", place: "6", rank: "3", team: "b", trend: "", kills: "58", deaths: "53", inflicted: "3,119", received: "2,090" },
    { id: 8, name: "Luda", photo: "player7.jpg", place: "8", rank: "2", team: "r", trend: "", kills: "45", deaths: "50", inflicted: "10,572", received: "10,978" },
    { id: 9, name: "Note To Self", photo: "player8.jpg", place: "5", rank: "3", team: "a", trend: "+", kills: "68", deaths: "53", inflicted: "11,222", received: "8,376" },
    { id: 10, name: "Scope", photo: "player9.jpg", place: "3", rank: "3", team: "g", trend: "+", kills: "82", deaths: "57", inflicted: "9,161", received: "9,162" },
    { id: 11, name: "ThePine", photo: "player10.jpg", place: "1", rank: "4", team: "b", trend: "+", kills: "143", deaths: "80", inflicted: "18,590", received: "11,193" },
    { id: 12, name: "Tim - Target Drone", photo: "player11.jpg", place: "12", rank: "0", team: "r", trend: "-", kills: "18", deaths: "50", inflicted: "2,879", received: "9,257" },
    { id: 13, name: "Turn Left Nower", photo: "player12.jpg", place: "13", rank: "0", team: "a", trend: "-", kills: "12", deaths: "31", inflicted: "2,741", received: "5,515" }
  ],

  // Produces synthetic packets to simulate an interesting demo
  packetProducer: function(options) {
    var ts = options.data.ts;
    var packets = [ { type: "ts", data: ts + 1 } ];

    if (ts == 0) {
      packets.push({ type: "player", data: $.mgr.players });
    }

    if (ts == 0 || ts % 60 == 0) {
      packets.push({ type: "game", data: { map: "mp_uo_carentan", type: "tdm", time: 30 } });
    } else if (ts % 30 == 0) {
      packets.push({ type: "game", data: { map: "mp_peaks", type: "tdm", time: 30 } });
    } else {
      packets.push({ type: "map", data: $.mgr.randMarkers(1) });
    }

    if (ts == 0 || ts % 30 == 0) {
      packets.push({ type: "event", data: { time: 0 } });
    } else {
      var data = { time: (ts % 30) };
      if (Math.floor(Math.random() * 100) > 80) {
        data.team = $.mgr.teams.charAt(Math.floor(Math.random() * 4));
      }
      packets.push({ type: "event", data: data });
    }
    return packets;
  },

  // Generates random markers for the map
  randMarkers: function(count) {
    var markers = [];
    for (var i = 0; i < count; i++) {
      var kx = ((parseInt(Math.random() * 3700))) + 200;
      var ky = ((parseInt(Math.random() * 2700))) + 700;
      var kplayer = $.mgr.players[Math.floor(Math.random() * $.mgr.players.length)];

      var dx = ((parseInt(Math.random() * 3700))) + 200;
      var dy = ((parseInt(Math.random() * 2700))) + 700;
      var dplayer = $.mgr.players[Math.floor(Math.random() * $.mgr.players.length)];

      markers.push({ kx: kx, ky: ky, kname: kplayer.name, kteam: kplayer.team,
        dx: dx, dy: dy, dname: dplayer.name, dteam: dplayer.team });
    }
    return markers;
  },

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
    $("#message").message("addMessages", data);
    Map.addMarkers(data);
  }
}});

  // Load the custom jQuery user interface components
  $("#nav").navigation();
  $("#ticker").ticker();
  $("#meter").meter();
  $("#message").message();

  // Load the map component with an empty map
  Map.load("#map");

  // Configure the network processors
  $.comm.producer = $.mgr.packetProducer;
  $.comm.bind("game", $.mgr.gameChanged);
  $.comm.bind("player", $.mgr.playerChanged);
  $.comm.bind("event", $.mgr.eventChanged);
  $.comm.bind("map", $.mgr.mapChanged);

  // Start generating synthetic packets
  setTimeout(function() { $.comm.update(); }, 2000);
});
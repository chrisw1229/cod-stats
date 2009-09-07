if (typeof Map == "undefined" || !Map) {
  var Map = {};

  Map.defaults = {
    cluster: 0,
    maxMarkers: 100,
    maxSize: 4096,
    maxTile: 256,
    maxZoom: 5,
    zoom: 0
  };
}

// Loads the map into the given element with the given options
Map.load = function(element, options) {

  // Copy default values for any missing options
  Map._init(element, $.extend({}, Map.defaults, options));
};

// Initializes the actual map component
Map._init = function(element, options) {
  Map.options = options;

  // Setup the map container
  Map.owner = $(element);
  Map.owner.addClass("ui-widget-content");
  $('<div class="ui-widget-overlay"/>').appendTo(Map.owner);

  // Create the map controls
  var navCtrl = new OpenLayers.Control.Navigation();
  var panCtrl = new OpenLayers.Control.CustomPanPanel();
  var zoomCtrl = new OpenLayers.Control.ZoomPanel();
  var keyCtrl = new OpenLayers.Control.KeyboardDefaults();

  // Create the actual map component
  var mapOpts = {
    controls: [navCtrl, panCtrl, zoomCtrl, keyCtrl],
    maxExtent: new OpenLayers.Bounds(0, 0, options.maxSize, options.maxSize),
    maxResolution: (options.maxSize / options.maxTile),
    numZoomLevels: options.maxZoom,
    theme: null
  };
  Map.ol = new OpenLayers.Map(Map.owner.attr("id"), mapOpts);
  $(window).bind("resize", Map._resize);

  // Create the map layers
  Map._initTileLayer();
  Map._initTargetLayer();
  Map._initMarkerLayer("death");
  Map._initMarkerLayer("kill");

  // Set control tool tips
  $(".olControlPanNorthItemInactive").attr("title", "Pan up");
  $(".olControlPanSouthItemInactive").attr("title", "Pan down");
  $(".olControlPanEastItemInactive").attr("title", "Pan right");
  $(".olControlPanWestItemInactive").attr("title", "Pan left");
  $(".olControlZoomInItemInactive").attr("title", "Zoom in");
  $(".olControlZoomToMaxExtentItemInactive").attr("title", "Zoom to show all");
  $(".olControlZoomOutItemInactive").attr("title", "Zoom out");

  // Set the initial map appearance
  var lon = (options.x ? options.x : (options.maxSize / 2));
  var lat = (options.y ? options.y : (options.maxSize / 2));
  Map.ol.setCenter(new OpenLayers.LonLat(lon, lat), 1);
  Map._resize();

  // Add random markers to the map
  Map.markerCnt = 0;
  setTimeout(function() {
    Map.addMarkers(Map._randMarkers(100));
  }, 1000);
  setInterval(function() {
    Map.addMarkers(Map._randMarkers(5));
  }, 2000);
};

// Adds the given marker to the map
Map.addMarkers = function(markers) {

  // Remove the oldest markers if the given array exceeds the max
  if (markers.length > Map.options.maxMarkers) {
    markers.splice(0, markers.length - Map.options.maxMarkers);
  }

  // Remove the oldest markers if the new total exceeds the max
  if (Map.markerCnt + markers.length > Map.options.maxMarkers) {
    var offset = (Map.markerCnt + markers.length) - Map.options.maxMarkers;
    for (var i = 1; i < Map.ol.layers.length; i++) {
      var layer = Map.ol.layers[i];
      layer.removeFeatures(layer.features.slice(0, offset));
    }
    Map.markerCnt -= offset;
  }

  // Build arrays of all the marker objects to add them in batches
  var targets = [], deaths = [], kills = [];
  for (var i = 0; i < markers.length; i++) {
    var marker = markers[i];
    var kp = new OpenLayers.Geometry.Point(marker.kx, marker.ky);
    var dp = new OpenLayers.Geometry.Point(marker.dx, marker.dy);

    targets.push(new OpenLayers.Feature.Vector(
      new OpenLayers.Geometry.LineString([kp, dp])
    ));
    deaths.push(new OpenLayers.Feature.Vector(dp));
    kills.push(new OpenLayers.Feature.Vector(kp));
  }

  // Add all the markers to the appropriate layers
  Map.ol.layers[1].addFeatures(targets);
  Map.ol.layers[2].addFeatures(deaths);
  Map.ol.layers[3].addFeatures(kills);
  Map.markerCnt += markers.length;
};

// Creates the base layer that displays map tiles
Map._initTileLayer = function() {

  // Configure the layer and add it to the map
  var layerOpts = {
    getURL: Map._tileURL,
    layername: "base",
    transitionEffect: "resize",
    type: "jpg"
  };
  Map.ol.addLayer(new OpenLayers.Layer.TMS("Tiles",
      "tiles/" + Map.options.map + "/", layerOpts));
};

// Creates a layer that displays association lines
Map._initTargetLayer = function() {

  // Configure the style for the layer
  var styleOpts = new OpenLayers.Style({
    strokeColor: "#ffb709", strokeWidth: 1
  });

  // Configure the layer and add it to the map
  var layerOpts = {
    styleMap: new OpenLayers.StyleMap({ "default": styleOpts }),
    rendererOptions: { yOrdering: true }
  }
  Map.ol.addLayer(new OpenLayers.Layer.Vector("Targets", layerOpts));
};

// Creates a layer that displays marker graphics
Map._initMarkerLayer = function(type) {

  // Configure the style for the layer
  var styleOpts = new OpenLayers.Style({
    externalGraphic: "styles/images/markers/" + type + "${size}.png",
    graphicWidth: "${size}", graphicHeight: "${size}"
  }, {
    context: {
      size: function(m) {
        return (m.cluster ? Math.min(m.attributes.count, 13) : 1) + 7;
      }
    }
  });

  // Configure the layer and add it to the map
  var layerOpts = {
    styleMap: new OpenLayers.StyleMap({ "default": styleOpts }),
    strategies: Map.options.cluster ? [new OpenLayers.Strategy.Cluster()] : null,
    rendererOptions: { yOrdering: true }
  }
  Map.ol.addLayer(new OpenLayers.Layer.Vector(type, layerOpts));
};

// Builds the URL to a single tile for the given map bounds
Map._tileURL = function(bounds) {
  var res = this.map.getResolution();
  var x = Math.round((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
  var y = Math.round((this.maxExtent.top - bounds.top) / (res * this.tileSize.h));
  var z = this.map.getZoom();

  var path = "tile_" + z + "_" + y + "_" + x + "." + this.type;
  var url = (url instanceof Array ? this.selectUrl(path, url) : this.url);
  return (url + path);
};

// Resizes the map when the browser window is resized
Map._resize = function(e) {

  // Adjust the map height to fit the window
  var height = $(window).height() - Map.owner.offset().top;
  Map.owner.css("height", height);

  // Update the dimensions of the map
  Map.ol.updateSize();
};

// Temporary function to generate random markers
Map._randMarkers = function(count) {
  var markers = [];
  for (var i = 0; i < count; i++) {
    var dx = ((parseInt(Math.random() * 3700))) + 200;
    var dy = ((parseInt(Math.random() * 2700))) + 700;
    var kx = ((parseInt(Math.random() * 3700))) + 200;
    var ky = ((parseInt(Math.random() * 2700))) + 700;
    markers.push({ dx: dx, dy: dy, kx: kx, ky: ky });
  }
  return markers;
};

// Custom pan panel used to set the slide factor
OpenLayers.Control.CustomPanPanel = OpenLayers.Class(OpenLayers.Control.Panel, {

  initialize: function(options) {
    OpenLayers.Control.Panel.prototype.initialize.apply(this, [options]);

    var ctrls = [
      new OpenLayers.Control.Pan(OpenLayers.Control.Pan.NORTH),
      new OpenLayers.Control.Pan(OpenLayers.Control.Pan.SOUTH),
      new OpenLayers.Control.Pan(OpenLayers.Control.Pan.EAST),
      new OpenLayers.Control.Pan(OpenLayers.Control.Pan.WEST)
    ];
    for (var i in ctrls) {
      ctrls[i].slideFactor = 125;
    }
    this.addControls(ctrls);
  },

  CLASS_NAME: "OpenLayers.Control.CustomPanPanel"
});
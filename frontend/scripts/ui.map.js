if (typeof Map == "undefined" || !Map) {
  var Map = {};

  Map.defaults = {
    cluster: 0,
    maxMarkers: 25,
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
  Map.markerCnt = 0;

  // Setup the map container
  Map.owner = $(element);
  Map.owner.addClass("ui-widget-content");
  $('<div class="ui-widget-overlay"/>').appendTo(Map.owner);

  // Create the map controls
  var navCtrl = new OpenLayers.Control.Navigation();
  var panCtrl = new OpenLayers.Control.CustomPanPanel();
  var zoomCtrl = new OpenLayers.Control.ZoomPanel();
  var keyCtrl = new OpenLayers.Control.KeyboardDefaults();
  Map.controls = [navCtrl, panCtrl, zoomCtrl, keyCtrl];

  // Create the actual map component
  var mapOpts = {
    controls: Map.controls,
    maxExtent: new OpenLayers.Bounds(0, 0, options.maxSize, options.maxSize),
    maxResolution: (options.maxSize / options.maxTile),
    numZoomLevels: options.maxZoom,
    theme: null
  };
  Map.ol = new OpenLayers.Map(Map.owner.attr("id"), mapOpts);

  // Create the map layers
  Map.tileLayer = Map._initTileLayer();
  Map.targetLayer = Map._initTargetLayer();
  Map.deathLayer = Map._initMarkerLayer("death");
  Map.killLayer = Map._initMarkerLayer("kill");

  // Set control tool tips
  $(".olControlPanNorthItemInactive").attr("title", "Pan up");
  $(".olControlPanSouthItemInactive").attr("title", "Pan down");
  $(".olControlPanEastItemInactive").attr("title", "Pan right");
  $(".olControlPanWestItemInactive").attr("title", "Pan left");
  $(".olControlZoomInItemInactive").attr("title", "Zoom in");
  $(".olControlZoomToMaxExtentItemInactive").attr("title", "Zoom to show all");
  $(".olControlZoomOutItemInactive").attr("title", "Zoom out");

  // Bind the event handlers
  $(window).bind("resize", Map._resize);

  // Set the initial map appearance
  var lon = (options.x ? options.x : (options.maxSize / 2));
  var lat = (options.y ? options.y : (options.maxSize / 2));
  Map.ol.setCenter(new OpenLayers.LonLat(lon, lat), 1);
  Map._resize();
  Map._enabled(false);
};

// Sets the tile layer displayed by the map
Map.setTiles = function(tiles) {

  // Check if the tile set is actually different
  if (Map.options.tiles != tiles) {

    // Check if there is an old tile layer to remove
    if (Map.tileLayer) {
      Map.ol.removeLayer(Map.tileLayer);
    }

    // Initialize a layer for the new tile set
    Map.options.tiles = tiles;
    Map.tileLayer = Map._initTileLayer();
  }

  // Enable the map controls if tiles are configured
  Map._enabled(Map.options.tiles);
};

// Adds the given marker to the map
Map.addMarkers = function(markers) {
  markers = ($.isArray(markers) ? markers : [ markers ]);

  // Remove the oldest markers if the given array exceeds the max
  if (markers.length > Map.options.maxMarkers) {
    markers.splice(0, markers.length - Map.options.maxMarkers);
  }

  // Remove the oldest markers if the new total exceeds the max
  if (Map.markerCnt + markers.length > Map.options.maxMarkers) {
    var offset = (Map.markerCnt + markers.length) - Map.options.maxMarkers;
    for (var i = 0; i < Map.ol.layers.length; i++) {
      var layer = Map.ol.layers[i];
      if (layer.features && layer.features.length > 0) {
        layer.removeFeatures(layer.features.slice(0, offset));
      }
    }
    Map.markerCnt -= offset;
  }

  // Build arrays of all the marker objects to add them in batches
  var targets = [], deaths = [], kills = [];
  for (var i = 0; i < markers.length; i++) {
    var marker = markers[i];

    // Invert the y-coordinates since we are plotting raw pixels
    var kp = new OpenLayers.Geometry.Point(marker.kx,
        Map.options.maxSize - marker.ky);
    var dp = new OpenLayers.Geometry.Point(marker.dx,
        Map.options.maxSize - marker.dy);

    targets.push(new OpenLayers.Feature.Vector(
      new OpenLayers.Geometry.LineString([kp, dp])
    ));
    deaths.push(new OpenLayers.Feature.Vector(dp));
    kills.push(new OpenLayers.Feature.Vector(kp));
  }

  // Add all the markers to the appropriate layers
  Map.targetLayer.addFeatures(targets);
  Map.deathLayer.addFeatures(deaths);
  Map.killLayer.addFeatures(kills);
  Map.markerCnt += markers.length;
};

// Removes all the map markers
Map.clearMarkers = function() {
  for (var i = 0; i < Map.ol.layers.length; i++) {
    var layer = Map.ol.layers[i];
    if (layer.features && layer.features.length > 0) {
      layer.removeFeatures(layer.features);
    }
  }
  Map.markerCnt = 0;
};

// Creates the base layer that displays map tiles
Map._initTileLayer = function() {

  // Configure the tile layer
  var layerOpts = {
    getURL: Map._tileURL,
    layername: "base",
    transitionEffect: "resize",
    type: "jpg"
  };

  // Add the tile layer to the map
  var layer = new OpenLayers.Layer.TMS("Tiles",
      "tiles/" + Map.options.tiles + "/", layerOpts);
  Map.ol.addLayer(layer);
  return layer;
};

// Creates a layer that displays association lines
Map._initTargetLayer = function() {

  // Configure the style for the layer
  var styleOpts = new OpenLayers.Style({
    strokeColor: "#ffb709", strokeWidth: 1
  });

  // Configure the target layer
  var layerOpts = {
    styleMap: new OpenLayers.StyleMap({ "default": styleOpts }),
    rendererOptions: { yOrdering: true }
  }

  // Add the target layer to the map
  var layer = new OpenLayers.Layer.Vector("Targets", layerOpts);
  Map.ol.addLayer(layer);
  return layer;
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

  // Configure the marker layer
  var layerOpts = {
    styleMap: new OpenLayers.StyleMap({ "default": styleOpts }),
    strategies: Map.options.cluster ? [new OpenLayers.Strategy.Cluster()] : null,
    rendererOptions: { yOrdering: true }
  }

  // Add the marker layer to the map
  var layer = new OpenLayers.Layer.Vector(type, layerOpts);
  Map.ol.addLayer(layer);
  return layer;
};

// Builds the URL to a single tile for the given map bounds
Map._tileURL = function(bounds) {

  // Check whether a valid tile set was provided
  if (Map.options.tiles == undefined) {
    return null;
  }

  // Calculate the tile attributes for the given bounds
  var res = this.map.getResolution();
  var x = Math.round((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
  var y = Math.round((this.maxExtent.top - bounds.top) / (res * this.tileSize.h));
  var z = this.map.getZoom();

  // Build a url to the appropriate tile
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

// Enables or disables the map controls
Map._enabled = function(enabled) {

  // Check if the state actually changed
  if (Map.enabled != enabled) {
    Map.enabled = enabled;

    // Add or remove the map controls based on the given state
    for (var i = 0; i < Map.controls.length; i++) {
      if (enabled) {
        Map.controls[i].activate();
      } else {
        Map.controls[i].deactivate();
      }
    }

    // Enable the map navigation cursor
    if (enabled) {
      $(".olMap").addClass("enabled");
    } else {
      $(".olMap").removeClass("enabled");
    }
  }
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
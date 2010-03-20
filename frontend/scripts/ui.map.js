if (typeof Map == "undefined" || !Map) {
  var Map = {};

  Map.defaults = {
    cluster: 0,
    maxMarkers: 25,
    maxSize: 4096,
    maxTile: 256,
    maxZoom: 5,
    zoom: 2
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
  Map.navCtrl = new OpenLayers.Control.Navigation();
  Map.panCtrl = new OpenLayers.Control.CustomPanPanel();
  Map.zoomCtrl = new OpenLayers.Control.ZoomPanel();
  Map.keyCtrl = new OpenLayers.Control.KeyboardDefaults();

  // Create the actual map component
  var mapOpts = {
    controls: [Map.navCtrl, Map.panCtrl, Map.zoomCtrl, Map.keyCtrl],
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
  Map.layers = [Map.targetLayer, Map.deathLayer, Map.killLayer];

  // Add the hover control after the feature layers are created
  Map.hoverCtrl = new OpenLayers.Control.Hover();
  Map.ol.addControl(Map.hoverCtrl);

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
  Map._resize();

  // Disable user input until tiles are loaded
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
  Map._enabled(Map.options.tiles != undefined);
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
  // Invert the y-coordinates since we are plotting raw pixels
  var targets = [], deaths = [], kills = [];
  for (var i = 0; i < markers.length; i++) {
    var marker = markers[i];

    // Set the fade out stamp for the marker
    marker.fadeCount = Map.fadeCount;

    // Create a vector point for the kill marker
    var kx = (marker.kx ? marker.kx : marker.sx);
    var ky = (marker.ky ? marker.ky : marker.sy);
    var kp = new OpenLayers.Geometry.Point(kx, Map.options.maxSize - ky);
    kills.push(new OpenLayers.Feature.Vector(kp, marker));

    // Create a vector point for the death marker
    var dx = (marker.dx ? marker.dx : marker.sx);
    var dy = (marker.dy ? marker.dy : marker.sy);
    var dp = new OpenLayers.Geometry.Point(dx, Map.options.maxSize - dy);
    deaths.push(new OpenLayers.Feature.Vector(dp, marker));

    // Create a vector line from the kill to the death marker
    var tl = new OpenLayers.Geometry.LineString([kp, dp]);
    targets.push(new OpenLayers.Feature.Vector(tl, marker));
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
  var styleOpts = new OpenLayers.Style({ strokeColor: "${color}",
    strokeWidth: "${width}", strokeOpacity: "${opacity}"
  }, {
    context: {
      color: function(m) {
        var team = m.attributes.kteam;
        if (team == "g") {
          return "#FFB709";
        } else if (team == "a" || team == "r" || team == "b") {
          return "#64C461";
        }
        return "#ABABAB";
      },

      width: function(m) {
        return Map.ol.getZoom() + 1;
      },

      opacity: function(m) {
        var diff = Map.fadeCount - m.attributes.fadeCount;
        return (diff < 3 ? 1 - (diff * 0.2) : 0.4);
      }
    }
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
  var styleOpts = new OpenLayers.Style({ cursor: "pointer",
    externalGraphic: "styles/images/markers/${type}${size}.png",
    graphicWidth: "${size}", graphicHeight: "${size}", graphicOpacity: "${opacity}"
  }, {
    context: {
      type: function(m) {
        if (m.attributes.steam || (type == "kill"
              && m.attributes.kteam == m.attributes.dteam)) {
          return "suicide";
        }
        return type;
      },

      size: function(m) {

        // Use the marker count to select an image size when clustering
        if (m.cluster) {
          return Math.min(m.attributes.count, 13) + 7;
        }

        // Use the current zoom level to select an image size otherwise
        var zoom = Map.ol.getZoom();
        return (3 * zoom + 8);
      },

      opacity: function(m) {
        var diff = Map.fadeCount - m.attributes.fadeCount;
        return (diff < 3 ? 1 - (diff * 0.2) : 0.4);
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
    return "";
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

  // Update the dimensions of the hover dialog
  Map.hoverCtrl.resize();
};

// Enables or disables the map controls
Map._enabled = function(enabled) {

  // Check if the state actually changed
  if (Map.enabled != enabled) {
    Map.enabled = enabled;

    // Only allow mouse interaction when tiles are loaded
    if (enabled) {
      Map.navCtrl.activate();
      Map.hoverCtrl.activate();
    } else {
      Map.navCtrl.deactivate();
      Map.hoverCtrl.deactivate();
    }

    // Adjust the map appearance
    if (enabled) {
      $(".olMap").addClass("enabled");

      // Set the default pan and zoom values
      var lon = (Map.options.x ? Map.options.x : (Map.options.maxSize / 2));
      var lat = (Map.options.y ? Map.options.y : (Map.options.maxSize / 2));
      Map.ol.setCenter(new OpenLayers.LonLat(lon, lat), Map.options.zoom);
    } else {
      $(".olMap").removeClass("enabled");
    }

    // Enable/disable the timer used to fade out old markers
    if (enabled && Map.running == undefined) {
      Map.fadeCount = 0;
      Map.running = setInterval(function() {
        Map.fadeCount++;
        Map.targetLayer.redraw();
        Map.killLayer.redraw();
        Map.deathLayer.redraw();
      }, 10000);
    } else if (!enabled && Map.running) {
      clearInterval(Map.running);
      Map.fadeCount = 0;
      Map.running = undefined;
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

OpenLayers.Control.Hover = OpenLayers.Class(OpenLayers.Control, {                

  initialize: function(options) {
    OpenLayers.Control.prototype.initialize.apply(this, arguments); 

    this.layer = new OpenLayers.Layer.Vector.RootContainer(
      this.id + "_container", { layers: Map.layers }
    );

    this.callbacks = { over: this.overFeature, out: this.outFeature };
    this.handlers = {
      feature: new OpenLayers.Handler.Feature(this, this.layer, this.callbacks)
    };

    // Create a dialog element for displaying hover information
    this.dialog = $('<div class="ui-widget ui-widget-content ui-corner-all map-dialog"/>').appendTo($(Map.owner));
    $('<div class="map-dialog-name1"/>').appendTo(this.dialog);
    $('<div class="map-dialog-weapon"/>').appendTo(this.dialog);
    $('<div class="map-dialog-name2"/>').appendTo(this.dialog);
    this.dialog.css("opacity", 0.8);
    this.dialog.hide();
  },

  destroy: function() {
    OpenLayers.Control.prototype.destroy.apply(this, arguments);

    this.dialog.remove();
    this.layer.destroy();
  },

  activate: function () {
    if (!this.active) {
      this.map.addLayer(this.layer);
      this.handlers.feature.activate();
    }
    return OpenLayers.Control.prototype.activate.apply(this, arguments);
  },

  deactivate: function () {
    if (this.active) {
      this.handlers.feature.deactivate();
      this.map.removeLayer(this.layer);
    }
    return OpenLayers.Control.prototype.deactivate.apply(this, arguments);
  },

  overFeature: function(feature) {
    this.selected = feature.attributes;

    var marker = feature.attributes;
    var name1Div = $(".map-dialog-name1", this.dialog);
    var weaponDiv = $(".map-dialog-weapon", this.dialog);
    var name2Div = $(".map-dialog-name2", this.dialog);

    name1Div.text(marker.kname);
    weaponDiv.text(marker.weapon);
    name2Div.text(marker.sname ? marker.sname : marker.dname);

    if (marker.steam) {
      name1Div.hide();
      name2Div.addClass("map-dialog-suicide");
    } else {
      if (marker.kteam == marker.dteam) {
        name1Div.addClass("map-dialog-suicide");
      } else {
        name1Div.removeClass("map-dialog-suicde");
      }
      name1Div.show();
      name2Div.removeClass("map-dialog-suicide");
    }
  
    var team = (marker.steam ? marker.steam : marker.kteam);
    weaponDiv.attr("class", "map-dialog-weapon map-dialog-weapon-" + team);

    var maxW = $(Map.owner).width();
    var maxH = $(Map.owner).height();
    this.dialog.css({ left: (maxW - this.dialog.width()) / 2,
        top: maxH - this.dialog.outerHeight(true) });
    this.dialog.show();
  },

  outFeature: function(feature) {
    this.selected = undefined;
    this.dialog.hide();
  },

  setMap: function(map) {
    this.handlers.feature.setMap(map);

    OpenLayers.Control.prototype.setMap.apply(this, arguments);
  },

  resize: function() {
    this.dialog.hide();
  },

  CLASS_NAME: "OpenLayers.Control.Hover"
});
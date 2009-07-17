if (typeof Map == "undefined" || !Map) {
  var Map = {};

  Map.defaults = {
    maxSize: 4096,
    maxTile: 256,
    maxZoom: 5,
    zoom: 0
  };
}

Map.load = function(element, options) {
  Map._init(element, $.extend({}, Map.defaults, options));
};

Map._init = function(element, options) {
  Map.options = options;

  // Setup the map container
  Map.owner = $(element);
  Map.owner.addClass("ui-widget-content ui-map");
  $('<div class="ui-widget-overlay"></div>').appendTo(Map.owner);

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
  Map.map = new OpenLayers.Map(Map.owner.attr("id"), mapOpts);
  $(window).bind("resize", Map._resize);

  // Create the map tile layer
  var layerOpts = {
    getURL: Map._tileURL,
    layername: "base",
    transitionEffect: "resize",
    type: "jpg"
  };
  Map.layer = new OpenLayers.Layer.TMS("Game",
      "tiles/" + options.map + "/", layerOpts);
  Map.map.addLayer(Map.layer);

  // Set control tool tips
  $(".olControlPanNorthItemInactive").attr("title", "Pan up");
  $(".olControlPanSouthItemInactive").attr("title", "Pan down");
  $(".olControlPanEastItemInactive").attr("title", "Pan right");
  $(".olControlPanWestItemInactive").attr("title", "Pan left");
  $(".olControlZoomInItemInactive").attr("title", "Zoom in");
  $(".olControlZoomToMaxExtentItemInactive").attr("title", "Zoom to show all");
  $(".olControlZoomOutItemInactive").attr("title", "Zoom out");

  // Set the initial map appearance
  var lat = (options.x ? options.x : (options.maxSize / 2));
  var lon = (options.y ? options.y : (options.maxSize / 2));
  Map.center = new OpenLayers.LonLat(lon, lat);
  Map._resize();
};

Map._tileURL = function(bounds) {
  var res = this.map.getResolution();
  var x = Math.round((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
  var y = Math.round((this.maxExtent.top - bounds.top) / (res * this.tileSize.h));
  var z = this.map.getZoom();

  var path = "tile_" + z + "_" + y + "_" + x + "." + this.type;
  var url = this.url;
  if (url instanceof Array) {
    url = this.selectUrl(path, url);
  }
  return (url + path);
};

Map._resize = function(e) {

  // Adjust the map height to fit the window
  var height = $(window).height() - Map.owner.offset().top;
  Map.owner.css("height", height);

  // Update the dimensions of the map
  Map.map.updateSize();
};

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
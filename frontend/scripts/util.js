// Extends the jQuery object with additional utility functions
(function($) {

// Register the logger object as a jQuery extension
$.extend({ logger: {

  enabled: true,

  listener: undefined,

  listen: function(event) {
    $.logger.log(event);
  },

  info: function(msg, exc) {
    if (this.enabled) { this._fire({ type: "info", msg: msg, exc: exc }); }
  },

  error: function(msg, exc) {
    if (this.enabled) { this._fire({ type: "error", msg: msg, exc: exc }); }
  },

  debug: function(message, exc) {
    if (this.enabled) { this._fire({ type: "debug", msg: msg, exc: exc }); }
  },

  log: function(event) {
    if (this.enabled && event) {
      if (event.info) { this.info(event.info, event.exc); }
      if (event.error) { this.error(event.error, event.exc); }
      if (event.debug) { this.debug(event.debug, event.exc); }
    }
  },

  _fire: function(event) {
    if (this.enabled && this.listener != undefined) {
      this.listener(event);
    }
  }

}});

$.extend({

  // This function calls the given method within the given context
  call: function(context, method) {
    method = (typeof(method) == 'string' ? context[method] : method);
    return function () { method.apply(context, arguments); };
  },

  // This function gets parameter value from a url
  getParam: function(url, key) {
    var pos = url.indexOf("?");
    if (pos < 0) {
      return null;
    }

    var query = url.substring(pos + 1);
    var params = query.split("&");
    for (var i = 0; i < params.length; i++) {
      var param = params[i].split("=");
      if (param[0] == key) {
        return (param.length == 1 ? true : param[1]);
      }
    }
    return null;
  }
});

})(jQuery);
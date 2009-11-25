// Extends the jQuery object with additional utility functions
(function($) {

// Register the logger object as a jQuery extension
$.extend({ logger: {

  info: function(message, exception) {
    alert("INFO: " + message + (exception ? "\n" + exception : ""));
  },

  warn: function(message, exception) {
    alert("WARN: " + message + (exception ? "\n" + exception : ""));
  },

  error: function(message, exception) {
    alert("ERROR: " + message + (exception ? "\n" + exception : ""));
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
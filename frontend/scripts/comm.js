// Provides dynamic network communication with the server
(function($) {

// Register the communication object as a jQuery extension
$.extend({ comm: {

  SERVICE: "live", // The address of the dynamic update service
  processors: {}, // A map of registered data processors
  timestamp: 0, // Stores the last update time from the server
  errors: 0, // The number of consecutive communication errors

  // Registers a processor to a type of data
  bind: function(type, processor) {
    var list = this.processors[type];
    if (list == null) {
      list = [];
      this.processors[type] = list;
    }
    list.push(processor);
  },

  // Unregisters a processor from a type of data
  unbind: function(type, processor) {
    var list = this.processors[type];
    if (list != null) {
      for (var i = 0; i < list.length; i++) {
        if (list[i] == processor) {
          list.splice(i, 1);
          break;
        }
      }
      if (list.length == 0) {
        this.processors[type] = undefined;
      }
    }
  },

  // Makes an update request to the server to get new data
  update: function(type, all) {

    // Build a list of request parameters
    var params = {
      type: (type ? type : ""),
      ts: (all ? 0 : this.timestamp)
    };

    // Configure the request options
    var options = {
      url: this.SERVICE,
      data: params,
      dataType: "json",
      cache: false,
      success: $.call(this, "_handleSuccess"),
      error: $.call(this, "_handleError"),
      complete: $.call(this, "_handleComplete")
    };

    // Send the request to the server
    $.ajax(options);
  },

  // Handles updated data responses from the server
  _handleSuccess: function(data, status) {

    // Clear any previous errors
    this.errors = 0;

    // Process all the messages received from the server
    for (var i = 0; i < data.length; i++) {
      var msg = data[i];

      // Check if this is a time stamp message
      if (msg.type == "ts") {
        this.timestamp = msg.data;
      } else {

        // Pass the parsed message to all matching processors
        var list = this.processors[msg.type];
        if (list != null) {
          for (var processor in list) {
            processor(msg.data);
          }
        }
      }
    }
  },

  // Handles error responses from the server
  _handleError: function(request, status, error) {

    // TODO Show this somewhere
    this.errors++;
  },

  // Handles cleanup after an update completes
  _handleComplete: function(request, status) {

    // Calculate the delay until the next update
    // Retry quickly for initial errors then slow down for repeated errors
    var delay = (1 + (this.errors < 3 ? this.errors : 59)) * 1000;

    // Request the next set of updates from the server
    var self = this;
    setTimeout(function() { self.update(); }, delay);
  }

}});

})(jQuery);
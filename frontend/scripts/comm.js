// Provides dynamic network communication with the server
(function($) {

// Register the communication object as a jQuery extension
$.extend({ comm: {

  service: "live", // The address of the communication service
  params: {}, // Optional set of parameters to add to the request
  processors: {}, // A map of registered data processors
  timestamp: 0, // Stores the last update time from the server
  errors: 0, // The number of consecutive communication errors
  producer: undefined, // An optional function that produces synthetic packets

  // Registers a processor to a type of data
  bind: function(type, processor) {
    if (!$.isFunction(processor)) {
      alert("Processor must be a function: " + processor);
      return;
    }

    var list = (this.processors[type] ? this.processors[type] : []);
    list.push(processor);
    this.processors[type] = list;
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
    for (var param in this.params) {
      params[param] = this.params[param];
    }

    // Configure the request options
    var options = {
      url: this.service,
      data: params,
      dataType: "json",
      cache: false,
      success: $.call(this, "_handleSuccess"),
      error: $.call(this, "_handleError"),
      complete: $.call(this, "_handleComplete")
    };

    // Check whether a synthetic packet producer is registered
    if (this.producer) {

      // Get the next packet from a local function
      this._handleSuccess(this.producer(options));
      this._handleComplete();
    } else {

      // Send the request to the server
      $.ajax(options);
    }
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
          for (var j = 0; j < list.length; j++) {
            try {
              var processor = list[j];
              processor(msg.data);
            } catch(err) {
              $.logger.error("Error processing comm packet: " + msg.type, err);
            }
          }
        }
      }
    }
  },

  // Handles error responses from the server
  _handleError: function(request, status, error) {
    this.errors++;
    $.logger.error("Error connecting to server", error);
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
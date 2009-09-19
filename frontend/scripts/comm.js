
// Build the communication object immediately
(function($) {

// Declare the communication object definition
COMM = {

//  SERVER_URL: "http://cdjenkin-laptop/live",
  SERVER_URL: "http://192.168.1.101:8080/live",
//  SERVER_URL: "http://cward-nb/stats/live",

  processors: {},

  lastUpdate: 0,

  timestamp: 0,

  errors: 0,

  // Registers a processor to a type of data
  bind: function(type, processor) {
    this.processors[type] = processor;
  },

  // Unregisters a processor from a type of data
  unbind: function(type, processor) {
    this.processors[type] = undefined;
  },

  // Makes a request to the server for updated data
  request: function(type, all) {
    this.lastUpdate = new Date().getTime();

    // Build a list of request parameters
    var params = {};
    if (type) {
      params.type = type;
    }
    params.ts = (all ? 0 : this.timestamp);
    params.rnd = this.lastUpdate;

    // Send the request to the server
    var self = this;
    $.getJSON(this.SERVER_URL, params, function(data, status) {
      self.response(data, status);
    });
  },

  // Handles the response from the server for updated data
  response: function(msgs, status) {

    // Check if the remote server call was successful
    if (status == "success") {

      // Clear any previous errors
      this.errors = 0;

      // Process all the messages received from the server
      for (var i = 0; i < msgs.length; i++) {
        var msg = msgs[i];

        // Check if this is a time stamp message
        if (msg.type == "ts") {
          this.timestamp = msg.data;
        } else {

          // Pass the parsed message to a registered processor
          var processor = this.processors[msg.type];
          if (processor != null) {
            processor(msg.data);
          }
        }
      }
    } else {

      // TODO Show the error
      this.errors++;
    }

    // Calculate the delay until the next server request
    // Retry quickly for initial errors then slow down for repeated errors
    var delay = (1 + (this.errors < 3 ? this.errors : 59)) * 1000;

    // Request the next set of changes from the server
    var self = this;
    setTimeout(function() { self.request(); }, delay);
  }

};

// Register the communication object as an extension
$.extend({ comm: COMM });

})(jQuery);

$(document).ready(function() {

  
});
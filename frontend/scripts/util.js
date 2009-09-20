// Extends the jQuery object with additional utility functions
(function($) {
  
$.extend({

  // This function calls the given method within the given context
  call: function (context, method) {
    method = (typeof(method) == 'string' ? context[method] : method);
    return function () { method.apply(context, arguments); };
  }

});

})(jQuery);
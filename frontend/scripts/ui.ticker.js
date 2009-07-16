(function($) {

$.widget("ui.ticker", {

  _init: function() {
    var self = this;

    // Build the document model
    this.element.addClass("ui-widget-content ui-ticker");
    this.shadowDiv = $('<div class="ui-ticker-shadow"></div>').appendTo(this.element);
    this.itemsDiv = $('<div class="ui-ticker-items"></div>').appendTo(this.element);
    for (var i in this.options.items) {
      var item = this.options.items[i];
      var itemDiv = $('<div class="ui-ticker-item"></div>').appendTo(this.itemsDiv);
      $('<div class="ui-widget-shadow ui-ticker-item-shadow"></div>').appendTo(itemDiv);
      $('<div class="ui-widget-header ui-corner-top ui-state-default ui-ticker-item-name">'
          + item.name + '</div>').appendTo(itemDiv);
      var contDiv = $('<div class="ui-widget-content ui-corner-bottom ui-ticker-item-content"></div>').appendTo(itemDiv);
      var image = $('<div class="ui-widget-content ui-corner-bl ui-ticker-item-image"></div>').appendTo(contDiv);
      image.css("background-image", "url(players/" + item.image + ")");
      var statsDiv = $('<div class="ui-ticker-stats"></div>').appendTo(contDiv);
      $('<div class="ui-ticker-stats-head">KILLS: ' + item.k + '</div>').appendTo(statsDiv);
      $('<div class="ui-ticker-stats-base">DEATHS: ' + item.d + '</div>').appendTo(statsDiv);
      $('<div class="ui-ticker-stats-base">DAM: ' + item.dm + '</div>').appendTo(statsDiv);
      $('<div class="ui-ticker-stats-base">PERF: ' + item.p + '</div>').appendTo(statsDiv);
    }
  },

  destroy: function() {

    // Destroy the document model
    this.element.removeClass("ui-widget-content ui-ticker");
    this.shadowDiv.remove();
    this.itemsDiv.remove();

    $.widget.prototype.destroy.apply(this, arguments);
  }

});

$.extend($.ui.ticker, {
  version: "1.7.2",
  defaults: {
    items: [
      { name: "A Figment of Your Imagination", image: "player1.jpg", k: "789", d: "575", dm: "105,807", p: "0.313" },
      { name: "CHUCKNORRISCOUNTEDTOINFINITY...", image: "player2.jpg", k: "1,079", d: "554", dm: "39,178", p: "-1.301" },
      { name: "GOMER PYLE", image: "player3.jpg", k: "271", d: "546", dm: "134,936", p: "0.613" },
      { name: "ThePine", image: "player4.jpg", k: "1,428", d: "803", dm: "183,928", p: "0.385" }
    ]
  }
});

})(jQuery);
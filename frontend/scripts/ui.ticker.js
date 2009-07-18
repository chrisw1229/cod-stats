(function($) {

$.widget("ui.ticker", {

  _init: function() {
    var self = this;

    // Build the document model
    this.element.addClass("ui-widget-content ui-ticker");
    this.shadowDiv = $('<div class="ui-ticker-shadow"></div>').appendTo(this.element);
    this.itemsDiv = $('<div class="ui-ticker-items"></div>').appendTo(this.element);
    for (var i = 0; i < this.options.items.length; i++) {
      var item = this.options.items[i];
      var itemDiv = $('<div class="ui-ticker-item"></div>').appendTo(this.itemsDiv);
      $('<div class="ui-widget-shadow ui-ticker-item-shadow"></div>').appendTo(itemDiv);
      $('<div class="ui-widget-header ui-corner-top ui-state-default ui-ticker-item-name">'
          + item.name + '</div>').appendTo(itemDiv);
      var contDiv = $('<div class="ui-widget-content ui-corner-bottom ui-ticker-item-content"></div>').appendTo(itemDiv);
      var image = $('<div class="ui-widget-content ui-corner-bl ui-ticker-item-image"></div>').appendTo(contDiv);
      image.css("background-image", "url(players/" + item.image + ")");
      var statsDiv = $('<div class="ui-ticker-stats"></div>').appendTo(contDiv);
      $('<div class="cod-icon-rank cod-icon-rank' + (i + 1) + '"></div>').appendTo(statsDiv);
      $('<div class="ui-ticker-stats-head">KILLS: ' + item.k + '</div>').appendTo(statsDiv);
      $('<div class="ui-ticker-stats-base">DEATHS: ' + item.d + '</div>').appendTo(statsDiv);
      $('<div class="ui-ticker-stats-base">DAMAGE: ' + item.dm + '</div>').appendTo(statsDiv);
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
      { name: "A Figment of Your Imagination", image: "player1.jpg", k: "79", d: "57", dm: "10k", p: "31" },
      { name: "CHUCKNORRISCOUNTEDTOINFINITY...", image: "player2.jpg", k: "27", d: "55", dm: "3k", p: "13" },
      { name: "GOMER PYLE", image: "player3.jpg", k: "108", d: "55", dm: "13k", p: "61" },
      { name: "ThePine", image: "player4.jpg", k: "144", d: "80", dm: "18k", p: "38" }
    ]
  }
});

})(jQuery);
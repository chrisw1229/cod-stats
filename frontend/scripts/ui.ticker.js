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
      var shadowDiv = $('<div class="ui-widget-shadow ui-ticker-item-shadow"></div>').appendTo(itemDiv);
      var headerDiv = $('<div class="ui-state-default ui-corner-top ui-ticker-item-header">'
          + item.name + '</div>').appendTo(itemDiv);
      var contDiv = $('<div class="ui-widget-content ui-corner-bottom ui-ticker-item-content"></div>').appendTo(itemDiv);
      var photoDiv = $('<div class="ui-widget-content ui-corner-br ui-ticker-item-photo"></div>').appendTo(contDiv);
      photoDiv.css("background-image", "url(players/" + item.photo + ")");

      var iconsDiv = $('<div class="ui-ticker-item-icons"></div>').appendTo(contDiv);
      $('<div class="ui-widget-header ui-corner-bl ui-ticker-place">'
          + '<div class="ui-ticker-place-label">RANK</div>'
          + '<div class="ui-ticker-place-value">' + item.place + '</div>'
          + '</div>').appendTo(iconsDiv);
      $('<div class="icon-rank icon-rank-' + item.rank
          + ' ui-ticker-item-rank"</div>').appendTo(iconsDiv);
      $('<div class="icon-team icon-team-' + item.team
          + ' ui-ticker-item-team"</div>').appendTo(iconsDiv);

      var stats = $('<table class="ui-ticker-stats">'
          + '<tr class="ui-ticker-stat-line1">'
            + '<td class="ui-ticker-stat-value">' + item.kills + '</td>'
            + '<td>Kills</td>'
          + '</tr><tr class="ui-ticker-stat-line2">'
            + '<td class="ui-ticker-stat-value">' + item.deaths + '</td>'
            + '<td>Deaths</td>'
          + '</tr><tr class="ui-ticker-stat-line3">'
            + '<td class="ui-ticker-stat-value">' + item.inflicted + '</td>'
            + '<td>Inflicted</td>'
            + '<td/>'
          + '</tr><tr class="ui-ticker-stat-line3">'
            + '<td class="ui-ticker-stat-value">' + item.received + '</td>'
            + '<td>Received</td>'
            + '<td/>'
          + '</tr></table>').appendTo(contDiv);
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
      { name: "A Figment of Your Imagination", photo: "player1.jpg", place: "7", rank: "3", team: "a", kills: "79", deaths: "57", inflicted: "500", received: "200" },
      { name: "CHUCKNORRISCOUNTEDTOINFINITY...", photo: "player2.jpg", place: "23", rank: "1", team: "b", kills: "27", deaths: "55", inflicted: "65", received: "1,456" },
      { name: "GOMER PYLE", photo: "player3.jpg", place: "2", rank: "4", team: "r", kills: "108", deaths: "55", inflicted: "800", received: "80" },
      { name: "ThePine", photo: "player4.jpg", place: "1", rank: "5", team: "g", kills: "144", deaths: "80", inflicted: "2,123", received: "1,789" }
    ]
  }
});

})(jQuery);
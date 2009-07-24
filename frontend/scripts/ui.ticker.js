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
      var contDiv = $('<div class="ui-widget-content ui-ticker-item-content"></div>').appendTo(itemDiv);
      var photoDiv = $('<div class="ui-widget-content ui-ticker-item-photo"></div>').appendTo(contDiv);
      photoDiv.css("background-image", "url(players/" + item.photo + ")");

      var iconsDiv = $('<div class="ui-ticker-item-icons"></div>').appendTo(contDiv);
      $('<div class="ui-widget-header ui-corner-bl ui-ticker-place">'
          + '<div class="ui-ticker-place-label">RANK</div>'
          + '<div class="ui-ticker-place-value">' + item.p + '</div>'
          + '</div>').appendTo(iconsDiv);
      $('<div class="icon-rank icon-rank-' + item.r
          + ' ui-ticker-item-rank"</div>').appendTo(iconsDiv);
      $('<div class="icon-team icon-team-' + item.t
          + ' ui-ticker-item-team"</div>').appendTo(iconsDiv);

      var stats = $('<table class="ui-ticker-stats">'
          + '<tr class="ui-ticker-stat-line1">'
            + '<td class="ui-ticker-stat-value">' + item.k + '</td>'
            + '<td>Kills</td>'
          + '</tr><tr class="ui-ticker-stat-line2">'
            + '<td class="ui-ticker-stat-value">' + item.d + '</td>'
            + '<td>Deaths</td>'
          + '</tr><tr class="ui-ticker-stat-line2">'
            + '<td class="ui-ticker-stat-value">' + item.c + '</td>'
            + '<td>Change</td>'
            + '<td/>'
          + '</tr><tr class="ui-ticker-stat-line2">'
            + '<td colspan="2">Best Enemy</td>'
          + '</tr></table>').appendTo(contDiv);
      var enemyDiv = $('<div class="ui-corner-bottom ui-ticker-item-footer">'
          + item.e + '</div>').appendTo(itemDiv);
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
      { name: "A Figment of Your Imagination", photo: "player1.jpg", p: "7", r: "3", t: "a", k: "79", d: "57", c: "+4", e: "GOMER PYLE" },
      { name: "CHUCKNORRISCOUNTEDTOINFINITY...", photo: "player2.jpg", p: "23", r: "1", t: "b", k: "27", d: "55", c: "+2", e: "ThePine" },
      { name: "GOMER PYLE", photo: "player3.jpg", p: "2", r: "4", t: "r", k: "108", d: "55", c: "-3", e: "CHUCKNORRISCOUNTEDTOINFINITY..." },
      { name: "ThePine", photo: "player4.jpg", p: "1", r: "5", t: "g", k: "144", d: "80", c: "+1", e: "A Figment of Your Imagination" }
    ]
  }
});

})(jQuery);
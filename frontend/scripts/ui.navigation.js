(function($) {

$.widget("ui.navigation", {

  _init: function() {
    var self = this;

    // Build the document model
    this.element.addClass("ui-nav");
    this.ctrlDiv = $('<div class="ui-state-default ui-corner-right ui-nav-ctrl" title="'
        + this.options.tip + '"><span class="ui-nav-ctrl-icon"/></div>').appendTo(this.element);
    this.bodyDiv = $('<div class="ui-nav-body"/>').appendTo(this.element);
    this.shadowDiv = $('<div class="ui-widget-shadow ui-corner-all ui-nav-shadow"/>').appendTo(this.bodyDiv);
    this.contentDiv = $('<div class="ui-widget-content ui-corner-all ui-nav-content"/>').appendTo(this.bodyDiv);
    this.logoDiv = $('<div class="ui-nav-logo">LOGO</div>').appendTo(this.contentDiv);
    this.menuDiv = $('<div class="ui-nav-menu"/>').appendTo(this.contentDiv);
    this.headerDiv = $('<h2 class="ui-helper-reset ui-widget-header ui-corner-top ui-nav-menu-header">'
        + this.options.header + '</h2>').appendTo(this.menuDiv);
    this.menus = [];
    for (var i = 0; i < this.options.menus.length; i++) {
      var item = this.options.menus[i];
      var menu = $('<h3 class="ui-helper-reset ui-state-default ui-nav-menu"/>').appendTo(this.menuDiv);
      var icon = $('<span class="ui-icon ' + this.options.icon
          + ' ui-nav-menu-icon"/>').appendTo(menu);
      var link = $('<a class="ui-nav-menu-link" href="' + item.url
          + '" title="' + item.tip + '">' + item.name + '</a>').appendTo(menu);
      this.menus[i] = menu;
    }
    this.footerDiv = $('<h4 class="ui-helper-reset ui-widget-header ui-corner-bottom ui-nav-menu-footer">'
        + this.options.footer + '</h4>').appendTo(this.menuDiv);

    // Bind the event handlers
    this.ctrlDiv.bind("mouseenter", function() { self._ctrlOn(); });
    this.ctrlDiv.bind("mouseleave", function() { self._ctrlOff(); });
    this.ctrlDiv.bind("click", function() { self.flyin(); });
    this.bodyDiv.bind("mouseleave", function() { self.flyout(); });
    $(this.menus).each(function(i) {
      $(this).bind("mouseenter", function() { $(this).addClass("ui-state-hover"); });
      $(this).bind("mouseleave", function() { $(this).removeClass("ui-state-hover"); });
      $("a", this).bind("click", function() { self.activate(i); return false; });
    });

    // Setup the initial appearance
    this.bodyDiv.hide();
    setTimeout(function() { self.ctrlDiv.fadeTo("slow", 0.4); }, 500);
  },

  destroy: function() {

    // Clear the event handlers
    this.ctrlDiv.unbind();
    this.bodyDiv.unbind();
    $(this.menus).each(function() {
      $(this).unbind();
      $("a", this).unbind();
    });

    // Destroy the document model
    this.element.removeClass("ui-nav")
    this.ctrlDiv.remove();
    this.bodyDiv.remove();

    $.widget.prototype.destroy.apply(this, arguments);
  },

  flyin: function(callback) {
    if (this.flying) {
      return;
    }
    this.flying = true;

    this.shadowDiv.width(this.bodyDiv.width());
    this.shadowDiv.height(this.bodyDiv.height());

    var self = this;
    this.bodyDiv.show("slide", "slow", function() {
      self.flying = undefined;
      if (callback) {
        callback();
      }
    });
  },

  flyout: function(callback) {
    if (this.flying) {
      return;
    }
    this.flying = true;

    var self = this;
    this.bodyDiv.hide("slide", {}, "slow", function() {
      self.flying = undefined;
      if (callback) {
        callback();
      }
    });
  },

  activate: function(index) {
    var self = this;
    this.flyout(function() {
      window.location = $("a", self.menus[index]).attr("href");
    });
  },

  _ctrlOn: function() {
    this.ctrlDiv.stop().fadeTo("normal", 1.0);
  },

  _ctrlOff: function() {
    this.ctrlDiv.stop().fadeTo("normal", 0.4);
  }

});

$.extend($.ui.navigation, {
  version: "1.7.2",
  defaults: {
    tip: "Click to show navigation",
    header: "Menu",
    footer: "06-14-2009",
    icon: "ui-icon-triangle-1-e",
    menus: [
      { name: "Awards", tip: "", url: "awards.html" },
      { name: "Games", tip: "", url: "games.html" },
      { name: "Game Types", tip: "", url: "game-types.html" },
      { name: "Hit Zones", tip: "", url: "hit-zones.html" },
      { name: "Leaderboard", tip: "", url: "leaderboard.html" },
      { name: "Maps", tip: "", url: "maps.html" },
      { name: "Matchups", tip: "", url: "matchups.html" },
      { name: "Players", tip: "", url: "players.html" },
      { name: "Weapons", tip: "", url: "weapons.html" }
    ]
  }
});

})(jQuery);
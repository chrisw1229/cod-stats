TODO: Requirementify some of these.

# Custom Game Mod #
  * Add killer and victim coordinates to every game type.
  * Add log entries when someone goes in/out of spectator mode.
  * Use "announcement" function to send info to all players.
  * Use "clientannouncement" function to send info to a specific player.
  * Notify everyone of the current leaders periodically.
  * Notify individuals of their progress periodically.
  * Suggest which teams people should join to help auto-balance.
  * Let players type special commands to interact with the stats system:
    * "beer" or "smoke" - Tracks their performance vs. substance intake.
    * "flare" or "beacon" - Highlights their current position on the real-time map.

# Parser #
  * Read each line of input and determine what type of log entry it is.
  * Create a parser interface that is responsible for converting a log entry into an object representation based on its type.
  * Implementations of this parser interface will update the global state of system as appropriate.
  * Once the global system state is updated, then stats can be re-calculated.
  * Create a processor interface that is responsible for computing stats based on the current state.
  * Implement several processors to represent all the rules for creating statistics.
  * Output the most recent updates to some external location after each entry or at some interval.
  * Output a full stat dump including more expensive features once the event is over.
  * Output script files that the server can execute somehow to integrate with the mod.
  * Ignore invalid games (very short during a map change, very few players, no kills, etc).
  * Enable the parser to output and update data in real time for use within and display during a game.

# Player Names #
  * Use console\_mp.log (newly discovered) to map IP address to client number.
  * Use games\_mp.log (normal log) to map client number to player names.
  * The first name used would be the one shown for statistics.
  * Automatically keep track of all names used for each player.
  * Enable an override (possibly mapping file?) in case people change IPs or share computers.

# Frontend (Static) #
  * Generate detailed statistics between games and during an event.
  * Create a slick look and feel for the site.
  * Include all the stats and awards available in the old tool.
  * Allow users to pick the number of players to show in rankings/awards 5,10,20,all, etc.
  * Show various graphs/plots of the data using this jQuery plugin: http://omnipotent.net/jquery.sparkline/
  * Plot the killer/victim coordinates for each map similar to markers on Google maps.
  * Allow users to include/exclude certain maps or games since maps like Jeep Arena skew the numbers.
  * Allow users to compare the stats of 2 players, similar to product comparisons.
  * Allow users to automatically upload their screen shots at the end of the night.

# Frontend (Real-time) #
  * While a game is in progress, use AJAX to update the content every 1 or 2 seconds.
  * While a new game is loading, switch to the static content.
  * Target resolution needs to be 800x600 for TV display.
  * Displays a stock ticker of the players and animated changes in rank.
  * Displays the current map with kill/death markers or a heat map.
  * Displays plots of the total deaths and current death rate for the event.
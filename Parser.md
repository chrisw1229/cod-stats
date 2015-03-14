# Technology #

Clojure, Java

[Parser](http://wiki.github.com/joshua-choi/fnparse) library being used.  Likely be in two chunks with one specific to CoD and a base set of things like newlines, semi-colon literals, numbers, identifiers, etc.

A JSON configuration file will be needed to convert some items into more detailed descriptions.  One example would be taking the weapon name string and converting that to its English name as well as possibly the name of an image file for display on the awards page.

All the log entries are converted to data/symbol combos that Clojure can understand.  The built in map, filter and reduce functions seem to cover a large majority of what we need to calculate the awards.  This data will then be pushed out as JSON to the web frontend.

Live stats will need to be processed on a per game basis.  Depending on performance it might make the most sense to update the overall standings at the end of each game.

We may end up with two CoD parser versions as well with the straight CoD and mod-CoD.

To play around with [Clojure](http://clojure.bighugh.com/) and a good [reference](http://jnb.ociweb.com/jnb/jnbMar2009.html).

# BNF #

Note, for this implementation the longer options for an item should be listed before the shorter items if the longer is a superset of the shorter (IE: "sayteam" before "say").  Otherwise the parser will try the shorter first, consume the tokens and freak out on the rest of the longer one.  (IE: "sayteam" would get the "say" consumed and then the parser would be like "WTF is 'team'!!?)

```
<time-stamp> ::= <number>":"<number>

<log-file> ::= <line> | <line> <log-file>
<line> ::= <opt-ws><time-stamp><ws><action><new-line>
   | repeat 60 "-"

<action> ::= <server-action> | <player-action>

<server-action> ::= <string>":"<string>

<team> ::= "axis" | "allies"

<player> ::= <number>";"<number>";"<team>";"<string>
   | <number>";"<number>";"<string>
   | <number>";"<string>

<hit-info> ::= <weapon>";<number>";"<damage-type>";"<damage-area>
<pain-type> ::= "D" | "K"
<damage-kill> ::= <pain-type>";"<player>";"<player>";"<hit-info>//victim then attacker
   | <pain-type>";"<player>";"";-1;world;"";"<hit-info>//world damage

<talk-id> ::= "sayteam" | "say"
<talk-action> ::= <talk-id>";"<player>";"<string>

<pickup-type> ::= "Weapon" | "Item"
<pickup> ::= <pickup-type>";"<player>";"<string>

<join-quit> ::= "J"";"<player> | "Q"";"<player>

<game-event> ::= "A"";"<player>";"<string>
<win-loss-event> ::= "W"";"<team>*(";"<player>)
   | "L"";"<team>(";"<player>)

<player-action> ::= <damage-kill> 
   | <talk-action> 
   | <pickup> 
   | <join-quit> 
   | <game-event>
   | <win-loss-event>
```

Stats generation - The current initial idea is to extract certain kinds of log-lines and then filter down that set to get the data we want.  IE: We would get all of the damage-kill lines, then just the kill lines.  Add the name of attackers to a set and then use that attacker set to filter/count the number of kills for each person from the kill set.

This strategy seems to be working well.  I think it might also be possible to get all of the awards calculated without tracking state.  This would work by splitting the log sequences up by, for example, life to get some of our awards.  (IE: Get all log lines for a player then split that set by death.  For each of those "life" subsets do whatever calculation we need, etc.)

# Real Time #

Things I still need to create: Something similar to the Unix tail -f function to watch a file and pass in lines to add to the current game set.

The actual real time data set code.  On each line being read in store it in either a master list or pre-filter out into separate lists (IE: Damage-kill list, kill list, connect-disconnect list, etc.).

The code to recalculate the current stats and output them to the front end.  I'll probably start by setting up a separate thread to recalculate every X seconds from the current data.  If that ends up being too slow I can likely have aggregated stats from the "old" log entries and read in lines from a "new" queue then only need to do the fine grained stats calculations on the new entries, add the "new" log entries to the "old" set and update the aggregate stats to output.

Game log = games\_mp.log
Connect log = console\_mp.log

On startup of backend watch for creation of those two files and then start processing the logs.
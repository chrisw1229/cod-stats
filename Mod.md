# Information #

[Script Documentation](http://www.zeroy.com/script)


# Setup #

  1. Create a new folder for the mod: {INSTALL\_DIR}/cod-stats
  1. Add all the required scripts to the folder (either as .pk3 or individual files).
  1. Use this parameter when starting the game: +set fs\_game cod-stats
  1. In order to set additional options whenever the game starts, use the following steps:
    1. Add the following parameter to the game shortcut: +exec settings.cfg
    1. Create a new configuration file: {INSTALL\_DIR}/cod-stats/settings.cfg
    1. Edit the file with a text editor and add one or more of the following parameters.
    1. Each parameter should be on its own line and some common ones are included below.
    1. set sv\_pure "0"
      1. Allows the game to execute modded or non-standard files.
    1. set logfile "2"
      1. Forces each console log entry to be written immediately.
    1. set g\_logsync "1"
      1. Forces each game log entry to be written immediately.
    1. set g\_gametype "tdm"
      1. Sets the default game type to load.
    1. set map "mp\_carentan"
      1. Sets the default map to load.

# Implementation #

  * For this section, the term "game file" refers to: dm.gsc, tdm.gsc, ctf.gsc, dom.gsc, ftf.gsc, sftf.gsc

  1. Add game initialization log entries.
    1. Edit the `Callback_StartGameType` function at the beginning of each game file.
    1. Add details about the game that is currently loading.
      1. Round time is an integer given in minutes.
      1. Allies team is one of: "american", "british", or "russian".
      1. Axis team will basically always be "german".
    1. Format: `Game;GameType;MapName;RoundTime;AlliesTeam;AxisTeam`
    1. EX: `Game;tdm;mp_uo_carentan;30;american;german`
  1. Add more details to kill log entries.
    1. Edit the `Callback_PlayerKilled` function in each game file.
    1. Add map coordinates for the killer and victims to the log. {x,y,z}
    1. Add yaw orientation angles for the killer and victims to the log. {-180.0 to +180.0}
      1. Value range will be divided into 90 degree quadrants for comparison purposes. Front, back, and 2 sides.
    1. Add stance type for the killer and victims to the log. {stand,crouch,prone}
    1. Format: `{KILL_LINE} + VictimX,VictimY,VictimZ;KillerX,KillerY,KillerZ;VictimAngle;KillerAngle;VictimStance;KillerStance`
    1. EX: `K;0;0;axis;Luda;0;0;axis;Luda;fraggrenade_mp;111;MOD_GRENADE_SPLASH;none;631.87,20.4834,-2.12491;631.87,20.4834,-2.12491;12.8705;12.8705;stand;stand`
  1. Add player ranking log entries.
    1. Edit the `_rank_gmi.gsc` file.
    1. All players implicitly start with a rank of 0.
    1. Add a log message when a player changes rank. {0 to 4}
    1. Format: `Rank;GUID;Num;Team;Name;NewRank`
    1. EX: `Rank;0;0;axis;Luda;1`
  1. Add spectator log entries.
    1. Edit the `spawnSpectator` functions in each game file.
    1. Add a log message when the player enters spectator mode.
    1. Format: `Spec;GUID;Num;Name`
    1. EX: `Spec;0;1;Luda`
  1. Add starting spawn positions as a separate log entry.
    1. Edit the `spawnPlayer` functions in each game file.
    1. Add a log message when a player spawns for their location.
    1. Format: `Spawn;GUID;Num;Team;Name;Weapon;PlayerX,PlayerY,PlayerZ;PlayerAngle`
    1. EX: `Spawn;0;0;axis;Luda;kar98k_sniper_mp;-663.905,440.078,3.92032;-135`
  1. Add vehicle position log entries.
    1. Edit the `_jeepdrive_gmi.gsc` and `_tankdrive_gmi.gsc` files.
    1. Add a log message when the player gets in or out of a vehicle.
    1. Vehicle number is just a counter from 0 on up, acting as an id number. Tanks and jeeps each have their own count, so the number + type forms a unique id.
    1. Vehicle team values can be "all" if vehicles are not exclusive to one team.
    1. Vehicle seat values represent none, driver, gunner, passenger. {0 to 3}
    1. When a player changes vehicle seats, 2 log entries are created due to the way callbacks are issued in the game. One for exiting the first position and one for entering the new position, where the exit entry can really be ignored in this case.
    1. Vehicle captures can be detected when the player team differs from the vehicle team and the vehicle team is not "all". If a player gets in and then out before completing a capture, no log entry is created. Once a vehicle is captured successfully, its team is changed to "all" for future log entries until it is destroyed and respwaned.
    1. Format: `Use;GUID;Num;Team;Name;VehicleNum;VehicleTeam;VehicleType;Seat;PlayerX,PlayerY,PlayerZ;PlayerAngle`
    1. EX: `Use;0;0;axis;Luda;10;all;shermantank_mp;1;-274,-288,58.7392;-90`
  1. Add mounted turret gun and flak gun use log entries.
    1. Edit the `_turret_gmi.gsc` and `_flak_gmi.gsc` file.
    1. Add a log message when the player gets on or off of a gun.
    1. Gun number is just a counter from 0 on up, acting as an id number. Turret and flak guns each have their own count, so the number + type forms a unique id.
    1. Gun team will always be "all" since guns cannot be captured.
    1. Gun seat values represent none or gunner. {0,1}
    1. Format: `Use;GUID;Num;Team;Name;GunNum;GunTeam;GunType;Seat;PlayerX,PlayerY,PlayerZ;PlayerAngle`
    1. EX: `Use;0;0;allies;Luda;1;all;mg42_turret_mp;1;-815.11,-505.223,339.125;54.3878`
  1. Add world object damage log entries.
    1. Edit the `_treefall_gmi.gsc` file.
    1. Add a log message when a world object such as a tree or street light is crushed by a vehicle or takes damage from explosive weapons.
    1. Note that the log entry format is the same as for player damage.
    1. ObjectGUID, ObjectNum, and ObjectTeam will always be empty, -1, and "world" respectively.
    1. Object Name is actually the name of the file used for the graphics model.
    1. Weapon will always be "none" except for vehicle crush damage because it can't be reliably determined at the time of the damage.
    1. Hit Location will always be "none".
    1. Format: `D;ObjectGUID;ObjectNum;ObjectTeam;ObjectName;PlayerGUID;PlayerNum;PlayerTeam;PlayerName;Weapon;Damage;DamageType;HitLocation`
    1. EX: `D;;-1;world;xmodel/light_streetlight2off;0;0;axis;Luda;panzeriv_mp;100;MOD_CRUSH_TANK;none`
  1. Add player shell shock log entries.
    1. Edit the `_shellshock_gmi.gsc` file.
    1. Add a log message when a player is shell shocked due to damage received.
    1. Shock time is the number of seconds the player was shocked. {1 to 4}
    1. Format: `Shock;GUID;Num;Team;Name;Weapon;ShockTime;DamageType;HitLocation`
    1. EX: `Shock;0;0;allies;Luda;fraggrenade_mp;3;MOD_GRENADE_SPLASH;none`
  1. Add vehicle kill log entries.
    1. Edit the `_jeepeffects_gmi.gsc` and `_tankeffects_gmi.gsc` files.
    1. Add a log message when a vehicle is killed by a player or the world.
    1. Note that the log entry format is the same as for player kills.
    1. Vehicle GUID is just a counter from 0 on up, acting as an id number. Tanks and jeeps each have their own count, so the number + type forms a unique id.
    1. Vehicle number here is always -1 so it can be easily identified as a vehicle death.
    1. Vehicle team values can be "all" if vehicles are not exclusive to one team.
    1. Killer GUID, Num, Team, and Name can be empty if it was done by "world" just like when players are killed.
    1. Killer weapon will always be "none" because it can't be reliably determined at the time of the vehicle death.
    1. Damage is always 10000 because that is what is dealt to a vehicle when it needs to explode.
    1. Damage Type is always MOD\_EXPLOSIVE or MOD\_WATER.
    1. Hit Location and Vehicle Stance will always be "none".
    1. Format: `K;VehicleGUID;VehicleNum;VehicleTeam;VehicleType;KillerGUID;KillerNum;KillerTeam;KillerName;KillerWeapon;Damage;DamageType;HitLocation;VehicleX,VehicleY,VehicleZ;KillerX,KillerY,KillerZ;VehicleAngle;KillerAngle;VehicleStance;KillerStance`
    1. EX: `K;1;-1;axis;panzeriv_mp;0;0;axis;Luda;none;10000;MOD_EXPLOSIVE;none;480,8109,-143.558;951.296,7731.92,-27.9767;-90;141.147;none;stand`
  1. Add player actions to game type log entries.
    1. Edit the `Callback_PlayerKilled` function in the game files.
    1. Add a log message when various game actions occur.
      1. Action values are in the notes under "Game Awards" section of the awards page.
    1. Add map location coordinates to all game actions log entries.
    1. Use the is\_near\_flag functions from ctf.gsc as a starting point.
    1. Format: `A;GUID;Num;Team;Name;Action;PlayerX;PlayerY;PlayerZ;PlayerAngle;PlayerStance`
    1. EX: `A;0;0;allies;Luda;ftf_stole;-815.11,-505.223,339.125;54.3878;stand`
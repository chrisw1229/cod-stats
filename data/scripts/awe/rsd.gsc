/*	limit lives 11-23 last edit. Improve second weapon drop moves some lines added wait
	11-24 removed guid checks almost fixed weapopn issue
	11-26 removed weapon carry over
	11-29  edit added to kill player switching teams
	12-1    edit fixed healthdrop
	12-7 back to S&D spawns for whole game
	Reinforced Search and Destroy (AWE version)
	Attackers objective: Bomb 2 positions
	Defenders objective: Defend these 2 positions / Defuse planted bombs
	Round ends:	When bomb explodes or roundlength time is reached.
	Map ends:	When all rounds have been played.
	Respawning:	When player dies, they are placed in a timed reinforcement queue.  Time to reinforce (in seconds) is set by the server through b_rsd_queueTime_<team>.

	Mod created by Boco and is based off the Search and Destroy game mode made by Infinity Ward.
	Cvars used by this mod can be found in the readme.txt file.

	Modified to work with AWEUO and United Offensive by Bell
	Fixed up for use with AWEUO final version by GroundPounder\Ol'ClumsyFingers finally! \o/
	Tweaked again by bell to make it work with AWEUO 2.0
*/

main()
{
	game["mod_version"] = "1.7(AWEUO)";
	println("^1*****Starting Reinforced Search and Destroy*****");
	println("^1::Version ^7", game["mod_version"]);
	println("^1::Created by ^4B^7oco, modifed for UO by bell");

	spawnpointname[0] = "mp_sd_spawn_allied"; // edit cant see flak gun in Berlin
	spawnpointname[1] = "mp_searchanddestroy_spawn_allied";
	spawnpoints[0] = getentarray(spawnpointname[0], "classname");
	spawnpoints[1] = getentarray(spawnpointname[1], "classname");

	if(!spawnpoints[0].size)
	{
		game["map_ent_name"] = "searchanddestroy";
		if ( !spawnpoints[1].size )
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}
		for(i = 0; i < spawnpoints[1].size; i++)
			spawnpoints[1][i] placeSpawnpoint();
	}
	else
	{
		game["map_ent_name"] = "rsd";
		for(i = 0; i < spawnpoints[0].size; i++)
			spawnpoints[0][i] placeSpawnpoint();
	}

	spawnpointname[0] = "mp_rsd_spawn_axis";
	spawnpointname[1] = "mp_searchanddestroy_spawn_axis";
	spawnpoints[0] = getentarray(spawnpointname[0], "classname");
	spawnpoints[1] = getentarray(spawnpointname[1], "classname");

	if(!spawnpoints[0].size)
	{
		if ( !spawnpoints[1].size )
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}
		for(i = 0; i < spawnpoints[1].size; i++)
			spawnpoints[1][i] placeSpawnpoint();
	}
	else
		for(i = 0; i < spawnpoints[0].size; i++)
			spawnpoints[0][i] placeSpawnpoint();

	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;

	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	level._effect["bombexplosion"] = loadfx("fx/explosions/v2_exlosion.efx");

	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";
	allowed[3] = "rsd";
	maps\mp\gametypes\_gameobjects::main(allowed);

	maps\mp\gametypes\_rank_gmi::InitializeBattleRank();
	maps\mp\gametypes\_secondary_gmi::Initialize();

	// Boco: Set basic cvars
	level.roundlimit = cvarBounds( "scr_rsd_roundlimit", "int", 1, 1 );
	setCvar("ui_rsd_roundlimit", level.roundlimit);
	level.roundlength = cvarBounds( "scr_rsd_roundlength", "int", 10, 1, 30 );
	level.graceperiod = cvarBounds( "scr_rsd_graceperiod", "float", 15, 0, 60 );
	cvarBounds( "scr_friendlyfire", "int", 1, 0, 4 );
	level.drawfriend = cvarBounds( "scr_drawfriend", "int", 1, 0, 1 );
	level.battlerank = cvarBounds( "scr_battlerank", "int", 1, 0, 1);
	setCvar("ui_battlerank", level.battlerank);

	if(getCvar("scr_shellshock") == "")		// controls whether or not players get shellshocked from grenades or rockets
		setCvar("scr_shellshock", "1");
	setCvar("ui_shellshock", getCvar("scr_shellshock"));
	makeCvarServerInfo("ui_shellshock", "0");
			
	if(!isDefined(game["compass_range"]))		// set up the compass range.
		game["compass_range"] = 1024;		
	setCvar("cg_hudcompassMaxRange", game["compass_range"]);

	if(getCvar("scr_drophealth") == "")
		setCvar("scr_drophealth", "1");

	level.killcam = cvarBounds( "scr_killcam", "int", 1, 0, 1 );
	level.teambalance = cvarBounds( "scr_teambalance", "int", 1, 0, 1 );
		level.teambalancetimer = 0;
	level.allowfreelook = cvarBounds( "scr_freelook", "int", 0, 0, 1 );
	level.allowenemyspectate = cvarBounds( "scr_spectateenemy", "int", 0, 0, 1 );

	// Boco: Define RSD cvar defaults.
	setCvar( "modversion", game["mod_version"], true );
	level.queueTime_allies = cvarBounds( "b_rsd_queueTime_allies", "int", 30, 1, 99 );
	level.queueTime_axis = cvarBounds( "b_rsd_queueTime_axis", "int", 30, 1, 99 );
	cvarBounds( "b_spawn_protect_allies", "int", 5, 0, 99 );
	cvarBounds( "b_spawn_protect_axis", "int", 5, 0, 99 );
	cvarBounds( "b_spawn_protect_noShoot", "int", 0, 0, 1 );
	cvarBounds( "b_rsd_obj_destroyBoth", "int", 1, 0, 1 ); level.obj_destroyed = 0;
	cvarBounds( "b_rsd_bomb_arm", "float", 3, 0, 99 );
	cvarBounds( "b_rsd_bomb_defuse", "float", 6, 0, 99 );
	cvarBounds( "b_rsd_bomb_time", "int", 36, 1, 99 );
	cvarBounds( "b_rsd_bomb_blow_points", "int", 4, 0 );
	cvarBounds( "b_rsd_bomb_arm_points", "int", 2, 0 );
	cvarBounds( "b_rsd_bomb_defuse_points", "int", 2, 0 );
	cvarBounds( "b_rsd_bomb_suddenDeath", "int", 1, 0, 1 );
	cvarBounds( "b_rsd_latejoin_penalty", "int", 0, 0, 99 );
	cvarBounds( "b_rsd_switchteam_penalty", "int", 10, 0, 99 );
	cvarBounds( "b_rsd_suicide_penalty", "int", 10, 0, 99 );
	cvarBounds( "b_clip_default", "int", 2, 0 );
	cvarBounds( "b_player_health", "int", 100, 0, 1000 );
	level.player_lives["allies"] = cvarBounds( "b_player_lives_allies", "int", 0, 0, 99 );
	level.player_lives["axis"] = cvarBounds( "b_player_lives_axis", "int", 0, 0, 99 );
	cvarBounds( "scr_drophealth", "int", 0, 0, 1 ); // edit use to be "b_player_dropHealth"
	cvarBounds( "b_player_tkmode", "int", 0, 0 );
	cvarBounds( "b_player_tk_spawnPenalty", "int", 5, 0 );
	cvarBounds( "b_player_tklimit", "int", 5, 0 );
	cvarBounds( "b_limitedlives_lateJoin", "int", 1, 0, 1 );
	cvarBounds( "b_limitedlives_lateJoin", "int", 1, 0, 1 );

//	cvarBounds( "b_corpse_timeout", "float", 0, 0 );
	cvarBounds( "b_testbots", "int", 0, 0 );

	cvarBounds( "b_print_settings", "int", 1, 0, 1 );

	//-----------------------

	if(!isdefined(game["state"]))

		game["state"] = "playing";
	if(!isdefined(game["roundsplayed"]))
		game["roundsplayed"] = 0;
	if(!isdefined(game["matchstarted"]))
		game["matchstarted"] = false;

	if(!isdefined(game["alliedscore"]))
		game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);

	if(!isdefined(game["axisscore"]))
		game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);

	// turn off ceasefire
	level.ceasefire = 0;
	setCvar("scr_ceasefire", "0");

	level.bombplanted[0] = false;
	level.bombplanted[1] = false;
	level.bombexploded[0] = false;
	level.bombexploded[1] = false;
	level.roundstarted = false;
	level.roundended = false;
	level.mapended = false;

	level.healthqueue = [];
	level.healthqueuecurrent = 0;

	level.voices["german"] = 3;
	level.voices["american"] = 7;
	level.voices["russian"] = 6;
	level.voices["british"] = 6;

	level.exist["allies"] = 0;
	level.exist["axis"] = 0;
	level.exist["teams"] = false;
	level.didexist["allies"] = false;
	level.didexist["axis"] = false;

	// Boco: Initialize the bomb model array.
	level.bombmodel[0] = 0;
	level.bombmodel[1] = 0;

	if ( level.killcam == 1 )
		setArchive( true );
	else
		setArchive( false );
}

Callback_StartGameType()
{

/////////////// Added by AWE ////////////////////
	maps\mp\gametypes\_awe::Callback_StartGameType();
/////////////////////////////////////////////////

	// if this is a fresh map start, set nationalities based on cvars, otherwise leave game variable nationalities as set in the level script
	if(!isdefined(game["gamestarted"]))
	{
		// defaults if not defined in level script
		if(!isdefined(game["allies"]))
			game["allies"] = "american";
		if(!isdefined(game["axis"]))
			game["axis"] = "german";

		if(!isdefined(game["layoutimage"]))
			game["layoutimage"] = "default";
		layoutname = "levelshots/layouts/hud@layout_" + game["layoutimage"];
		precacheShader(layoutname);
		setcvar("scr_layoutimage", layoutname);
		makeCvarServerInfo("scr_layoutimage", "");

		// server cvar overrides
		if(getcvar("scr_allies") != "")
			game["allies"] = getcvar("scr_allies");	
		if(getcvar("scr_axis") != "")
			game["axis"] = getcvar("scr_axis");

		game["menu_team"] = "team_" + game["allies"] + game["axis"];
		game["menu_weapon_allies"] = "weapon_" + game["allies"];
		game["menu_weapon_axis"] = "weapon_" + game["axis"];
		game["menu_viewmap"] = "viewmap";
		game["menu_callvote"] = "callvote";
		game["menu_quickcommands"] = "quickcommands";
		game["menu_quickstatements"] = "quickstatements";
		game["menu_quickresponses"] = "quickresponses";
		game["menu_quickvehicles"] = "quickvehicles";
		game["menu_quickrequests"] = "quickrequests";

		precacheString(&"MPSCRIPT_PRESS_ACTIVATE_TO_SKIP");
		precacheString(&"MPSCRIPT_KILLCAM");
		precacheString(&"SD_MATCHSTARTING");
		precacheString(&"SD_MATCHRESUMING");
		precacheString(&"SD_EXPLOSIVESPLANTED");
		precacheString(&"SD_EXPLOSIVESDEFUSED");
		precacheString(&"SD_ROUNDDRAW");
		precacheString(&"SD_TIMEHASEXPIRED");
		precacheString(&"SD_ALLIEDMISSIONACCOMPLISHED");
		precacheString(&"SD_AXISMISSIONACCOMPLISHED");
		precacheString(&"SD_ALLIESHAVEBEENELIMINATED");
		precacheString(&"SD_AXISHAVEBEENELIMINATED");
		precacheString(&"GMI_MP_CEASEFIRE");

		precacheMenu(game["menu_team"]);
		precacheMenu(game["menu_weapon_allies"]);
		precacheMenu(game["menu_weapon_axis"]);
		precacheMenu(game["menu_viewmap"]);
		precacheMenu(game["menu_callvote"]);
		precacheMenu(game["menu_quickcommands"]);
		precacheMenu(game["menu_quickstatements"]);
		precacheMenu(game["menu_quickresponses"]);
		precacheMenu(game["menu_quickvehicles"]);
		precacheMenu(game["menu_quickrequests"]);

		precacheShader("black");
		precacheShader("white");
		precacheShader("hudScoreboard_mp");
		precacheShader("gfx/hud/hud@mpflag_spectator.tga");
		precacheStatusIcon("gfx/hud/hud@status_dead.tga");
		precacheStatusIcon("gfx/hud/hud@status_connecting.tga");

		// Boco: Precache the skull and crossbones status icon.
		precacheStatusIcon("gfx/hud/death_suicide.tga");
		precacheShader("gfx/hud/hud@status_dead.tga");

		precacheShader("ui_mp/assets/hud@plantbomb.tga");
		precacheShader("ui_mp/assets/hud@defusebomb.tga");
		precacheShader("gfx/hud/hud@objectiveA.tga");
		precacheShader("gfx/hud/hud@objectiveA_up.tga");
		precacheShader("gfx/hud/hud@objectiveA_down.tga");
		precacheShader("gfx/hud/hud@objectiveB.tga");
		precacheShader("gfx/hud/hud@objectiveB_up.tga");
		precacheShader("gfx/hud/hud@objectiveB_down.tga");
		precacheShader("gfx/hud/hud@bombplanted.tga");
		precacheShader("gfx/hud/hud@bombplanted_up.tga");
		precacheShader("gfx/hud/hud@bombplanted_down.tga");
		precacheShader("gfx/hud/hud@bombplanted_down.tga");
		precacheModel("xmodel/mp_bomb1_defuse");
		precacheModel("xmodel/mp_bomb1");

		//precacheModel("xmodel/vehicle_plane_stuka");

		precacheItem("item_health");

		game["RSD_Text"][0] = &"seconds left until respawn.";
		game["RSD_Text"][1] = &"x";
		precacheString(game["RSD_Text"][0]);
		precacheString(game["RSD_Text"][1]);

		maps\mp\gametypes\_teams::precache();
		maps\mp\gametypes\_teams::scoreboard();

		//BOT CLIENTS
		for ( tb = 0; tb < getcvarint("b_testbots"); tb++ )
			thread addBotClients();
	}

	maps\mp\gametypes\_teams::modeltype();
	maps\mp\gametypes\_teams::initGlobalCvars();
	maps\mp\gametypes\_teams::initWeaponCvars();
	maps\mp\gametypes\_teams::restrictPlacedWeapons();
	thread maps\mp\gametypes\_teams::updateGlobalCvars();
	thread maps\mp\gametypes\_teams::updateWeaponCvars();

	game["gamestarted"] = true;

	// Boco: Custom objective text.
	game["obj_text"]["attackers"] = "^1RSD version ^7" + game["mod_version"] + " ^1- www.iwnation.com/Hosted/Boco/index.html\n^7Destroy the objectives to win!";
	game["obj_text"]["defenders"] = "^1RSD version ^7" + game["mod_version"] + " ^1- www.iwnation.com/Hosted/Boco/index.html\n^7Prevent the objectives from being destroyed to win!";

	// Boco: Set to auto_change to allow the player to change their name in the middle of the match.
	setClientNameMode("auto_change");

	thread bombzones(0);
	thread bombzones(1);
	thread startGame();
	thread updateGametypeCvars();
}

printServerSettings()
{
	if(!getcvarint("b_print_settings"))
		return;

	wait 3;

	// Boco: Display server settings.
	self iprintln("^1*****Starting Reinforced Search and Destroy*****");
	self iprintln("^1::Version ^7", game["mod_version"]);
	self iprintln("^1::Created by ^4B^7oco");
	self iprintln("^1::URL - ^7http://www.iwnation.com/Hosted/Boco/index.html");
	self iprintln("^2::Server Settings");
	self printSetting( "Number of rounds       ^5: ", "scr_rsd_roundlimit" );
	self printSetting( "Time of round          ^5: ", "scr_rsd_roundlength" );
	self printSetting( "Grace period           ^5: ", "scr_rsd_graceperiod" );
	self iprintln("-----");
	self printSetting( "Queue Allies           ^5: ", "b_rsd_queueTime_allies" );
	self printSetting( "Queue Axis             ^5: ", "b_rsd_queueTime_axis" );
	self iprintln("-----");
	if ( getcvarint("b_rsd_obj_destroyBoth") == 1 )
		self iprintln("Game type              ^5: Normal");
	else
		self iprintln("Game type              ^5: Single Bomb");
	self iprintln("-----");
	self printSetting( "Bomb arm time          ^5: ", "b_rsd_bomb_arm" );
	self printSetting( "Bomb defuse time       ^5: ", "b_rsd_bomb_defuse" );
	self printSetting( "Bomb time              ^5: ", "b_rsd_bomb_time" );
	self printSetting( "Bomb Sudden Death mode ^5: ", "b_rsd_bomb_suddenDeath", 2, "ed" );
	self iprintln("-----");
	self printSetting( "Latejoin penalty       ^5: ", "b_rsd_latejoin_penalty" );
	self printSetting( "Switchteam penalty     ^5: ", "b_rsd_switchteam_penalty" );
	self printSetting( "Suicide penalty        ^5: ", "b_rsd_suicide_penalty" );
	self iprintln("-----");

	// Boco: Give it time to rest.
	wait 0.2;

	self printSetting( "Default gun clips      ^5: ", "b_clip_default" );
	self printSetting( "::Clip - BAR           ^5: ", "b_clip_bar", 1 );
	self printSetting( "::Clip - Bren          ^5: ", "b_clip_bren", 1 );
	self printSetting( "::Clip - Colt          ^5: ", "b_clip_colt", 1 );
	self printSetting( "::Clip - Enfield       ^5: ", "b_clip_enfield", 1 );
	self printSetting( "::Clip - Kar98k        ^5: ", "b_clip_kar98k", 1 );
	self printSetting( "::Clip - Kar98k Sniper ^5: ", "b_clip_kar98ksniper", 1 );
	self printSetting( "::Clip - Luger         ^5: ", "b_clip_luger", 1 );
	self printSetting( "::Clip - M1Carbine     ^5: ", "b_clip_m1carbine", 1 );
	self printSetting( "::Clip - M1Garand      ^5: ", "b_clip_m1garand", 1 );
	self printSetting( "::Clip - MP40          ^5: ", "b_clip_mp40", 1 );
	self printSetting( "::Clip - MP44          ^5: ", "b_clip_mp44", 1 );
	self printSetting( "::Clip - Nagant        ^5: ", "b_clip_nagant", 1 );
	self printSetting( "::Clip - Nagant Sniper ^5: ", "b_clip_nagantsniper", 1 );
	self printSetting( "::Clip - PPSH          ^5: ", "b_clip_ppsh", 1 );
	self printSetting( "::Clip - Springfield   ^5: ", "b_clip_springfield", 1 );
	self printSetting( "::Clip - Sten          ^5: ", "b_clip_sten", 1 );
	self printSetting( "::Clip - Thompson      ^5: ", "b_clip_thompson", 1 );
	self printSetting( "::Grenade - American   ^5: ", "b_clip_fraggrenade", 1 );
	self printSetting( "::Grenade - British    ^5: ", "b_clip_mk1britishfrag", 1 );
	self printSetting( "::Grenade - Russian    ^5: ", "b_clip_rgd-33russianfrag", 1 );
	self printSetting( "::Grenade - German     ^5: ", "b_clip_stielhandgranate", 1 );
	self iprintln("-----");

	//Boco: Give it time to rest.
	wait 0.2;

	self printSetting( "Spawn protect: Allies  ^5: ", "b_spawn_protect_allies" );
	self printSetting( "Spawn protect: Axis    ^5: ", "b_spawn_protect_axis" );
	if ( getcvarint("b_spawn_protect_noShoot") == 1 )
		self iprintln("Spawn protect mode     ^5: Disable if shoots");
	self printSetting( "Team balance           ^5: ", "scr_teambalance", true );
	self iprintln("-----");

	if ( getcvarint("b_player_tkmode") == 0 )
	{
		self iprintln("TK Mode                ^5: Reflect");
		self printSetting( "TK Limit               ^5: ", "b_player_tklimit" );
	}
	else if ( getcvarint("b_player_tkmode") == 1 )
	{
		self iprintln("TK Mode                ^5: Spawn Penalty");
		self printSetting( "TK Spawn Penalty       ^5: ", "b_player_tk_spawnPenalty" );
	}

	wait 0.2;
	self iprintln("-----");
	self printSetting( "Player health          ^5: ", "b_player_health" );
	self printSetting( "Drop health on death   ^5: ", "scr_drophealth", 2, "tf" );
	self iprintln("-----");
	if ( getcvarint("b_player_lives_allies") > 0 )
		self iprintln("Player lives: Allies   ^5: ", getcvar("b_player_lives_allies"));
	if ( getcvarint("b_player_lives_axis") > 0 )
		self iprintln("Player lives: Axis     ^5: ", getcvar("b_player_lives_axis"));
	self printSetting( "Limited Lives latejoin ^5: ", "b_limitedlives_lateJoin", 2, "tf" );
	self iprintln("-----");

	self printSetting( "Kill Cam               ^5: ", "scr_killcam", 2, "ed" );
	self iprintln("-----");
	self iprintln("^2Settings printed to console.  Open console to view.");
}

Callback_PlayerConnect()
{
	self.statusicon = "gfx/hud/hud@status_connecting.tga";
	self waittill("begin");
	self.statusicon = "";
		if (!isdefined (self.pers["teamTime"]))
		self.pers["teamTime"] = 1000000;

	// Boco: Print the server settings.
	if ( firstTime == qtrue )
		self thread printServerSettings();

	// Boco: Initialize player variables.
	//self.notspawned = 20;
	self.addQueueTime = 0;
	self.addPQueueTime = 0;
	self.force_gracePeriod = 0;
	self.tk = 0;
	self.tk_reflect = false;
	self.lives_hud = false;
	if ( !isDefined( self.lives ) )
		self.lives = 1;  //edit changed to 1 from 0

	if(!isdefined(self.pers["score"]))
		self.pers["score"] = 0;
	self.score = self.pers["score"];

	if(!isdefined(self.pers["deaths"]))
		self.pers["deaths"] = 0;
	self.deaths = self.pers["deaths"];

	if(!isdefined(self.pers["team"]))
		iprintln(&"MPSCRIPT_CONNECTED", self);

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("J;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");


	// Boco: Limited lives.
	if ( self.lives_HUD == false )
	{
		self thread limitedLife_HUD();
		self.lives_HUD = true;
		self.given_lives = false;
	}

	if(game["state"] == "intermission")
	{
		spawnIntermission();
		return;
	}

	level endon("intermission");

	if(isdefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_weapontab", "1");

		if(self.pers["team"] == "allies")
		{
			self.sessionteam = "allies";
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
				} else {
			self.sessionteam = "axis";
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
				}

		// Boco: If match is starting, just spawn the player.
		if(isdefined(self.pers["weapon"])) {
			self.pers["weapon"] = self.pers["spawnweapon"];
			self setLives();
			if ( level.roundstarted )
			{
				self.suicide = true;
				self suicide();
			} 
			else
				spawnPlayer();
			}	
			 else 
			{
			self.sessionteam = "spectator";
			spawnSpectator();

			if(self.pers["team"] == "allies")
				self openMenu(game["menu_weapon_allies"]);
			else
				self openMenu(game["menu_weapon_axis"]);
				}
	}
	else
	{
		self setClientCvar("g_scriptMainMenu", game["menu_team"]);
		self setClientCvar("ui_weapontab", "0");

		if(!isdefined(self.pers["team"]))
			self openMenu(game["menu_team"]);

		self.pers["team"] = "spectator";
		self.sessionteam = "spectator";

		spawnSpectator();
	}

	// start the vsay thread
	self thread maps\mp\gametypes\_teams::vsay_monitor();


	for(;;)
	{
		self waittill("menuresponse", menu, response);

		if(response == "open" || response == "close")
			continue;

		if(menu == game["menu_team"])
		{
			switch(response)
			{
			case "allies":
			case "axis":
			case "autoassign":
				if(response == "autoassign")
				{
					numonteam["allies"] = 0;
					numonteam["axis"] = 0;

					players = getentarray("player", "classname");
					for(i = 0; i < players.size; i++)
					{
						player = players[i];
					
						if(!isdefined(player.pers["team"]) || player.pers["team"] == "spectator" || player == self)
							continue;
			
						numonteam[player.pers["team"]]++;
					}

					// if teams are equal return the team with the lowest score
					if(numonteam["allies"] == numonteam["axis"])
					{
						if(getTeamScore("allies") == getTeamScore("axis"))
						{
							teams[0] = "allies";
							teams[1] = "axis";
							response = teams[randomInt(2)];
						}
						else if(getTeamScore("allies") < getTeamScore("axis"))
							response = "allies";
						else
							response = "axis";
					}
					else if(numonteam["allies"] < numonteam["axis"])
						response = "allies";
					else
						response = "axis";
					skipbalancecheck = true;
				}

				if(response == self.pers["team"] && (self.sessionstate == "playing"))
					break;

				//Check if the teams will become unbalanced when the player goes to this team...
				//------------------------------------------------------------------------------
				if ( (level.teambalance > 0) && (!isdefined (skipbalancecheck)) )
				{
					//Get a count of all players on Axis and Allies
					players = maps\mp\gametypes\_teams::CountPlayers();
					
					if (self.sessionteam != "spectator")
					{
						if (((players[response] + 1) - (players[self.pers["team"]] - 1)) > level.teambalance)
						{
							if (response == "allies")
							{
								if (game["allies"] == "american")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED",&"PATCH_1_3_AMERICAN");
								else if (game["allies"] == "british")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED",&"PATCH_1_3_BRITISH");
								else if (game["allies"] == "russian")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED",&"PATCH_1_3_RUSSIAN");
							}
							else
								self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED",&"PATCH_1_3_GERMAN");
							break;
						}
					}
					else
					{
						if (response == "allies")
							otherteam = "axis";
						else
							otherteam = "allies";
						if (((players[response] + 1) - players[otherteam]) > level.teambalance)
						{
							if (response == "allies")
							{
								if (game["allies"] == "american")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED2",&"PATCH_1_3_AMERICAN");
								else if (game["allies"] == "british")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED2",&"PATCH_1_3_BRITISH");
								else if (game["allies"] == "russian")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED2",&"PATCH_1_3_RUSSIAN");
							}
							else
							{
								if (game["allies"] == "american")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_AXIS",&"PATCH_1_3_AMERICAN");
								else if (game["allies"] == "british")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_AXIS",&"PATCH_1_3_BRITISH");
								else if (game["allies"] == "russian")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_AXIS",&"PATCH_1_3_RUSSIAN");
								}
							break;
						}
					}
				}
				skipbalancecheck = undefined;
				//------------------------------------------------------------------------------


				if(response != self.pers["team"] && self.sessionstate == "playing")
					self suicide(); // edit added to kill player switching teams
				// Boco: If they are changing teams from axis to allied, or allied to axis.
				// Boco: Will not run if player just joined..
				picked_team = response;

				self.pers["team"] = response;
				self.pers["teamTime"] = (gettime() / 1000);
				self.pers["weapon"] = undefined;
				self.pers["weapon1"] = undefined;
				self.pers["weapon2"] = undefined;
				self.pers["spawnweapon"] = undefined;
				self.pers["savedmodel"] = undefined;

				// Boco: Limited Lives
				self setLives();
				
				// update spectator permissions immediately on change of team
				maps\mp\gametypes\_teams::SetSpectatePermissions();

				// if there are weapons the user can select then open the weapon menu
				if ( maps\mp\gametypes\_teams::isweaponavailable(self.pers["team"]) )
				{
					if(self.pers["team"] == "allies")
					{
						menu = game["menu_weapon_allies"];
					}
					else
					{
						menu = game["menu_weapon_axis"];
					}
				
					self setClientCvar("ui_weapontab", "1");
					self openMenu(menu);
				}
				else
				{
					self setClientCvar("ui_weapontab", "0");
					self menu_spawn("none");
				}
		
				self setClientCvar("g_scriptMainMenu", menu);
				break;

			case "spectator":
				if(self.pers["team"] != "spectator")
				{
					  
					self.pers["team"] = "spectator";
					self.pers["teamTime"] = 1000000;
					self.pers["weapon"] = undefined;
					self.pers["weapon1"] = undefined;
					self.pers["weapon2"] = undefined;
					self.pers["spawnweapon"] = undefined;
					self.pers["savedmodel"] = undefined;

					self.sessionteam = "spectator";
					self.sessionstate = "spectator";
					self setClientCvar("g_scriptMainMenu", game["menu_team"]);
					self setClientCvar("ui_weapontab", "0");
					spawnSpectator();
				}
				break;

			case "weapon":
				if(self.pers["team"] == "allies")
					self openMenu(game["menu_weapon_allies"]);
				else if(self.pers["team"] == "axis")
					self openMenu(game["menu_weapon_axis"]);
				break;

			case "viewmap":
				self openMenu(game["menu_viewmap"]);
				break;
			
			case "callvote":
				self openMenu(game["menu_callvote"]);
				break;
			}
		}		
		else if(menu == game["menu_weapon_allies"] || menu == game["menu_weapon_axis"])
		{
			if(response == "team")
			{
				self openMenu(game["menu_team"]);
				continue;
			}
			else if(response == "viewmap")
			{
				self openMenu(game["menu_viewmap"]);
				continue;
			}
			else if(response == "callvote")
			{
				self openMenu(game["menu_callvote"]);
				continue;
			}

			if(!isdefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis"))
				continue;

			weapon = self maps\mp\gametypes\_teams::restrict(response);

			if(weapon == "restricted")
			{
				self openMenu(menu);
				continue;
			}
			
			self.pers["selectedweapon"] = weapon;

			if(isdefined(self.pers["weapon"]) && self.pers["weapon"] == weapon && !isdefined(self.pers["weapon1"]))
				continue;

			menu_spawn(weapon);
		}
		else if(menu == game["menu_viewmap"])
		{
			switch(response)
			{
			case "team":
				self openMenu(game["menu_team"]);
				break;
				
			case "weapon":
				if(self.pers["team"] == "allies")
					self openMenu(game["menu_weapon_allies"]);
				else if(self.pers["team"] == "axis")
					self openMenu(game["menu_weapon_axis"]);
				break;

			case "callvote":
				self openMenu(game["menu_callvote"]);
				break;
			}
		}
		else if(menu == game["menu_callvote"])
		{
			switch(response)
			{
			case "team":
				self openMenu(game["menu_team"]);
				break;
				
			case "weapon":
				if(self.pers["team"] == "allies")
					self openMenu(game["menu_weapon_allies"]);
				else if(self.pers["team"] == "axis")
					self openMenu(game["menu_weapon_axis"]);
				break;

			case "viewmap":
				self openMenu(game["menu_viewmap"]);
				break;
			}
		}
		else if(menu == game["menu_quickcommands"])
			maps\mp\gametypes\_teams::quickcommands(response);
		else if(menu == game["menu_quickstatements"])
			maps\mp\gametypes\_teams::quickstatements(response);
		else if(menu == game["menu_quickresponses"])
			maps\mp\gametypes\_teams::quickresponses(response);
		else if(menu == game["menu_quickvehicles"])
			maps\mp\gametypes\_teams::quickvehicles(response);
		else if(menu == game["menu_quickrequests"])
			maps\mp\gametypes\_teams::quickrequests(response);
	}
}

Callback_PlayerDisconnect()
{

///// Added by AWE ////////
	self maps\mp\gametypes\_awe::PlayerDisconnect();
///////////////////////////

	iprintln(&"MPSCRIPT_DISCONNECTED", self);

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	if ( !isDefined(self.lives) )
		self.lives = 0;

	if(game["matchstarted"])
		level thread updateTeamStatus();
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc)
{
	if(self.sessionteam == "spectator")
		return;

	// Boco: anti-doorblock code.
//	if ( self module\_mod_b_doorblock::main( eAttacker, sMeansOfDeath ) ) return;

	// dont take damage during ceasefire mode
	// but still take damage from ambient damage (water, minefields, fire)
	if(level.ceasefire && sMeansOfDeath != "MOD_EXPLOSIVE" && sMeansOfDeath != "MOD_WATER")
		return;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
//	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
///////////// Changed by AWE ///////////////
			if( level.friendlyfire == "1" && !isdefined(eAttacker.pers["awe_teamkiller"]) && !(sMeansOfDeath == "MOD_CRUSH_TANK" || sMeansOfDeath == "MOD_CRUSH_JEEP") )
////////////////////////////////////////////
			{
				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

//////////// Added by AWE /////////////////////
				eAttacker maps\mp\gametypes\_awe::teamdamage(self, iDamage);
///////////////////////////////////////////////

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);

////////////// Added by AWE //////////////////
				self maps\mp\gametypes\_awe::DoPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
//////////////////////////////////////////////

			}
////////////// Changed by AWE /////////
			else if(level.friendlyfire == "0" && !(sMeansOfDeath == "MOD_CRUSH_TANK" || sMeansOfDeath == "MOD_CRUSH_JEEP"))
///////////////////////////////////////
			{
				return;
			}
////////////// Changed by AWE /////////
			else if( (level.friendlyfire == "2" && !(sMeansOfDeath == "MOD_CRUSH_TANK" || sMeansOfDeath == "MOD_CRUSH_JEEP")) || isdefined(eAttacker.pers["awe_teamkiller"]))
///////////////////////////////////////
			{
				eAttacker.friendlydamage = true;
		
				iDamage = iDamage * .5;

				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
				eAttacker.friendlydamage = undefined;
				
				friendly = true;
			}
////////////// Changed by AWE /////////
			else if(level.friendlyfire == "3" || sMeansOfDeath == "MOD_CRUSH_TANK" || sMeansOfDeath == "MOD_CRUSH_JEEP" )
///////////////////////////////////////
			{
				eAttacker.friendlydamage = true;

				iDamage = iDamage * .5;

				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
				eAttacker.friendlydamage = undefined;
				
				friendly = true;
			}
		}
		else
		{
			// Make sure at least one point of damage is done
			if(iDamage < 1)
				iDamage = 1;

			self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);

////////////// Added by AWE //////////////////
			self maps\mp\gametypes\_awe::DoPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
//////////////////////////////////////////////

		}
	}

	self maps\mp\gametypes\_shellshock_gmi::DoShellShock(sWeapon, sMeansOfDeath, sHitLoc, iDamage);

	// Do debug print if it's enabled
	if(getCvarInt("g_debugDamage"))
	{
		println("client:" + self getEntityNumber() + " health:" + self.health +
			" damage:" + iDamage + " hitLoc:" + sHitLoc);
	}

	if(self.sessionstate != "dead")
	{
		lpselfnum = self getEntityNumber();
		lpselfguid = self getGuid();
		lpselfname = self.name;
		lpselfteam = self.pers["team"];
		lpattackerteam = "";

		if(isPlayer(eAttacker))
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackguid = self getGuid();
			lpattackname = eAttacker.name;
			lpattackerteam = eAttacker.pers["team"];
		}
		else
		{
			lpattacknum = -1;
			lpattackguid = "";
			lpattackname = "";
			lpattackerteam = "world";
		}

		if(isDefined(friendly))
		{  
			lpattacknum = lpselfnum;
			lpattackname = lpselfname;
			lpattackguid = lpselfguid;
		}

		//logPrint("D;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc)
{
	self endon("spawned");

	if(self.sessionteam == "spectator" || self.sessionstate == "spectator")
		return;

/////////// Added by AWE ///////////
	self thread maps\mp\gametypes\_awe::PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);
////////////////////////////////////

	// Boco: Initialize our variables so developer cvar doesn't yell at me.  :(
	if ( !isdefined(self.suicide) )
		self.suicide = false;
	if ( !isdefined(self.death_noBody) )
		self.death_noBody = false;

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// if this is a melee kill from a binocular then make sure they know that they are a loser
	if(sMeansOfDeath == "MOD_MELEE" && (sWeapon == "binoculars_artillery_mp" || sWeapon == "binoculars_mp") )
	{
		sMeansOfDeath = "MOD_MELEE_BINOCULARS";
	}
	
	// if this is a kill from the artillery binocs change the icon
	if(sMeansOfDeath != "MOD_MELEE_BINOCULARS" && sWeapon == "binoculars_artillery_mp" )
		sMeansOfDeath = "MOD_ARTILLERY";

	// send out an obituary message to all clients about the kill
////////// Removed by AWE ///////
//	if ( self.suicide == false )
//		obituary(self, attacker, sWeapon, sMeansOfDeath);
/////////////////////////////////

	self.spawned = undefined;
	self.sessionstate = "dead";
	self.statusicon = "gfx/hud/hud@status_dead.tga";
	self.headicon = "";

	if ( self.suicide == false && !isDefined(self.autobalance) )
	{
		self.pers["deaths"]++;
		self.deaths = self.pers["deaths"];
		self.lives--;
	}

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	lpselfname = self.name;
	lpselfteam = self.pers["team"];
	lpattackerteam = "";

	attackerNum = -1;

	doKillcam = false;
	if(isPlayer(attacker))
	{
		if ( self.suicide == false && !isDefined(self.autobalance) )
		{
			if(attacker == self) // killed himself
			{
				doKillcam = false;

				attacker.pers["score"]--;
				attacker.score = attacker.pers["score"];

				if(isdefined(attacker.reflectdamage))
					clientAnnouncement(attacker, &"MPSCRIPT_FRIENDLY_FIRE_WILL_NOT"); 

				if ( getcvarint("b_rsd_suicide_penalty") > 0 )
					self.addQueueTime += getcvarint("b_rsd_suicide_penalty");
			}
			else
			{
				attackerNum = attacker getEntityNumber();
				doKillcam = true;

				if(self.pers["team"] == attacker.pers["team"]) // killed by a friendly
				{
					attacker.pers["score"]--;
					attacker.score = attacker.pers["score"];
					attacker.tk++;
					attacker checkTKLimit();
				}
				else
				{
					attacker.pers["score"]++;
					attacker.score = attacker.pers["score"];
				}
			}
		}

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		if ( self.suicide == false )
		{
			doKillcam = false;

			self.pers["score"]--;
			self.score = self.pers["score"];

			lpattacknum = -1;
			lpattackguid = "";
			lpattackname = "";
			lpattackerteam = "world";
		}
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

///////// Changed by AWE /////////
	if(!isDefined(self.autobalance))
//////////////////////////////////
	{
		// Boco: Drop health.
		if ( getcvarint("scr_drophealth") == 1 )
			self dropHealth();

//////// Removed by AWE //////////////////////
//		// Make the player drop his weapon "isweaponavailable()" may have to call this from _teams
//		self dropItem(self getcurrentweapon());
//
//			if ( getcvarfloat("b_corpse_timeout") == 0 )
//		{
//			body = self cloneplayer();
//		}
//		else
//			level thread bodyTimeout( self, getcvarfloat("b_corpse_timeout") );
///////////////////////////////////////////////
	}

	updateTeamStatus();


	// Boco: If lives are 0, then set status icon to crossbones.
	if ( self.lives <= 0 && level.player_lives[self.pers["team"]] > 0 )
		self.statusicon = "gfx/hud/death_suicide.tga";

	if ( self.suicide == false && !isDefined(self.autobalance) )
	{
		delay = 2;	// Delay the player becoming a spectator till after he's done dying
		wait delay;	// ?? Also required for Callback_PlayerKilled to complete before killcam can execute
	}

	self.death_noBody = false;
	self.suicide = false;
	self.autobalance = undefined;
	//self.notspawned = 50; //edit make them spawn tdm now
	maps\mp\gametypes\_teams::SetSpectatePermissions();

	enableCam = getcvarint("scr_killcam");
	if(doKillcam && !level.roundended && enableCam == 1)
	{
		self thread killcam(attackerNum, delay);
		self thread joinQueue(self, true);
	} else {
		self thread joinQueue(self);
	}
}

dropHealth()
{
//// Added by AWE ////
	if(isdefined(self.awe_nohealthpack))
		return;
	self.awe_nohealthpack = true;
//////////////////////

	if(isdefined(level.healthqueue[level.healthqueuecurrent]))
		level.healthqueue[level.healthqueuecurrent] delete();
	
	level.healthqueue[level.healthqueuecurrent] = spawn("item_health", self.origin + (0, 0, 1));
	level.healthqueue[level.healthqueuecurrent].angles = (0, randomint(360), 0);

	level.healthqueuecurrent++;
	
	if(level.healthqueuecurrent >= 16)
		level.healthqueuecurrent = 0;
}

// Boco: If constantly TK, start reflecting damage.
checkTKLimit()
{
	if ( getcvarint("b_player_tklimit") > 0 )
	{
		if ( self.tk >= getcvarint("b_player_tklimit") && self.tk_reflect == false )
		{
			self iprintlnbold("^1BAD TK'ER");
			tkmode = getcvarint("b_player_tkmode");
			if ( tkmode == 0 )
				self.tk_reflect = true;
			else if ( tkmode == 1 )
			{
				self.tk_reflect = false;
				self.addPQueueTime += getcvarint("b_player_tk_spawnPenalty");
			}
		}
	}
}

// Boco: Draw the hud that shows how many lives you have left.
limitedLife_HUD()
{
	self thread LimitedLife_HUD_cleanup();

	self endon( "llHUD_close" );
	RSD_LIVES = game["RSD_Text"][1];

	for (;;)
	{
		if ( self.lives <= 0 )
		{
			if ( isDefined(self.hud_lives_icon) )
				self.hud_lives_icon destroy();
			if ( isDefined(self.hud_lives) )
				self.hud_lives destroy();

			wait 2;
			continue;
		}

		if(!isdefined(self.hud_lives_icon))
		{
			self.hud_lives_icon = newClientHudElem(self);				
			self.hud_lives_icon.alignX = "left";
			self.hud_lives_icon.alignY = "top";
			self.hud_lives_icon.x = 100;
			self.hud_lives_icon.y = 403;
			self.hud_lives_icon.alpha = 0.7;
			self.hud_lives_icon.sort = 0;
			self.hud_lives_icon setShader("gfx/hud/hud@status_dead.tga", 32, 32);
		}

		if (!isdefined(self.hud_lives))
		{
			self.hud_lives = newClientHudElem(self);
			self.hud_lives.alignX = "left";
			self.hud_lives.alignY = "middle";
			self.hud_lives.x = 130;
			self.hud_lives.y = 420;
			self.hud_lives.alpha = 0.65;
			if ( isDefined(RSD_LIVES) )
				self.hud_lives.label = RSD_LIVES;
		}
		self.hud_lives setValue( self.lives );
		wait 1;
	}
}

limitedLife_HUD_cleanup()
{
	self waittill( "llHUD_close" );
	if ( isDefined(self.hud_lives_icon) )
		self.hud_lives_icon destroy();
	if ( isDefined(self.hud_lives) )
		self.hud_lives destroy();
}

limitedLife_RoundRatio()
{
	if ( level.roundended == false )
	{
		// Boco: Must multiply by 1.0 to force the variables to float so they divide correctly.
		max_time = 1.0 * (level.roundlength * 60);
		current_time = 1.0 * ( max_time - ((getTime() - level.starttime) / 1000) );
		self.lives = (int)(level.player_lives[self.pers["team"]] * (current_time / max_time ));
	}
	else
		self.lives = 0;
}

/////////// Removed by AWE ///////
/*
bodyTimeout( player, time )
{
	body = player cloneplayer();

	wait time;
	sinkBody( body );
	body delete();
}

sinkBody( body, time, distance )
{
	if ( !isDefined(time) )
		time = 1;

	if ( !isDefined(distance) )
		distance = 20;

	distance_interval = distance / (time / 0.05);
	for ( i = 0; i < distance; i += distance_interval )
	{
		body.origin = body.origin - ( 0, 0, distance_interval );
		wait 0.05;
	}
}
*/
///////////////////////////////////

// ----------------------------------------------------------------------------------
//	menu_spawn
//
// 		called from the player connect to spawn the player
// ----------------------------------------------------------------------------------
menu_spawn(weapon)
{
	if(!game["matchstarted"])
	{
		if(isDefined(self.pers["weapon"]))
		{
	 		self.pers["weapon"] = weapon;

			// setup all the weapons
			self maps\mp\gametypes\_loadout_gmi::PlayerSpawnLoadout();
	 		self setWeaponSlotWeapon("primary", weapon);
			self switchToWeapon(weapon);
		}
		else
		{
			self.pers["weapon"] = weapon;
			self.spawned = undefined;
			spawnPlayer();
			self thread printJoinedTeam(self.pers["team"]);
			level checkMatchStart();
		}
	}
	else if(!level.roundstarted && !self.usedweapons)
	{
	 	if(isDefined(self.pers["weapon"]))
	 	{
	 		self.pers["weapon"] = weapon;
			// setup all the weapons
			self maps\mp\gametypes\_loadout_gmi::PlayerSpawnLoadout();
	 		self setWeaponSlotWeapon("primary", weapon);
			self switchToWeapon(weapon);
		}
	 	else
		{			 	
			self.pers["weapon"] = weapon;
			if(!level.exist[self.pers["team"]])
			{
				self.spawned = undefined;
				spawnPlayer();
				self thread printJoinedTeam(self.pers["team"]);
				level checkMatchStart();
			}
			else
			{
				spawnPlayer();
				self thread printJoinedTeam(self.pers["team"]);
			}
		}
	}
	else
	{
		//if(isDefined(self.pers["weapon"]))
			//self.oldweapon = self.pers["weapon"];

		self.pers["weapon"] = weapon;
		self.sessionteam = self.pers["team"];

		if(self.sessionstate != "playing")
			self.statusicon = "gfx/hud/hud@status_dead.tga";
	
		if(self.pers["team"] == "allies")
			otherteam = "axis";
		else if(self.pers["team"] == "axis")
			otherteam = "allies";
			
		// if joining a team that has no opponents, just spawn
		if(!level.didexist[otherteam] && !level.roundended)
		{
			self.spawned = undefined;
			spawnPlayer();
			self thread printJoinedTeam(self.pers["team"]);
		}				
		else if(!level.didexist[self.pers["team"]] && !level.roundended)
		{
			self.spawned = undefined;
			spawnPlayer();
			self thread printJoinedTeam(self.pers["team"]);
			level checkMatchStart();
		}
		else
		{
			weaponname = maps\mp\gametypes\_teams::getWeaponName(self.pers["weapon"]);

			if(self.pers["team"] == "allies")
			{
				if(maps\mp\gametypes\_teams::useAn(self.pers["weapon"]))
					self iprintln("You will spawn Allied with a ", weaponname);
				else
					self iprintln("You will spawn Allied with a ", weaponname);
			}
			// edit fixed spawn next round text
			else if(self.pers["team"] == "axis")
			{
				if(maps\mp\gametypes\_teams::useAn(self.pers["weapon"]))
					self iprintln("You will spawn Axis with a ", weaponname);
				else
					self iprintln("You will spawn Axis with a ", weaponname);
			}
		}
	}
	self thread maps\mp\gametypes\_teams::SetSpectatePermissions();
	if (isdefined (self.autobalance_notify))
		self.autobalance_notify destroy();
}

spawnPlayer()
{
	self notify("spawned");

	resettimeout();

	self.sessionteam = self.pers["team"];
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.reflectdamage = undefined;

	self.death_noBody = false;
	self.suicide = false;
	// Boco: Don't let them cheat by joining a team with lots of lives then switching to one with not a lot of lives.
	if ( self.lives > level.player_lives[self.pers["team"]] )
	{
		self.lives = level.player_lives[self.pers["team"]];
		if ( self.lives == 0 )
			self notify( "llHUD_close" );
	}

	if(isdefined(self.spawned))
		return;

	if ( self.lives <= 0 && level.player_lives[self.pers["team"]] > 0 )
	{
		spawnSpectator( undefined, undefined, true );
		return;
	}

	self.sessionstate = "playing";

	// Boco: RSD spawnpoints.
	if(self.pers["team"] == "allies")
		spawnpointname = "mp_" + game["map_ent_name"] + "_spawn_allied";
	else
		spawnpointname = "mp_" + game["map_ent_name"] + "_spawn_axis";

	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	if(isdefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");


	self.spawned = true;
	self.statusicon = "";

	// Boco: Set our health up.
	self.maxhealth = getcvarint("b_player_health");
	self.health = self.maxhealth;

	updateTeamStatus();

	if(!isdefined(self.pers["score"]))
		self.pers["score"] = 0;
	self.score = self.pers["score"];

	self.pers["rank"] = maps\mp\gametypes\_rank_gmi::DetermineBattleRank(self);
	self.rank = self.pers["rank"];

	if(!isdefined(self.pers["deaths"]))
		self.pers["deaths"] = 0;
	self.deaths = self.pers["deaths"];
	
	if(!isdefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	// setup all the weapons
	self maps\mp\gametypes\_loadout_gmi::PlayerSpawnLoadout();

	self.usedweapons = false;
	thread maps\mp\gametypes\_teams::watchWeaponUsage();

	// Boco: Custom objective text.
	if(self.pers["team"] == game["attackers"])
		self setClientCvar( "cg_objectiveText", game["obj_text"]["attackers"] );
	else if(self.pers["team"] == game["defenders"])
		self setClientCvar( "cg_objectiveText", game["obj_text"]["defenders"] );

	if(level.drawfriend)
	{
		if(level.battlerank)
		{
			self.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self);
			self.headicon = maps\mp\gametypes\_rank_gmi::GetRankHeadIcon(self);
			self.headiconteam = self.pers["team"];
		}
		else
		{
			if(self.pers["team"] == "allies")
			{
				self.headicon = game["headicon_allies"];
				self.headiconteam = "allies";
			}
			else
			{
				self.headicon = game["headicon_axis"];
				self.headiconteam = "axis";
			}
		}
	}
	else if(level.battlerank)
	{
		self.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self);
	}	

	// setup the hud rank indicator
	self thread maps\mp\gametypes\_rank_gmi::RankHudInit();

//////////// Added by AWE /////////////////////
	self maps\mp\gametypes\_awe::spawnPlayer();
///////////////////////////////////////////////

}

spawnSpectator(origin, angles)    //, keepTeam) edit out keepTeam
{
	self notify("spawned");

	resettimeout();

	if ( !isDefined(keepTeam) )
		keepTeam = false;

	if ( keepTeam == false )
	{
		self.sessionteam = "spectator";
		self.pers["team"] = "spectator";
	}

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.reflectdamage = undefined;

	if(self.pers["team"] == "spectator")
		self.statusicon = "";

	maps\mp\gametypes\_teams::SetSpectatePermissions();

	if(isdefined(origin) && isdefined(angles))
		self spawn(origin, angles);
	else
	{
		// Boco: RSD spawnpoints.
 		spawnpointname = "mp_" + game["map_ent_name"] + "_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

		if(isdefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	updateTeamStatus();

	self.usedweapons = false;
		self thread joinQueue(self); // edit added to join the game late?

	objtext = "^1RSD version ^7" + game["mod_version"] + " ^1- www.iwnation.com/Hosted/Boco/index.html\n^7Attackers: " + game["attackers"] + " - Defenders: " + game["defenders"];
	self setClientCvar("cg_objectiveText", objtext);
}

spawnIntermission()
{
	self notify("spawned");
	
	resettimeout();

	self.sessionstate = "intermission";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.reflectdamage = undefined;

	// Boco: RSD spawnpoints.
	spawnpointname = "mp_" + game["map_ent_name"] + "_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	if(isdefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
}

// Boco: Parent = level
// Boco: Functions that control the reinforcement queue.
joinQueue(player, killcam)
{
	self endon("spawned");

	if ( !isDefined(killcam) )
		killcam = false;

	// Boco: Set the player state to spectator.  joinQueue is only called when you die, so this makes forceSpectator work right.
	if ( killcam == false )
	{
		self.sessionstate = "spectator";
		self.spectatorclient = 0;
	}

	// Boco: If the player is already in the queue, stop.
	if ( isdefined(player.joinQueue) )
		return;

//	// Boco: Clan iO forceSpectator
//	if ( !isDefined(self.killcam) || killcam == false )
//		self thread forceSpectator();

	if ( player.lives <= 0 && level.player_lives[self.pers["team"]] > 0 )
	{
	self iprintlnbold("You have no lives left");
  	return;
	}
 	maps\mp\gametypes\_teams::SetSpectatePermissions(); // edit so spectator works right?
	// Boco: Mark the player that he is in the queue.
	player.joinQueue = true;
	// Boco: Find the time 'till reinforced.
	additionalTime = player.addQueueTime; 
	permTime = player.addPQueueTime;
		
	if ( self.pers["team"] == "allies" )
		self.queueTime_timer = permTime + additionalTime + level.queueTime_allies - (((getTime() - level.starttime) / 1000) % level.queueTime_allies);
	else
		self.queueTime_timer = permTime + additionalTime + level.queueTime_axis - (((getTime() - level.starttime) / 1000) % level.queueTime_axis);

	// Boco: Create the HUD elements.
	if ( !isdefined(self.respawn_bar_timer) )
	{
		self.respawn_bar_timer = newClientHudElem(self);
		self.respawn_bar_timer.archived = false;
		self.respawn_bar_timer.x = 0;
		self.respawn_bar_timer.y = 31;
		self.respawn_bar_timer.alpha = 0.5;
		self.respawn_bar_timer setShader("black", 189, 20);
	}
	if ( !isdefined(self.respawn_text_timer) )
	{
		self.respawn_text_timer = newClientHudElem(self);
		self.respawn_text_timer.archived = false;
		self.respawn_text_timer.x = 20;
		self.respawn_text_timer.y = 40;
		self.respawn_text_timer.alignX = "center";
		self.respawn_text_timer.alignY = "middle";
		self.respawn_text_timer.sort = 1;
	}
	self.respawn_text_timer setTimer(self.queueTime_timer);

	if(!isdefined(self.respawn_title))
	{
		self.respawn_title = newClientHudElem(self);
		self.respawn_title.archived = false;
		self.respawn_title.x = 40;
		self.respawn_title.y = 40;
		self.respawn_title.alignX = "left";
		self.respawn_title.alignY = "middle";
		self.respawn_text_timer.sort = 1;
	}
	RSD_QUEUE_TEXT = game["RSD_Text"][0];
	if ( isDefined(RSD_QUEUE_TEXT) )
		self.respawn_title setText(RSD_QUEUE_TEXT);

	// Boco: Create the support threads.
	self thread joinQueue_timer(player);
	self thread joinQueue_spawn(player);
	self waittill("queue_timeout");
	self joinQueue_cleanup(player);

	// Boco: If killcam is still running, pause until it finishes.
	if ( getcvarint("scr_killcam") == 1 )
		if ( isdefined(self.killcam) )
			self waittill("end_killcam");

	// Boco: Queue is over, spawn the player.
	player.joinQueue = undefined;
	player.spawned = undefined; // edit add it here

	if(isDefined(self.pers["weapon"]))
		spawnPlayer();
		else
		self thread joinQueue(self);

}

// Boco: Wait for the queue time then stop the queue functions.
joinQueue_timer(player)
{
	self endon("spawned");
	wait( self.queueTime_timer );
	self notify("queue_timeout");
}

// Boco: Remove the queue HUD.
joinQueue_cleanup(player)
{
	if(isdefined(self.respawn_bar_timer))
		self.respawn_bar_timer destroy();
	if(isdefined(self.respawn_text_timer))
		self.respawn_text_timer destroy();
	if(isdefined(self.respawn_title))
		self.respawn_title destroy();
	player.joinQueue = undefined;
}

// Boco: If the player spawns, close the queue HUD.
joinQueue_spawn(player)
{
	self endon("queue_timeout");
	self waittill("spawned");
	joinQueue_cleanup(player);
}

killcam(attackerNum, delay)
{
	self endon("spawned");

	// killcam
	if(attackerNum < 0)
		return;

	self.sessionstate = "spectator";
	self.spectatorclient = attackerNum;
	self.archivetime = delay + 7;

	maps\mp\gametypes\_teams::SetKillcamSpectatePermissions();

	// Boco: Moved to make sure this is set to true before joinQueue calls.
	self.killcam = true;

	// wait till the next server frame to allow code a chance to update archivetime if it needs trimming
	wait 0.05;

	if(self.archivetime <= delay)
	{
		self.spectatorclient = -1;
		self.archivetime = 0;

		maps\mp\gametypes\_teams::SetSpectatePermissions();
		return;
	}

	if(!isdefined(self.kc_topbar))
	{
		self.kc_topbar = newClientHudElem(self);
		self.kc_topbar.archived = false;
		self.kc_topbar.x = 0;
		self.kc_topbar.y = 0;
		self.kc_topbar.alpha = 0.5;
		self.kc_topbar setShader("black", 640, 112);
	}

	if(!isdefined(self.kc_bottombar))
	{
		self.kc_bottombar = newClientHudElem(self);
		self.kc_bottombar.archived = false;
		self.kc_bottombar.x = 0;
		self.kc_bottombar.y = 368;
		self.kc_bottombar.alpha = 0.5;
		self.kc_bottombar setShader("black", 640, 112);
	}

	if(!isdefined(self.kc_title))
	{
		self.kc_title = newClientHudElem(self);
		self.kc_title.archived = false;
		self.kc_title.x = 320;
		self.kc_title.y = 40;
		self.kc_title.alignX = "center";
		self.kc_title.alignY = "middle";
		self.kc_title.sort = 1; // force to draw after the bars
		self.kc_title.fontScale = 3.5;
	}
	self.kc_title setText(&"MPSCRIPT_KILLCAM");

	if(!isdefined(self.kc_skiptext))
	{
		self.kc_skiptext = newClientHudElem(self);
		self.kc_skiptext.archived = false;
		self.kc_skiptext.x = 320;
		self.kc_skiptext.y = 70;
		self.kc_skiptext.alignX = "center";
		self.kc_skiptext.alignY = "middle";
		self.kc_skiptext.sort = 1; // force to draw after the bars
	}
	self.kc_skiptext setText(&"MPSCRIPT_PRESS_ACTIVATE_TO_SKIP");

	if(!isdefined(self.kc_timer))
	{
		self.kc_timer = newClientHudElem(self);
		self.kc_timer.archived = false;
		self.kc_timer.x = 320;
		self.kc_timer.y = 428;
		self.kc_timer.alignX = "center";
		self.kc_timer.alignY = "middle";
		self.kc_timer.fontScale = 3.5;
		self.kc_timer.sort = 1;
	}
	self.kc_timer setTenthsTimer(self.archivetime - delay);

	self thread spawnedKillcamCleanup();
	self thread waitSkipKillcamButton();
	self thread waitKillcamTime();
	self waittill("end_killcam");

	self removeKillcamElements();

	self.spectatorclient = -1;
	self.archivetime = 0;
	self.killcam = undefined;

	maps\mp\gametypes\_teams::SetSpectatePermissions();
}

waitKillcamTime()
{
	self endon("end_killcam");
	
	wait(self.archivetime - 0.05);
	self notify("end_killcam");
}

waitSkipKillcamButton()
{
	self endon("end_killcam");
	
	while(self useButtonPressed())
		wait .05;

	while(!(self useButtonPressed()))
		wait .05;

	self notify("end_killcam");	
}

removeKillcamElements()
{
	if(isdefined(self.kc_topbar))
		self.kc_topbar destroy();
	if(isdefined(self.kc_bottombar))
		self.kc_bottombar destroy();
	if(isdefined(self.kc_title))
		self.kc_title destroy();
	if(isdefined(self.kc_skiptext))
		self.kc_skiptext destroy();
	if(isdefined(self.kc_timer))
		self.kc_timer destroy();
}

spawnedKillcamCleanup()
{
	self endon("end_killcam");

	self waittill("spawned");
	self removeKillcamElements();
}

startGame()
{
	axisDead = false;
	alliesDead = false;
	level.starttime = getTime();

	thread startRound();
	for(;;)
	{
		// Boco: Check for balanced teams.
		if ( level.roundstarted == true )
		{
			if ( level.player_lives["axis"] > 0 )
				axisDead = checkTeamDead("axis");
			if ( level.player_lives["allies"] > 0 )
				alliesDead = checkTeamDead("allies");
			if ( axisDead == true && alliesDead == true )
				level thread endRound("draw");
			else if ( axisDead == true )
				level thread endRound("allies");
			else if ( alliesDead == true )
				level thread endRound("axis");
		}
		wait 1;
	}
}

checkTeamDead( team, nolives )
{
	dead = 0;
	numonteam = 0;

	players = getentarray( "player", "classname" );

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!isdefined(player.pers["team"]) || player.pers["team"] == "spectator" || player.pers["team"] != team)
			continue;

		// Boco: Sanity check.
		if ( !isDefined(player.lives) )
			player.lives = 0;

		if ( isDefined(nolives) && nolives == true )
		{
			if ( player.sessionstate == "spectator" || player.sessionstate == "dead" )
				dead++;
		}
		else
		{
			if ( player.lives <= 0 && level.player_lives[player.pers["team"]] > 0 )
				dead++;
		}
		numonteam++;
	}

	if ( dead >= numonteam )
		return true;
	else
		return false;
}

startRound()
{
	thread maps\mp\gametypes\_teams::sayMoveIn();

	level.clock = newHudElem();
	level.clock.x = 320;
	level.clock.y = 460;
	level.clock.alignX = "center";
	level.clock.alignY = "middle";
	level.clock.font = "bigfixed";
	level.clock setTimer(level.roundlength * 60);

	if(game["matchstarted"])
	{
		level.clock.color = (0, 1, 0);

		if((level.roundlength * 60) > level.graceperiod)
		{
			wait level.graceperiod;

			level notify("round_started");
			level.roundstarted = true;
			level.clock.color = (1, 1, 1);

			// Players on a team but without a weapon show as dead since they can not get in this round
			players = getentarray("player", "classname");
			for(i = 0; i < players.size; i++)
			{
				player = players[i];

				if(player.sessionteam != "spectator" && !isdefined(player.pers["weapon"]))
					player.statusicon = "gfx/hud/hud@status_dead.tga";
			}

			wait ((level.roundlength * 60) - level.graceperiod);
		}
		else
			wait (level.roundlength * 60);
	}
	else	
	{
		level.clock.color = (1, 1, 1);
		wait (level.roundlength * 60);
	}
	
	if(level.roundended)
		return;

	if ( getcvarint( "b_rsd_bomb_suddenDeath" ) == 1 && level.obj_destroyed == 1 )
	{
		if ( level.bombplanted[0] == true )
		{
			level waittill( "bomb_event", event );
			if ( event == "explode" )
			{
				level thread endRound( game["attackers"] );
				return;
			}
		}
		else if ( level.bombplanted[1] == true )
		{
			level waittill( "bomb_event2", event );
			if ( event == "explode" )
			{
				level thread endRound( game["attackers"] );
				return;
			}
		}
	}
	if ( getcvarint( "b_rsd_bomb_suddenDeath" ) == 1 && level.obj_destroyed == 0 ) //edit added for one bomb
	{
		if ( level.bombplanted[0] == true )
		{
			level waittill( "bomb_event", event );
			if ( event == "explode" )
			{
				level thread endRound( game["attackers"] );
				return;
			}
		}
		else if ( level.bombplanted[1] == true )
		{
			level waittill( "bomb_event2", event );
			if ( event == "explode" )
			{
				level thread endRound( game["attackers"] );
				return;
			}
		}
	}

	if ( level.didexist[game["attackers"]] == false || level.didexist[game["defenders"]] == false )
	{
		announcement(&"SD_TIMEHASEXPIRED");
		level thread endRound("draw");
		return;
	}

	announcement(&"SD_TIMEHASEXPIRED");
	level thread endRound(game["defenders"]);
}

checkMatchStart()
{
	oldvalue["teams"] = level.exist["teams"];
	level.exist["teams"] = false;

	// If teams currently exist
	if(level.exist["allies"] && level.exist["axis"])
		level.exist["teams"] = true;

	// If teams previously did not exist and now they do
	if(!oldvalue["teams"] && level.exist["teams"] && !level.roundended)
	{
		if(!game["matchstarted"])
		{
			announcement(&"SD_MATCHSTARTING");
			level thread endRound("reset");
		}
		else
		{
			announcement(&"SD_MATCHRESUMING");
			level thread endRound("draw");
		}

		return;
	}
}

resetScores()
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		player.pers["score"] = 0;
		player.pers["deaths"] = 0;
	}

	game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);
	game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);
}

endRound(roundwinner)
{
	if(level.roundended)
		return;
	level.roundended = true;
	//self.notspawned = 20; // edit make player spawn s&d again
	// Boco: Reset the objective count.
	level.obj_destroyed = 0;

	if(roundwinner == "allies")
	{
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			players[i] playLocalSound("MP_announcer_allies_win");
			players[i] iprintln(&"MPSCRIPT_ALLIES_WIN");
		}
	}
	else if(roundwinner == "axis")
	{
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			players[i] playLocalSound("MP_announcer_axis_win");
			players[i] iprintln(&"MPSCRIPT_AXIS_WIN");
		}
	}
	else if(roundwinner == "draw")
	{
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			players[i] playLocalSound("MP_announcer_round_draw");
			players[i] iprintln(&"MPSCRIPT_THE_GAME_IS_A_TIE");
		}
	}

	wait 5;

	winners = "";
	losers = "";
	
	if(roundwinner == "allies")
	{
		game["alliedscore"]++;
		setTeamScore("allies", game["alliedscore"]);
		
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			lpGuid = players[i] getGuid();
			if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
				winners = (winners + ";" + lpGuid + ";" + players[i].name);
			else if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
				losers = (losers + ";" + lpGuid + ";" + players[i].name);
		}
		logPrint("W;allies" + winners + "\n");
		logPrint("L;axis" + losers + "\n");
	}
	else if(roundwinner == "axis")
	{
		game["axisscore"]++;
		setTeamScore("axis", game["axisscore"]);

		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			lpGuid = players[i] getGuid();
			if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
				winners = (winners + ";" + lpGuid + ";" + players[i].name);
			else if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
				losers = (losers + ";" + lpGuid + ";" + players[i].name);
		}
		logPrint("W;axis" + winners + "\n");
		logPrint("L;allies" + losers + "\n");
	}
	
	if(game["matchstarted"])
	{
		game["roundsplayed"]++;
		checkRoundLimit();
	}

	if(!game["matchstarted"] && roundwinner == "reset")
	{
		game["matchstarted"] = true;
		thread resetScores();
		game["roundsplayed"] = 0;
	}


	// Boco: Give everybody max lives again.
	players = getentarray("player", "classname");
	for ( i = 0; i < players.size; i++ )
	{
		players[i] unlink();
		players[i] enableWeapon();
		if ( players[i].pers["team"] != "spectator" && level.player_lives[players[i].pers["team"]] > 0 )
			players[i].lives = level.player_lives[players[i].pers["team"]];
	}

	if(level.mapended)
		return;
	level.mapended = true;

////////// Added by AWE //////////	
	maps\mp\gametypes\_awe::swapteams();
//////////////////////////////////

	map_restart(true);
}

endMap()
{

////// Added by AWE ///////////
	maps\mp\gametypes\_awe::endMap();
/////////////////////////////////

	game["state"] = "intermission";
	level notify("intermission");

	if(game["alliedscore"] == game["axisscore"])
		text = &"MPSCRIPT_THE_GAME_IS_A_TIE";
	else if(game["alliedscore"] > game["axisscore"])
		text = &"MPSCRIPT_ALLIES_WIN";
	else
		text = &"MPSCRIPT_AXIS_WIN";

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		player closeMenu();
		player setClientCvar("g_scriptMainMenu", "main");
		player setClientCvar("cg_objectiveText", text);
		player spawnIntermission();
	}

	wait 10;
	exitLevel(false);
}

checkRoundLimit()
{
	if(level.roundlimit <= 0)
		return;
	
	if(game["roundsplayed"] < level.roundlimit)
		return;
	
	if(level.mapended)
		return;
	level.mapended = true;

	println("Round limit reached!");
	iprintln(&"MPSCRIPT_ROUND_LIMIT_REACHED");
	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		roundlimit = getcvarint("scr_rsd_roundlimit");
		if(level.roundlimit != roundlimit)
		{
			level.roundlimit = roundlimit;
			setCvar("ui_sd_roundlimit", level.roundlimit);

			if(game["matchstarted"])
				checkRoundLimit();
		}

		roundlength = getcvarfloat("scr_rsd_roundlength");
		if(roundlength > 10)
			setcvar("scr_rsd_roundlength", "10");

		graceperiod = getcvarfloat("scr_rsd_graceperiod");
		if(graceperiod > 60)
			setcvar("scr_rsd_graceperiod", "60");

		drawfriend = getcvarfloat("scr_drawfriend");
		if(level.drawfriend != drawfriend)
		{
			level.drawfriend = drawfriend;
			
			if(level.drawfriend)
			{
				// for all living players, show the appropriate headicon
				players = getentarray("player", "classname");
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					
					if(isdefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
					{
						if(player.pers["team"] == "allies")
						{
							player.headicon = game["headicon_allies"];
							player.headiconteam = "allies";
						}
						else
						{
							player.headicon = game["headicon_axis"];
							player.headiconteam = "axis";
						}
					}
				}
			}
			else
			{
				players = getentarray("player", "classname");
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					
					if(isdefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
						player.headicon = "";
				}
			}
		}

		killcam = getCvarInt("scr_killcam");
		if (level.killcam != killcam)
		{
			level.killcam = getCvarInt("scr_killcam");
			if(level.killcam >= 1)
				setarchive(true);
			else
				setarchive(false);
		}
		
		freelook = getCvarInt("scr_freelook");
		if (level.allowfreelook != freelook)
		{
			level.allowfreelook = getCvarInt("scr_freelook");
			level maps\mp\gametypes\_teams::UpdateSpectatePermissions();
		}
		
		enemyspectate = getCvarInt("scr_spectateenemy");
		if (level.allowenemyspectate != enemyspectate)
		{
			level.allowenemyspectate = getCvarInt("scr_spectateenemy");
			level maps\mp\gametypes\_teams::UpdateSpectatePermissions();
		}
		
		teambalance = getCvarInt("scr_teambalance");
		if (level.teambalance != teambalance)
		{
			level.teambalance = getCvarInt("scr_teambalance");
			if (level.teambalance > 0)
			{
				level thread maps\mp\gametypes\_teams::TeamBalance_Check();
				level.teambalancetimer = 0;
			}
		}

		if (level.teambalance > 0)
		{
			level.teambalancetimer++;
			if (level.teambalancetimer >= 60)
			{
				level thread maps\mp\gametypes\_teams::TeamBalance_Check();
				level.teambalancetimer = 0;
			}
		}
		wait 1;
	}
}

updateTeamStatus()
{
	wait 0;	// Required for Callback_PlayerDisconnect to complete before updateTeamStatus can execute
	
	resettimeout();

	oldvalue["allies"] = level.exist["allies"];
	oldvalue["axis"] = level.exist["axis"];
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;
	
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		
		if(isdefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
			level.exist[player.pers["team"]]++;
	}

	if(level.exist["allies"])
		level.didexist["allies"] = true;
	if(level.exist["axis"])
		level.didexist["axis"] = true;

	if(level.roundended)
		return;
}

// Boco: Heavily redid the bombzones to allow multiple bomb planting and defusing, and to not end the game on bomb explosion.
bombzones(bombnumber)
{
	level.barsize = 288;
	level.planttime[bombnumber] = getcvarint("b_rsd_bomb_arm");			// seconds to plant a bomb
	level.defusetime[bombnumber] = getcvarint("b_rsd_bomb_defuse");		// seconds to defuse a bomb

	bombtrigger = getent("bombtrigger", "targetname");
	bombtrigger maps\mp\_utility::triggerOff();

	level.bombplanted[bombnumber] = false;

	bombzone_A = getent("bombzone_A", "targetname");
	bombzone_B = getent("bombzone_B", "targetname");
	if ( bombnumber == 0 )
	{
		bombzone_A thread bombzone_think(bombzone_B, bombnumber);

		wait 1;	// TEMP: without this one of the objective icon is the default. Carl says we're overflowing something.
		objective_add(0, "current", bombzone_A.origin, "gfx/hud/hud@objectiveA.tga");
	} else {
		bombzone_B thread bombzone_think(bombzone_A, bombnumber);

		wait 1;	// TEMP: without this one of the objective icon is the default. Carl says we're overflowing something.
		objective_add(1, "current", bombzone_B.origin, "gfx/hud/hud@objectiveB.tga");
	}
}

bombzone_think(bombzone_other, bombnumber)
{
	level endon("round_ended");

	level.barincrement = (level.barsize / (20.0 * level.planttime[bombnumber]));
	self.progresstime = 0;

	for(;;)
	{
		self waittill("trigger", other);

		if(isdefined(bombzone_other.planting))
		{
			if ( bombzone_other.planting == true && (getcvarint("b_rsd_obj_destroyBoth") == 0) )
			{
				if(isdefined(other.planticon))
					other.planticon destroy();

				continue;
			}
		}

		if ( (getcvarint("b_rsd_obj_destroyBoth") == 0) && (level.bombplanted[1 - bombnumber] == true) )
		{
			if(isdefined(other.planticon))
				other.planticon destroy();
			continue;
		}

		if(isPlayer(other) && (other.pers["team"] == game["attackers"]) && other isOnGround())
		{
			if(!isdefined(other.planticon))
			{
				other.planticon = newClientHudElem(other);				
				other.planticon.alignX = "center";
				other.planticon.alignY = "middle";
				other.planticon.x = 320;
				other.planticon.y = 345;
				other.planticon setShader("ui_mp/assets/hud@plantbomb.tga", 64, 64);			
			}

			while(other istouching(self) && isalive(other) && other useButtonPressed())
			{
				if ( bombnumber == 0 )
					other notify("kill_check_bombzone");
				else
					other notify("kill_check_bombzone2");
				
				self.planting = true;

				if(!isdefined(other.progressbackground))
				{
					other.progressbackground = newClientHudElem(other);				
					other.progressbackground.alignX = "center";
					other.progressbackground.alignY = "middle";
					other.progressbackground.x = 320;
					other.progressbackground.y = 385;
					other.progressbackground.alpha = 0.5;
				}
				other.progressbackground setShader("black", (level.barsize + 4), 12);		

				if(!isdefined(other.progressbar))
				{
					other.progressbar = newClientHudElem(other);				
					other.progressbar.alignX = "left";
					other.progressbar.alignY = "middle";
					other.progressbar.x = (320 - (level.barsize / 2.0));
					other.progressbar.y = 385;
				}
				other.progressbar setShader("white", 0, 8);
				other.progressbar scaleOverTime(level.planttime[bombnumber] - self.progresstime, level.barsize, 8);

				other playsound("MP_bomb_plant");
				other linkTo(self);
				other disableWeapon();

				// Boco: Check for attack key pressed if settings specify it.
				while( isalive(other) && other useButtonPressed() && (self.progresstime < level.planttime[bombnumber]) )
				{
					self.progresstime += 0.05;
					wait 0.05;
				}

				if(isDefined(other.progressbackground))
					other.progressbackground destroy();
				if(isDefined(other.progressbar))
					other.progressbar destroy();

				if(self.progresstime >= level.planttime[bombnumber])
				{
					if(isDefined(other.planticon))
						other.planticon destroy();

					other enableWeapon();

					// Boco: Give points for arming a dynomite.
					other.pers["score"] += getcvarint("b_rsd_bomb_arm_points");
					other.score = other.pers["score"];

					// Boco: Unlink the player from the obj.
					other unlink();

					self.planting = false;
					level.bombplanted[bombnumber] = true;
					self.progresstime = 0;

					objective_delete(bombnumber);

					plant = other maps\mp\_utility::getPlant();
					level.bombmodel[bombnumber] = spawn("script_model", plant.origin);
					level.bombmodel[bombnumber].angles = plant.angles;
					level.bombmodel[bombnumber] setmodel("xmodel/mp_bomb1_defuse");
					level.bombmodel[bombnumber] playSound("Explo_plant_no_tick");
					level.bombexploder[bombnumber] = self.script_noteworthy;

					objective_add(bombnumber, "current", level.bombmodel[bombnumber].origin, "gfx/hud/hud@bombplanted.tga");

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + game["attackers"] + ";" + other.name + ";" + "bomb_plant" + "\n");

					announcement(&"SD_EXPLOSIVESPLANTED");

					bombtrigger = getent("bombtrigger", "targetname");
					players = getentarray("player", "classname");
					for(i = 0; i < players.size; i++)
						players[i] playLocalSound("MP_announcer_bomb_planted");

					bombtrigger thread bomb_think(bombzone_other, bombnumber);
					bombtrigger thread bomb_countdown(self, bombnumber, other);
					bombtrigger thread bomb_think_ploc(bombzone_other, bombnumber);

					return;	//TEMP, script should stop after the wait .05
				}
				else
				{
					//other.progressbackground destroy();
					//other.progressbar destroy();
					other unlink();
					other enableWeapon();
				}

				wait .05;
			}
			
			self.planting = undefined;
			other thread check_bombzone(self, bombnumber);
		}
	}
}

check_bombzone(trigger, bombnumber)
{
	// Boco: Meh, each bomb has its own notifys.
	if ( bombnumber == 0 )
	{
		self notify("kill_check_bombzone");
		self endon("kill_check_bombzone");
	} else {
		self notify("kill_check_bombzone2");
		self endon("kill_check_bombzone2");
	}
	level endon("round_ended");

	while(isdefined(trigger) && !isdefined(trigger.planting) && self istouching(trigger) && isalive(self))
		wait 0.05;

	if(isdefined(self.planticon))
		self.planticon destroy();
}

bomb_countdown(bombzone, bombnumber, player)
{
	level endon("intermission");

	if ( bombnumber == 0 )
		level endon( "bomb_event_defuse" );
	else
		level endon( "bomb_event2_defuse" );

	level.bombmodel[bombnumber] playLoopSound("bomb_tick");

	countdowntime = getcvarint("b_rsd_bomb_time");
	wait countdowntime;

	// Boco: Give points for blowing up the objective.
	player.pers["score"] += getcvarint("b_rsd_bomb_blow_points");  // Default 6
	player.score = player.pers["score"];

	// bomb timer is up
	objective_delete(bombnumber);

	level.bombexploded[bombnumber] = true;
	level.bombplanted[bombnumber] = false;
	self.progresstime[bombnumber] = 0;

	if ( bombnumber == 0 )
	{
		level notify( "bomb_event", 1 );
		level notify( "bomb_event_explode" );
	}
	else
	{
		level notify( "bomb_event2", 1 );
		level notify( "bomb_event2_explode" );
	}

	// trigger exploder if it exists
	if(isdefined(level.bombexploder[bombnumber]))
		maps\mp\_utility::exploder(level.bombexploder[bombnumber]);

	// explode bomb
	origin = level.bombmodel[bombnumber] getorigin();
	range = 500;
	maxdamage = 2000;
	mindamage = 1000;

	level.bombmodel[bombnumber] stopLoopSound();

	playfx(level._effect["bombexplosion"], origin);
	radiusDamage(origin + (0,0,16), range, maxdamage, mindamage);

	// Boco: If server requires both obj to be destroyed, then check for both before ending the round.
	level.obj_destroyed++;
	if ( getcvarint("b_rsd_obj_destroyBoth") == 1 )
	{
		if ( level.obj_destroyed >= 2 )
			level thread endRound(game["attackers"]);
	} else {
		level thread endRound(game["attackers"]);
	}

	// Boco: Try to stop playSound from spawning random entities!  x_x
	self thread bomb_explosion(bombnumber);
}

bomb_explosion(bombnumber)
{
	level.bombmodel[bombnumber] playSound("explo_metal_rand");
	wait 0.05;
	level.bombmodel[bombnumber] delete();
}

bomb_think_ploc(bombzone_other, bombnumber)
{
	if ( bombnumber == 0 )
		level endon( "bomb_event_explode" );
	else
		level endon( "bomb_event2_explode" );

	for (;;)
	{
		if ( level.bombplanted[bombnumber] == true )
		{
			players = getentarray("player", "classname");
			for(i = 0; i < players.size; i++)
			{
				if ( distance(players[i].origin, level.bombmodel[bombnumber].origin) < 50 )
				{
					self.origin = level.bombmodel[bombnumber].origin;
					break;
				}
			}
		}
		wait 1;
	}
}

bomb_think(bombzone, bombnumber)
{
	if ( bombnumber == 0 )
		level endon( "bomb_event_explode" );
	else
		level endon( "bomb_event2_explode" );

	level.barincrement = (level.barsize / (20.0 * level.defusetime[bombnumber]));
	self.defusing[bombnumber] = false;
	self.progresstime[bombnumber] = 0;

	for(;;)
	{
		self waittill("trigger", other);

		// check for having been triggered by a valid player
		if(isPlayer(other) && (other.pers["team"] == game["defenders"]) && other isOnGround())
		{
			if(!isdefined(other.defuseicon))
			{
				other.defuseicon = newClientHudElem(other);				
				other.defuseicon.alignX = "center";
				other.defuseicon.alignY = "middle";
				other.defuseicon.x = 320;
				other.defuseicon.y = 345;
				other.defuseicon setShader("ui_mp/assets/hud@defusebomb.tga", 64, 64);			
			}

			while(other islookingat(self) && distance(other.origin, level.bombmodel[bombnumber].origin) < 64 && isalive(other) && other useButtonPressed())
			{
				if ( bombnumber == 0 )
					other notify("kill_check_bomb");
				else
					other notify("kill_check_bomb2");

				self.defusing[bombnumber] = true;

				if(!isdefined(other.progressbackground))
				{
					other.progressbackground = newClientHudElem(other);				
					other.progressbackground.alignX = "center";
					other.progressbackground.alignY = "middle";
					other.progressbackground.x = 320;
					other.progressbackground.y = 385;
					other.progressbackground.alpha = 0.5;
				}
				other.progressbackground setShader("black", (level.barsize + 4), 12);		

				if(!isdefined(other.progressbar))
				{
					other.progressbar = newClientHudElem(other);				
					other.progressbar.alignX = "left";
					other.progressbar.alignY = "middle";
					other.progressbar.x = (320 - (level.barsize / 2.0));
					other.progressbar.y = 385;
				}
				other.progressbar setShader("white", 0, 8);			
				other.progressbar scaleOverTime(level.defusetime[bombnumber] - self.progresstime[bombnumber], level.barsize, 8);

				other playsound("MP_bomb_defuse");
				other linkTo(level.bombmodel[bombnumber]);
				other disableWeapon();
				other thread check_bomb_explosion(bombnumber);

				// Boco: Check for attack key pressed if settings specify it.
				while(isalive(other) && other useButtonPressed() && (self.progresstime[bombnumber] < level.defusetime[bombnumber]))
				{
					if ( level.bombexploded[bombnumber] == true )
						break;
					self.progresstime[bombnumber] += 0.05;
					wait 0.05;
				}

				if(isDefined(other.progressbackground))
					other.progressbackground destroy();
				if(isDefined(other.progressbar))
					other.progressbar destroy();

				if((self.progresstime[bombnumber] >= level.defusetime[bombnumber]) && (level.bombexploded[bombnumber] == false))
				{
					if(isDefined(other.defuseicon))
						other.defuseicon destroy();

					other unlink();
					other enableWeapon();
					trigger = undefined;

					// Boco: Once planted, reset progress time.
					self.progresstime[bombnumber] = 0;

					// Boco: Give points for disarming a dynomite.
					other.pers["score"] += getcvarint("b_rsd_bomb_defuse_points");	// default 3
					other.score = other.pers["score"];

					objective_delete(bombnumber);

					if ( bombnumber == 0 )
					{
						level notify( "bomb_event", 0 );
						level notify( "bomb_event_defuse" );
					}
					else
					{
						level notify( "bomb_event2", 0 );
						level notify( "bomb_event2_defuse" );
					}

					// Boco: Stop checking for bomb blow.
					other notify("cbe_stop");

					level.bombmodel[bombnumber] stopLoopSound();
					level.bombmodel[bombnumber] delete();

					announcement(&"SD_EXPLOSIVESDEFUSED");

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + game["defenders"] + ";" + other.name + ";" + "bomb_defuse" + "\n");

					players = getentarray("player", "classname");
					for(i = 0; i < players.size; i++)
						players[i] playLocalSound("MP_announcer_bomb_defused");

					level thread bombzones(bombnumber);

					return;	//TEMP, script should stop after the wait .05
				}
				else
				{
					//other.progressbackground destroy();
					//other.progressbar destroy();
					other notify("cbe_stop");
					other unlink();
					other enableWeapon();
				}
				
				wait .05;
			}
			self.defusing[bombnumber] = false;
			other thread check_bomb(self, bombnumber);
		}
	}
}

check_bomb_explosion(bombnumber)
{
	self endon("cbe_stop");
	for (;;)
	{
		if ( level.bombexploded[bombnumber] == true )
		{
			if( isdefined(self.progressbackground) )
				self.progressbackground destroy();
			if( isdefined(self.progressbar) )
				self.progressbar destroy();
			if ( isdefined(self.defuseicon) )
				self.defuseicon destroy();
		}
		wait 1;
	}
}

check_bomb(trigger, bombnumber)
{
	if ( bombnumber == 0 )
	{
		self notify("kill_check_bomb");
		self endon("kill_check_bomb");
	} else {
		self notify("kill_check_bomb2");
		self endon("kill_check_bomb2");
	}
	
	while(isdefined(trigger) && trigger.defusing[bombnumber] == false && distance(self.origin, trigger.origin) < 50 && self islookingat(trigger) && isalive(self))
		wait 0.05;

	if(isDefined(self.defuseicon))
		self.defuseicon destroy();
}

printJoinedTeam(team)
{
	if(team == "allies")
		iprintln(&"MPSCRIPT_JOINED_ALLIES", self);
	else if(team == "axis")
		iprintln(&"MPSCRIPT_JOINED_AXIS", self);
}

addBotClients()
{
	wait 5;
	
	for(i = 0; i < 2; i++)
	{
		ent[i] = addtestclient();
		wait 0.5;
	
		if(isPlayer(ent[i]))
		{
			if(i & 1)
			{
				ent[i] notify("menuresponse", game["menu_team"], "axis");
				wait 0.5;
				ent[i] notify("menuresponse", game["menu_weapon_axis"], "kar98k_mp");
			}
			else
			{
				ent[i] notify("menuresponse", game["menu_team"], "allies");
				wait 0.5;
				ent[i] notify("menuresponse", game["menu_weapon_allies"], "m1garand_mp");
			}
		}
	}
}


/////////////////////////////////////////
// Project Bell Cvar control function.
/////////////////////////////////////////
cvarBounds( sName, sType, vDefault, vMin, vMax )
{
	if ( isDefined(vDefault) )
		if ( getcvar(sName) == "" )
			setcvar(sName, vDefault);

	if ( !isDefined( sType ) )
		sType = "";

	switch( sType )
	{
		case "":
		case "string":
			return getcvar(sName);
		break;
		case "int":
			if ( isDefined(vMin) )
				if ( getcvarint(sName) < vMin )
					setcvar(sName, vMin);
			if ( isDefined(vMax) )
				if ( getcvarint(sName) > vMax )
					setcvar(sName, vMax);
			return getcvarint(sName);
		break;
		case "float":
			if ( isDefined(vMin) )
				if ( getcvarfloat(sName) < vMin )
					setcvar(sName, vMin);
			if ( isDefined(vMax) )
				if ( getcvarfloat(sName) > vMax )
					setcvar(sName, vMax);
			return getcvarfloat(sName);
		break;
	}
	return undefined;
}

printSetting( text, cvar, flags, mode )
{
	if ( !isDefined(text) )
		return;
	if ( !isDefined(flags) )
		flags = 0;

	switch ( flags )
	{
		case 0:
			printtext = text + getcvar(cvar);
			break;
		case 1:
			if ( getcvar(cvar) == "" )
				return;
			printtext = text + getcvar(cvar);
			break;
		case 2:
			if ( !isDefined(mode) )
				return;
			if ( getcvar(cvar) == "" )
				return;

			if ( mode == "tf" )
			{
				modeText[0] = "False"; modeText[1] = "True";
			}
			else if ( mode == "ed" )
			{
				modeText[0] = "Disabled"; modeText[1] = "Enabled";
			}

			printtext = text + modeText[getcvarint(cvar)];
			break;
	}
	self iprintln( printtext );
}

setLives()
{
	if ( self.given_lives == false )
	{
		self.given_lives = true;
		if ( level.player_lives[self.pers["team"]] > 0 )
		{
			// Boco: isNew is false if your GUID is already stored for this round.
			if ( self.isNew == true )
			{
				// Boco: If conditions are met, give them zero lives.
				if ( getCvarInt("b_limitedlives_lateJoin") == 0 && level.roundstarted == true )
					self.lives = 0;
				else
				{
					self.lives = level.player_lives[self.pers["team"]];
					if ( level.roundstarted == true )
						self limitedLife_RoundRatio();
				}
			}
			else
			{
				// Boco: They got disconnected during the round.
				if ( getCvarInt("b_limitedlives_lateJoin") == 1 )
				{
					self limitedLife_RoundRatio();
				}
				else
					self.lives = 0;
			}
		}
		else
			self.lives = 0;
	}
}




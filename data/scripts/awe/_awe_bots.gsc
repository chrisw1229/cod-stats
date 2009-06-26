addBotClients()
{
	level endon("awe_boot");

	wait 2;

	if(level.awe_debug)
		iprintln(level.awe_allplayers.size + " players found.");

	numbots = 0;
	// Catch & count running bots and start their think threads.
	for(i=0;i<level.awe_allplayers.size;i++)
	{
		if(isdefined(level.awe_allplayers[i]))
		{
			player = level.awe_allplayers[i];
			if(player.name.size==4 || player.name.size==5)
			{
				if(player.name[0] == "b" && player.name[1] == "o" && player.name[2] == "t")
				{
					player thread bot_think();
					numbots++;
				}
			}
		}
	}
	
	for(;;)
	{
		wait 3;

		// Any new bots to add?
		newbots = level.awe_bots - numbots;
	
		// Any new bots to add?
		if(newbots<=0)
			continue;

		for(i = 0; i < newbots; i++)
		{
			bot = addtestclient();
			wait 0.5;
			if(isdefined(bot) && isPlayer(bot))
				bot thread bot_think();
			numbots++;
		}
	}
}

bot_think()
{
	level endon("awe_boot");

	if(level.awe_debug)
		iprintln("Starting think thread for: " + self.name);

	if(getcvar("g_gametype") == "bel" || getcvar("g_gametype") == "mc_bel")
		bel = "_only";
	else
		bel = "";

	if(isPlayer(self))
	{
		for(;;)
		{
			if(!isAlive(self) && self.sessionstate != "playing")
			{
				if(level.awe_debug)
					iprintln(self.name + " is sending menu responses.");

				if(bel == "")
					self notify("menuresponse", game["menu_team"], "autoassign");
				else
					self notify("menuresponse", game["menu_team"], "axis");
				wait 0.5;	

				if(self.pers["team"]=="axis")
				{
					self notify("menuresponse", game["menu_weapon_axis" + bel], "kar98k_mp");
				}
				else
				{
					self notify("menuresponse", game["menu_team"], "allies");
					wait 0.5;
					if(game["allies"] == "russian")
						self notify("menuresponse", game["menu_weapon_allies" + bel], "mosin_nagant_mp");
					else
						self notify("menuresponse", game["menu_weapon_allies" + bel], "springfield_mp");
				}
			}
			wait 10;
		}
	}
}
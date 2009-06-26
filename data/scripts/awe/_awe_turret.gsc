turret_think(num)
{
//////// Added by AWE ////////
	self notify("awe_turret_think");	// Make sure only one thread is running
	self endon("awe_turret_think");
//////////////////////////////

//	self endon("death");  // Removed by AWE

	self waittill("activated",gunner);

//////// Added by AWE ////////
	gunner.awe_usingturret = num;
//////////////////////////////

/////// Changed by AWE /////
	self thread turret_activated_delay(gunner,num);
//////////////////////////////
}

turret_activated_delay(gunner,num) /////// Changed by AWE /////
{
	wait 0.1;	// wait for a dismount to be processed if on same frame

	if(level.awe_turrets[num]["type"] != "misc_ptrs")   ///////// Added by AWE ///////
	{
		overheat_back = newClientHudElem( gunner );
		overheat_back setShader("gfx/hud/hud@vehiclehealth.dds", 128, 7, 1.0, 0.20);
		overheat_back.alignX = "left";
		overheat_back.alignY = "top";
		overheat_back.x = 488+13;
		overheat_back.y = 449;

		overheat = newClientHudElem( gunner );
		overheat setShader("gfx/hud/hud@health_bar.dds", 128, 4);
		overheat.alignX = "left";
		overheat.alignY = "top";
		overheat.x = 488+14;
		overheat.y = 450;

		level thread turret_hud_destroy_think( self, gunner, overheat, overheat_back);
	}	///////// Added by AWE ///////

	// Incase we want to use this else where.
	self.gunner = gunner; 

	if(level.awe_turrets[num]["type"] != "misc_ptrs")	///////// Added by AWE ///////
		self thread turret_hud_overheat_run( gunner, overheat );

/////// Changed by AWE /////
	self thread turret_dismount(num);
//////////////////////////////
}

turret_hud_destroy_think(turret, gunner, overheat, overheat_back)
{
	gunner waittill("stop_turret_hud");

	if (!isValidPlayer( gunner ))
	{
		// already disconnected, hudelem's must have been destroyed
		return;
	}

	if(isdefined(overheat))	///////// Added by AWE ///////
		overheat destroy();
	if(isdefined(overheat_back))	///////// Added by AWE ///////
		overheat_back destroy();
}

turret_hud_overheat_run(activator, overheat)
{
//	self endon("death");	// Removed by AWE
	activator endon("death");
	activator endon("stop_turret_hud");
	
	minheight = 0;

	max_width = 126;
	
	while(1)
	{
		wait (0.1);
		if ( !isDefined(self) || !isDefined(overheat) )
			break;
		
		heat = self getturretheat();
		overheating = self getturretoverheating();
		
		if ( overheating )
		{
			overheat.color = ( 1.0, 0.0, 0.0);
		}
		else
		{
			overheat.color = ( 1.0, 1.0-heat,1.0-heat);
		}
		
		hud_width = (1.0 - heat) * max_width;
		
		if ( hud_width < 1 )
			hud_width = 1;
			
		overheat setShader("gfx/hud/hud@health_bar.dds", hud_width, 5);
	}
}

turret_dismount(num)/////// Changed by AWE /////
{
	self endon("awe_turret_think");	///////// Added by AWE ///////

	self waittill("deactivated");
	
	self.gunner notify("stop_turret_hud");

	// now restart the thinking for the next user
/////// Changed by AWE /////
	self thread turret_think(num);
//////////////////////////////

//////// Added by AWE ////////
	self.gunner.awe_usingturret = undefined;
//////////////////////////////
}

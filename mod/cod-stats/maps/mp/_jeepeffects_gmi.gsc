//#using_animtree( "panzerIV" );

init( precache )
{
	self.collision_fx_str = "fx/vehicle/vehicle_collision.efx";

	if (precache)
	{
		loadfx("fx/explosions/vehicles/t34_mp_n/burn_smoke.efx");
		loadfx("fx/explosions/vehicles/t34_mp_n/1st_exp_v2.efx");
		loadfx("fx/explosions/vehicles/t34_mp_n/2nd_exp.efx");
		loadfx("fx/map_mp/mp_smoke_vehicle_damage.efx");
		loadfx( self.collision_fx_str );
	}
	
	if (self.vehicletype == "willyjeep_MP" || self.vehicletype == "willyjeep_mp")
	{
		if (self.model == "xmodel/v_us_lnd_willysjeep")
			self.deathmodel = "xmodel/v_us_lnd_willysjeep_d";
		else if (self.model == "xmodel/v_us_lnd_willysjeep_snow")
			self.deathmodel = "xmodel/v_us_lnd_willysjeep_d";
		else
			self.deathmodel = "xmodel/v_us_lnd_willysjeep_d";
		
		if (precache)
			precachevehicle("willyjeep_mp");
	}
	else if (self.vehicletype == "horch_mp" )
	{
		if (self.model == "xmodel/mp_vehicle_horch1a")
			self.deathmodel = "xmodel/mp_vehicle_horch1a_damaged";
		else
			self.deathmodel = "xmodel/mp_vehicle_horch1a_damaged";
		
		if (precache)
			precachevehicle("horch_mp");
	}
	else if (self.vehicletype == "gaz67b_mp" )
	{
		if (self.model == "xmodel/mp_vehicle_gaz67b")
			self.deathmodel = "xmodel/mp_vehicle_gaz67b_damaged";
		else
			self.deathmodel = "xmodel/mp_vehicle_gaz67b_damaged";
		
		if (precache)
			precachevehicle("gaz67b_mp");
	}
	
	if (!isdefined( self.deathmodel ))
	{
		println("vehicle unknown, check that vehicle type and model are both lowercase");
		return;
	}

	if (precache)
	{
		precachemodel(self.deathmodel);
	}

	// start the collision thinker
	self thread collision_thread();
}

collision_thread()
{
	self endon("death");
	
	self.collision_fx = loadfx( self.collision_fx_str );
	
	while (1)
	{
		self waittill("vehicle_collision", pos, dir );
		
		// spawn the collision fx
		playfx( self.collision_fx, pos, dir );
	}
	
}

damaged_smoke()
{
	self endon ("death");
	
	smokefx = loadfx("fx/map_mp/mp_smoke_vehicle_damage.efx");
	
	while (1)
	{
		self waittill ("damage");
	
		if (!isDefined( self.hud_height ))
		{
			// wait for the hud to initialize
			wait 0.5;
		}
		else
		{
			if (self.hud_height < 0.35*self.hud_maxheight)
			{
				// it's now smoking, so stay in this section until death
				while (1)
				{
					if (!isDefined( smoke_ent ))
					{
						// spawn the smoke_ent
						smoke_ent = PlayLoopedFX( smokefx, 0.3, self.origin, 2048 );
						// kill it once we're dead
						self thread damaged_smoke_stop( smoke_ent );
					}
					else
					{
						// update the position
						smoke_ent.origin = self.origin;
					}
					
					wait 0.1;
				}
			}
		}
	}
}

damaged_smoke_stop(smoke_ent)
{
	self waittill("death");
	
	smoke_ent delete();
}

jeepPlayFXUntilEvent( fxId, eventStr )
{
	// spawn the smoke_ent
	smoke_ent = PlayLoopedFX( fxId, 1, self.origin );
	
	self waittill( eventStr );
	
	smoke_ent delete();
}

death()
{

	self.deathfx    = loadfx ("fx/explosions/vehicles/t34_mp_n/burn_smoke.efx");
	self.explode1fx = loadfx( "fx/explosions/vehicles/t34_mp_n/1st_exp_v2.efx" );
	self.explode2fx = loadfx( "fx/explosions/vehicles/t34_mp_n/2nd_exp.efx" );
	self waittill( "death" );

    // Log the vehicle death
    lpvehicleguid = self.tank_num;
    lpvehiclenum = "-1";
    lpvehicleteam = self.tank_team;
    lpvehiclename = self.vehicletype;
    lpdamage = "10000";
    lpdamagetype = "MOD_EXPLOSIVE";
    if (isDefined(self.deepwater) && self.deepwater) {
      lpdamagetype = "MOD_WATER";
    }
    lphitloc = "none";
    lpvehicleorigin = self.origin;
    lpvehicleangle = self.angles[1];
    lpvehiclestance = "none";

    if (isValidPlayer(self.last_attacker)) {
        lpplayer = self.last_attacker;
        if (isValidPlayer(self.last_inflictor)) {
            lpplayer = self.last_inflictor;
        }
    }
    if (isDefined(lpplayer)) {
        lpplayerguid = lpplayer getGuid();
        lpplayernum = lpplayer getEntityNumber();
        lpplayerteam = lpplayer.pers["team"];
        lpplayername = lpplayer.name;
        lpplayerweapon = "none";
        lpplayerorigin = lpplayer.origin;
        lpplayerangle = lpplayer.angles[1];
        lpplayerstance = lpplayer getStance();
    } else {
        lpplayerguid = "";
        lpplayernum = "-1";
        lpplayerteam = "world";
        lpplayername = "";
        lpplayerweapon = "none";
        lpplayerorigin = (0, 0, 0);
        lpplayerangle = "0";
        lpplayerstance = "none";
    }
    logPrint("K;" + lpvehicleguid + ";" + lpvehiclenum + ";" + lpvehicleteam + ";" + lpvehiclename + ";" + lpplayerguid + ";" + lpplayernum + ";" + lpplayerteam + ";" + lpplayername + ";" + lpplayerweapon + ";" + lpdamage + ";" + lpdamagetype + ";" + lphitloc + ";" + lpvehicleorigin[0] + "," + lpvehicleorigin[1] + "," + lpvehicleorigin[2] + ";" + lpplayerorigin[0] + "," + lpplayerorigin[1] + "," + lpplayerorigin[2] + ";" + lpvehicleangle + ";" + lpplayerangle + ";" + lpvehiclestance + ";" + lpplayerstance + "\n");

	if (!isdefined(self.deepwater))
	{
		if (isdefined( self.deathmodel ))
			self setmodel( self.deathmodel );
			
		// 1st explode			
		playfxontag( self.explode1fx, self, "tag_origin" );		
		earthquake( 0.25, 3, self.origin, 1050 );
		self thread playLoopSoundOnTag("distantfire");
		self thread jeepPlayFXUntilEvent( self.deathfx, "allow_explode" );

		self waittill( "allow_explode" );
		println( "recieved allow_explode death");
	
		self notify ("stop sound distantfire");

		// 2nd explode			
		playfxontag( self.explode2fx, self, "tag_origin" );

		// wait for effects to finish
		wait 0.5;
	
		// this will keep the jeep from blocking the radius damage
		self setcontents(0);
		radiusDamage ( (self.origin[0],self.origin[1],self.origin[2]+25), 300, 80, 0);
	}
	else
	{
		println("water death");
		self waittill( "allow_explode" );
	}
	
	// we currently need to remove it straight away, in case it's sitting in the place of the spawning in tank
	self delete();
}

playLoopSoundOnTag(alias, tag)
{
	org = spawn ("script_origin",(0,0,0));
	if (isdefined (tag))
		org linkto (self, tag, (0,0,0), (0,0,0));
	else
	{
		org.origin = self.origin;
		org.angles = self.angles;
		org linkto (self);
	}
	org playloopsound (alias);
	self waittill ("stop sound " + alias);
	org stoploopsound (alias);
	org delete();
}
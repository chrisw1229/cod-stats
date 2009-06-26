main()
{
	precacheFX();
	effects = getentarray ("effect","targetname");
	thread spawnWorldFX(effects);
}

precacheFX()
{
// SMOKE ================================//
	level._effect["gigantor"]			= loadfx ("fx/map_mp/mp_gigantor_night.efx");
//	level._effect["tanksmoke"]			= loadfx ("fx/map_mp/mp_smoke_tank_slow_long_high.efx");

// FIRE ================================//
	level._effect["car_fire"]			= loadfx ("fx/map_mp/mp_smoke_car_slow_long_high.efx");
	level._effect["distant_fire2tall_smoke"]	= loadfx ("fx/map_mp/mp_building_fire_big_2ts.efx");
	level._effect["distant_fire2"]			= loadfx ("fx/map_mp/mp_building_fire_big_2.efx");

// Atmosphere ==========================//
	//level._effect["distant_light"]			= loadfx ("fx/map_mp/mp_mortar_mz.efx");
    	//level._effect["antiair_tracers"]		= loadfx ("fx/atmosphere/antiair_tracers.efx");
    	//level._effect["searchlight"]			= loadfx ("fx/atmosphere/v_light_searchlight.efx");

// Water ===============================//
    	level._effect["sewer_foam"]			= loadfx ("fx/map_mp/mp_sewer_foam.efx");

}

spawnWorldFX(effects)
{
	if (isdefined (effects))
	{
		for (i=0;i<effects.size;i++)
		{
//			if (effects[i].script_noteworthy == "tanksmoke")
//			wait(0.3);
//				level thread maps\mp\_fx::loopfx(effects[i].script_noteworthy, effects[i].origin, 5);
//			}
			if (effects[i].script_noteworthy == "gigantor")
			{
			wait(0.3);
				level thread maps\mp\_fx::loopfx(effects[i].script_noteworthy, effects[i].origin, 5);
			}
			else if (effects[i].script_noteworthy == "car_fire")
			{
			wait(0.3);
				level thread maps\mp\_fx::loopfx(effects[i].script_noteworthy, effects[i].origin, 5);
			}
		}
	}

 //SMOKE ==============================//
	wait(.1);
	level thread maps\mp\_fx::loopfxthread ( "distant_fire2tall_smoke", 		(680,-4880,-40), 5);

 //FIRE ===============================//
	wait(.1);
	level thread maps\mp\_fx::loopfxthread ( "distant_fire2", 			(680,-4880,-40), 5);
 
 //WATER ===============================//
	wait(.1);
	level thread maps\mp\_fx::loopfxthread ( "sewer_foam", 				(-2677, 3139, 61), 5);
}


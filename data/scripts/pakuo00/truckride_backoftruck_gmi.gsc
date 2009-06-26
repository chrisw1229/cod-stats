#using_animtree ("generic_human");

hackangle()
{
	for (;;)
	{
		enemyAngle = animscripts\utility::GetYawToEnemy();
		self OrientMode ("face angle", enemyAngle);
		wait .05;
	}
}

main( )
{
	self.orgsuppressionwaittime = self.suppressionwait;
	self.suppressionwait = 1.5;
	self.totalshotcount = 0;//  count the amount of shots for accuracy ramping
	self.truckstarttime = gettime();
	println("anim1");
	self endon("killanimscript");
	self endon("outoftruck");
	animscripts\utility::initialize("l33t truckride combat");
    	self trackScriptState( "l33t truckride combat", "becauseisaidso" );
    	thread hackangle();
	self OrientMode("face enemy");
	if(randomint(100) >50)
		nextaction = ("stand");
	else
		nextaction = ("crouch");

	for ( ;; )
	{
		// Nothing below will work if our gun is completely empty.
		// If I'm wounded, I fight differently until I recover
		if (self.anim_pose == "wounded")
		{
			self animscripts\wounded::SubState_WoundedGetup("pose be wounded");
		}
	        self [[anim.SetPoseMovement]]("","stop");
	        
	        animscripts\combat::Reload(0);
//	        if ( canShootstand && canStand &&
//	             ( !canShootCrouch || !canCrouch || ( dist < anim.standRangeSq )) )

		if(nextaction == ("stand"))
		{
			timer = gettime()+randomint(1500)+1500;
			while(timer > gettime())
		        {

			        self [[anim.SetPoseMovement]]("stand","stop");
				self animscripts\aim::aim();
				if(distance(self.enemy.origin, self.origin)>1000)
				{
					wait(.05);
					continue;
				}
				success = ShootVolley(0,undefined, self.enemy,nextaction);
		//			if (!success)
		//				self interruptPoint();	// We couldn't shoot for some reason, so now would be a good time to run for cover.
				nextaction = ("crouch");

		        }
		}
		else if(nextaction == ("crouch"))
		{
		        timer = gettime()+randomint(1000)+1000;
		        while(timer > gettime())
		        {
				/#[[anim.println]]("ExposedCombat - Crouched combat");#/
				self [[anim.SetPoseMovement]]("crouch","stop");

				self animscripts\aim::aim();
				if(distance(self.enemy.origin, self.origin)>1000)
				{
					wait(.05);
					continue;
				}
				
				success = ShootVolley(0,undefined, self.enemy, nextaction );
				if (success==0)
					continue;
				else if (success == 2)
					break;
				nextaction = ("stand");
		        }

		}
	}
}


ShootVolley(completeLastShot, forceShoot, posOverrideEntity, nextaction )
{
	self animscripts\utility::AddToDebugString(" Csva");
	/#[[anim.println]]("Entering combat::ShootVolley");#/
	if (!isDefined(forceShoot))
	{
		forceShoot = "dontForceShoot";
	}
	self animscripts\shared::PutGunInHand("right");
	if (self.anim_pose == "stand")
	{
		anim_autofire = %stand_shoot_auto;
		anim_semiautofire = %stand_shoot;
		anim_boltfire = %stand_shoot;
	}
	else // assume crouch
	{
		anim_autofire = %crouch_shoot_auto;
		anim_semiautofire = %crouch_shoot;
		anim_boltfire = %crouch_shoot;
	}

 	// Make sure the aim and shoot animations are ready to play
	self setanimknob(%shoot, 1, .15, 1);

	if(isdefined(level.vehiclegroupcontrol["maxoffset"][self.script_vehiclegroup]))
		maxoffset = level.vehiclegroupcontrol["maxoffset"][self.script_vehiclegroup];  
	else
		maxoffset = 203;  
	if(isdefined(level.vehiclegroupcontrol["shotramp"][self.script_vehiclegroup]))
		shotramp = level.vehiclegroupcontrol["shotramp"][self.script_vehiclegroup]; 
	else
		shotramp = 20000;  
	if(isdefined(level.vehiclegroupcontrol["zerooffset"][self.script_vehiclegroup]))
		zerooffset = level.vehiclegroupcontrol["zerooffset"][self.script_vehiclegroup]; 
	else
		zerooffset = 48;  
	
	zerooffsethalfed = zerooffset/2;	
	self animscripts\utility::AddToDebugString(" Csvb");

	xdir = randomint(2);
	ydir = randomint(2);

	if(xdir == 2)
		xdir = -1;
	if(ydir == 2)
		ydir = -1;
		
	if (animscripts\weaponList::usingAutomaticWeapon())
	{
		self animscripts\face::SetIdleFace(anim.autofireface);
		self setflaggedanimknob("animdone", anim_autofire, 1, .15, 0);
		wait 0.20;
		animRate = animscripts\weaponList::autoShootAnimRate();
		self setFlaggedAnimKnobRestart("shootdone", anim_autofire, 1, .05, animRate);
		numShots = randomint(8) + 6;
		enemyAngle = animscripts\utility::AbsYawToEnemy();
		/#[[anim.locSpam]]("c16a");#/
		for (i = 0; (i<numShots && self.bulletsInClip>0 && enemyAngle<20); i ++)
		{
			self waittillmatch ("shootdone", "fire");
			self.totalshotcount++;
			timeaccumulated = gettime()-self.truckstarttime;
			if(timeaccumulated > shotramp)
			{
				xoffset = randomint(zerooffset)-zerooffsethalfed;
				yoffset = randomint(zerooffset)-zerooffsethalfed;
				zoffset = randomint(zerooffset)-zerooffsethalfed;			
			}
			else
			{
				multiplier = (float)maxoffset-((float)maxoffset*timeaccumulated/(float)shotramp);
				xoffset = xdir* multiplier;
				yoffset = ydir*	multiplier;
				zoffset = multiplier;
				self.totalshotcount++;				
			}
			if ( isDefined ( posOverrideEntity ) )
			{
				if (isSentient(posOverrideEntity))
				{
					pos = posOverrideEntity.origin + (xoffset,yoffset,64+zoffset);
					
				}
				else
				{
					pos = posOverrideEntity.origin;
				}
				if(self canshoot( self gettagorigin("tag_flash"), pos ) && !(self issuppressed()))
					self shoot ( 1 , pos);
				else if (nextaction == "crouch")
					return 2;
			}
			else
			{
				self shoot();
				iprintlnbold("somebody's using their own ai");
			}
			self.bulletsInClip --;
			enemyAngle = animscripts\utility::AbsYawToEnemy();
		}
		if (completeLastShot)
			wait animscripts\weaponList::waitAfterShot();
		self notify ("stopautofireFace");
	}
	else if (animscripts\weaponList::usingSemiAutoWeapon())
	{
		self animscripts\face::SetIdleFace(anim.aimface);

		self setanimknob(anim_semiautofire, 1, .15, 0);
		wait 0.2;

		rand = randomint(2) + 2;
		for (i = 0; (i<rand && self.bulletsInClip>0); i ++)
		{
			self setFlaggedAnimKnobRestart("shootdone", anim_semiautofire, 1, 0, 1);
			timeaccumulated = gettime()-self.truckstarttime;
			if(timeaccumulated > shotramp)
			{
				xoffset = randomint(zerooffset)-zerooffsethalfed;
				yoffset = randomint(zerooffset)-zerooffsethalfed;
				zoffset = randomint(zerooffset)-zerooffsethalfed;			
			}
			else
			{
				multiplier = (float)maxoffset-((float)maxoffset*timeaccumulated/(float)shotramp);
				xoffset = xdir* multiplier;
				yoffset = ydir*	multiplier;
				zoffset = multiplier;
				self.totalshotcount++;				
			}
			if ( isDefined ( posOverrideEntity ) )
			{
	           	 	self shoot ( 1 , posOverrideEntity.origin + (xoffset,yoffset,64+zoffset));
			}
			else
			{
				self shoot();
				
			}
			self.totalshotcount++;	
			self.bulletsInClip --;
			/#[[anim.locSpam]]("c17.1b");#/
			shootTime = animscripts\weaponList::shootAnimTime();
			quickTime = animscripts\weaponList::waitAfterShot();
			wait quickTime;
			if ( ( (completeLastShot) || (i<rand-1) ) && shootTime>quickTime)
				wait shootTime - quickTime;
		}
	}
	else // Bolt action
	{

//		/#[[anim.println]](" ShootVolley: bolt-action fire, "+self.bulletsInClip+" rounds in clip, enemyDistanceSq is "+self.enemyDistanceSq+".");#/
		animscripts\combat::Rechamber();	// In theory you will almost never need to rechamber here, because you will have done
						// it somewhere smarter, like in cover.
		self animscripts\face::SetIdleFace(anim.aimface);
		// Slowly blend in the first frame of the shoot instead of playing the transition.
		self setanimknob(anim_boltfire, 1, .15, 0);
		// We want panzerfaust guys to wait longer before firing.
		if (self animscripts\utility::weaponAnims() == "panzerfaust")
			wait 0.5;
		else
			wait 0.2;

		self setFlaggedAnimKnobRestart("shootdone", anim_boltfire, 1, 0, 1);
		timeaccumulated = gettime()-self.truckstarttime;
		if(timeaccumulated > shotramp)
		{
			xoffset = randomint(zerooffset)-zerooffsethalfed;
			yoffset = randomint(zerooffset)-zerooffsethalfed;
			zoffset = randomint(zerooffset)-zerooffsethalfed;			
		}
		else
		{
			multiplier = (float)maxoffset-((float)maxoffset*timeaccumulated/(float)shotramp);
			xoffset = xdir* multiplier;
			yoffset = ydir*	multiplier;
			zoffset = multiplier;
			self.totalshotcount++;				
		}
		if ( isDefined ( posOverrideEntity ) )
		{
			self shoot ( 1 , posOverrideEntity.origin + (xoffset,yoffset,64+zoffset));
		}
		else
		{
			iprintlnbold("bolt action no manual");  //won't every happen!
			self shoot();
		}
		self.anim_needsToRechamber = 1;
		self.bulletsInClip --;
		shootTime = animscripts\weaponList::shootAnimTime();
		quickTime = animscripts\weaponList::waitAfterShot();
		wait quickTime;
	}
	self setanim(%shoot,0.0,0.2,1); // cleanup and turn down shoot knob
	/#[[anim.println]]("Leaving combat::ShootVolley");#/
	self animscripts\utility::AddToDebugString(" Csvc");
	return 1;
}


















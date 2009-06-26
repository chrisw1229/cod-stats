#using_animtree ("generic_human");

main()
{
	self endon("killanimscript");

   	self trackScriptState( "Combat Main Switch", "code" );

	animscripts\utility::initialize("combat");
	self animscripts\utility::StartDebugString("CombatStart");
	
	// If I'm wounded, I fight differently until I recover
	if (self.anim_pose == "wounded")
	{
		self animscripts\wounded::combat("pose is wounded");
		[[anim.assert]](self.anim_pose != "wounded");
	}

	[[anim.locSpam]]("c1");


	self.anim_meleeState = "aim";			// Assume we're not pulled back for melee hit when we enter combat


	// Say random shit.
	animscripts\combat_say::generic_combat();

	[[anim.locSpam]]("c2");

	[[anim.locSpam]]("c3");
	
	for (;;)
	{
		canMelee = animscripts\melee::TryMeleeCharge();
		if (canMelee)
		{
			[[anim.locSpam]]("c4a");
			self thread animscripts\melee::MeleeCombat("TryMeleeCharge passed");
         		return;
		}
		else 
		{
			[[anim.locSpam]]("c4b");
			backPedalled = tryBackPedal();
			if (!backPedalled)
			{
				self.enemyDistanceSq = self MyGetEnemySqDist();
				
				usingLMG = animscripts\weaponList::usingLMGWeapon();
				
				if ( isDefined( self.weapon ) )
					usingLMG = self animscripts\weaponList::usingLMGWeapon();
				else
					usingLMG = false;
					
				if (usingLMG)
				{
					[[anim.locSpam]]("c7");
//					println("	combat - enemyDistSq: "+self.enemyDistanceSq+" - doing LMG combat");
					self thread animscripts\lmg_gmi::LMGRangeCombat("Carrying LMG");
					return;
				}
		                else if (self.enemyDistanceSq > anim.proneRangeSq && self isStanceAllowed("prone") ) 
				{
					[[anim.locSpam]]("c5");
		
// MikeD: Removed comments so I can see my comments from the level script. :P
//					println("	combat - enemyDistSq: "+self.enemyDistanceSq+" - doing prone combat");
					self thread animscripts\prone::ProneRangeCombat("Dist > ProneRangeSq");
				   	return;
				}
				else
				{
//					println("	combat - enemyDistSq: "+self.enemyDistanceSq+" - doing general exposed combat");
					[[anim.locSpam]]("c6");
		                   	self thread animscripts\exposedcombat::GeneralExposedCombat("Dist < ProneRangeSq" );
		                    	return;
				}
				
				TryGrenade();
				Reload(0);		// Note: Reload calls an interrupt point if it decides to reload.
				Rechamber();
			}
		}
		[[anim.locSpam]]("c8");
	}
}

EnemiesWithinStandingRange()
{
	enemyDistanceSq = self MyGetEnemySqDist();
	return ( enemyDistanceSq < anim.standRangeSq );
}

MyGetEnemySqDist()
{

    dist = self GetClosestEnemySqDist();
	if (!isDefined(dist))
		dist = 500;	// Arbitrary values for now
    return dist;
}


// Fires a volley of shots.  The completeLastShot flag indicates whether to wait a full 1-shot after the last 
// shot is fired before returning.  If you're firing two volleys in a row, you want to wait, whereas if 
// you're going to do something else next, you want to abort a little early to look more natural.
// TODO CompleteLastShot is a hack and is preventing me from getting the timing of the shots as I want them.  
// It'd be nice to handle recovery from a shot, and aiming for the next shot, a little better.
// Optional forceShoot can be set to "forceShoot" or "dontForceShoot"
ShootVolley(completeLastShot, forceShoot, posOverrideEntity )
{
// MikeD: Removed comments so I can see my comments from the level script. :P
//	println("Entering combat::ShootVolley");
	if (!isDefined(forceShoot))
	{
		forceShoot = "dontForceShoot";
	}
	if ( (self MyGetEnemySqDist()<=anim.meleeRangeSq) && (forceShoot!="forceShoot") )
	{
// MikeD: Removed comments so I can see my comments from the level script. :P
		println("Aborting combat::ShootVolley - enemy within melee range");
		return 0;
	}
	if (self.bulletsInClip <= 0)
	{
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println("Aborting combat::ShootVolley - need to reload");
		return 0;
	}
	if (self animscripts\utility::weaponAnims() == "none")
	{
// MikeD: Removed comments so I can see my comments from the level script. :P
		println ("Trying to shoot when unarmed!");
		return 0;
	}
	if ( !self animscripts\utility::canShootEnemy(posOverrideEntity, false) )	// Don't use a sight check once we're actually in combat.
	{
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println("Aborting combat::ShootVolley - can't hit enemy from here.");
//		return 0;
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

	self thread EyesAtEnemy();

//	[[anim.assert]](self.anim_alertness == "aiming", "ShootVolley called when not aiming");
 	// Make sure the aim and shoot animations are ready to play
	self setanimknob(%shoot, 1, .15, 1);

	// Set up the loop variables.
	self.enemyDistanceSq = self MyGetEnemySqDist();

	if (animscripts\weaponList::usingFlamethrowerWeapon())
	{
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println(" ShootVolley: flamethrower fire, "+self.bulletsInClip+" rounds in mag, enemyDistanceSq is "+self.enemyDistanceSq+".");

		self animscripts\face::SetIdleFace(anim.autofireface);

		// Slowly blend in shoot instead of playing the transition.
		self setflaggedanimknob("animdone", anim_autofire, 1, .15, 0);
		wait 0.20;

		[[anim.locSpam]]("c15a");
		animRate = animscripts\weaponList::autoShootAnimRate();
		self setFlaggedAnimKnobRestart("shootdone", anim_autofire, 1, .05, animRate);
		[[anim.locSpam]]("c16a");
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println("enemyDistanceSq: ",self.enemyDistanceSq,", meleeRangeSq: ",anim.meleeRangeSq);
//		println("forceShoot: ",forceShoot,", animRate: ",animRate);
		numShots = randomint(40) + 80;
		if (self.bulletsInClip < numShots)
			numShots = self.bulletsInClip;
		estimatedTime =  0.1 * (float)numShots / (float)animRate;
		self thread DoFlamethrowerFire("flamethrower fire done", numShots, forceShoot);
		self waittill("flamethrower fire done");
		wait 0.3;
		self notify ("stopautofireFace");
	}
	else if (animscripts\weaponList::usingAutomaticWeapon())
	{
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println(" ShootVolley: automatic fire, "+self.bulletsInClip+" rounds in mag, enemyDistanceSq is "+self.enemyDistanceSq+".");

		self animscripts\face::SetIdleFace(anim.autofireface);

		// Slowly blend in shoot instead of playing the transition.
		self setflaggedanimknob("animdone", anim_autofire, 1, .15, 0);
		wait 0.20;

		[[anim.locSpam]]("c15a");
		animRate = animscripts\weaponList::autoShootAnimRate();
		self setFlaggedAnimKnobRestart("shootdone", anim_autofire, 1, .05, animRate);
		[[anim.locSpam]]("c16a");
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println("enemyDistanceSq: ",self.enemyDistanceSq,", meleeRangeSq: ",anim.meleeRangeSq);
//		println("forceShoot: ",forceShoot);
		numShots = randomint(8) + 6;
		if (self.bulletsInClip < numShots)
			numShots = self.bulletsInClip;
		estimatedTime =  0.1 * (float)numShots / (float)animRate;
		self thread KillRunawayAutofire("cornerattack autofire done", estimatedTime);
		self thread DoAutoFire("cornerattack autofire done", numShots, forceShoot);
		self waittill("cornerattack autofire done");
		if (completeLastShot)
			wait animscripts\weaponList::waitAfterShot();
		self notify ("stopautofireFace");
	}
	else if (animscripts\weaponList::usingSemiAutoWeapon())
	{
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println(" ShootVolley: semiauto fire, "+self.bulletsInClip+" rounds in clip, enemyDistanceSq is "+self.enemyDistanceSq+".");

		self animscripts\face::SetIdleFace(anim.aimface);

		// TEMP(?) Slowly blend in shoot instead of playing the transition.
		self setanimknob(anim_semiautofire, 1, .15, 0);
		wait 0.2;

		[[anim.locSpam]]("c15b");
		rand = randomint(2) + 2;
		for (i = 0; (i<rand && (self.enemyDistanceSq>anim.meleeRangeSq || forceShoot=="forceShoot") && self.bulletsInClip>0); i ++)
		{
			[[anim.locSpam]]("c16b");
			self setFlaggedAnimKnobRestart("shootdone", anim_semiautofire, 1, 0, 1);
			[[anim.locSpam]]("c17b");
            if ( isDefined ( posOverrideEntity ) )
                self shoot ( 1 , posOverrideEntity . origin );
            else
                self shoot();
			self.bulletsInClip --;
			[[anim.locSpam]]("c17.1b");
			shootTime = animscripts\weaponList::shootAnimTime();
			quickTime = animscripts\weaponList::waitAfterShot();
			wait quickTime;
			if ( ( (completeLastShot) || (i<rand-1) ) && (self MyGetEnemySqDist()>anim.meleeRangeSq) && shootTime>quickTime)
				wait shootTime - quickTime;
			[[anim.locSpam]]("c18b");
			self.enemyDistanceSq = self MyGetEnemySqDist();
		}
	}
	else // Bolt action
	{
//		/#println(" ShootVolley: bolt-action fire, "+self.bulletsInClip+" rounds in clip, enemyDistanceSq is "+self.enemyDistanceSq+".");#/
		Rechamber();	// In theory you will almost never need to rechamber here, because you will have done 
						// it somewhere smarter, like in cover.
		if (self MyGetEnemySqDist()<=anim.meleeRangeSq && forceShoot!="forceShoot")	// Whenever time passes I need to check this...
		{
			/#println("Aborting combat::ShootVolley after rechambering - enemy within melee range");#/
			self notify ("stop EyesAtEnemy");
			return 0;
		}

		self animscripts\face::SetIdleFace(anim.aimface);

		// Slowly blend in the first frame of the shoot instead of playing the transition.
		self setanimknob(anim_boltfire, 1, .15, 0);
		// We want panzerfaust guys to wait longer before firing.
		if (self animscripts\utility::weaponAnims() == "panzerfaust" 
		 || self animscripts\utility::weaponAnims() == "panzerschreck"
		 || self animscripts\utility::weaponAnims() == "bazooka")
			wait 0.5;
		else
			wait 0.2;

		self setFlaggedAnimKnobRestart("shootdone", anim_boltfire, 1, 0, 1);
		[[anim.locSpam]]("c17c");
        if ( isDefined ( posOverrideEntity ) )
            self shoot ( 1 , posOverrideEntity . origin );
        else
            self shoot();
		self.anim_needsToRechamber = 1;
		self.bulletsInClip --;
		[[anim.locSpam]]("c17.1c");
		shootTime = animscripts\weaponList::shootAnimTime();
		quickTime = animscripts\weaponList::waitAfterShot();
		wait quickTime;
		[[anim.locSpam]]("c18c");
//		if ( (completeLastShot) && (self MyGetEnemySqDist()>anim.meleeRangeSq) )
//			Rechamber();
	}
	self setanim(%shoot,0.0,0.2,1); // cleanup and turn down shoot knob
	[[anim.locSpam]]("c19");
// MikeD: Removed comments so I can see my comments from the level script. :P
//	println("Leaving combat::ShootVolley");
	self notify ("stop EyesAtEnemy");
	return 1;
}


// There is a bug we don't have time to fix, where sometimes the autfire animation stops returning notetracks, 
// resulting in guys getting stuck in their autofire animation, not firing bullets.  This thread stops that 
// from continuing forever.
KillRunawayAutofire(notifyString, timeToWait)
{
	[[anim.assert]](timetowait>0);
	self endon(notifyString);
	self endon("killanimscript");
	self endon("death");
	wait timeToWait;
	self notify (notifyString);
	[[anim.locspam]]("kill af");
}
DoFlamethrowerFire(notifystring, numshots, forceShoot, stopTime, posOverrideEntity)
{
	[[anim.assert]](numshots>0);
	self endon(notifyString);
	self endon("killanimscript");
	self endon("death");
    if ( isDefined ( posOverrideEntity ) )
	{
		posOverrideEntity endon("death");
	}
	enemyAngle = animscripts\utility::AbsYawToEnemy();
	/#println("enemyAngle: ",enemyAngle);#/
	for (i = 0; (i<numShots && ((isDefined(self.enemyDistanceSq) && self.enemyDistanceSq>anim.meleeRangeSq) || forceShoot=="forceShoot") && self.bulletsInClip>0 && enemyAngle<20); i ++)
	for (i = 0; (i<numShots && ((isDefined(self.enemyDistanceSq) && self.enemyDistanceSq>anim.meleeRangeSq) || forceShoot=="forceShoot") && self.bulletsInClip>0 && enemyAngle<20); i ++)
	{
		[[anim.locspam]]("af1");
		wait 0.05;
		
        if ( isDefined ( posOverrideEntity ) )
		{
			if (isSentient(posOverrideEntity))
			{
				pos = posOverrideEntity GetEye();
			}
			else
			{
				pos = posOverrideEntity GetOrigin();
			}
		}
		if ( isDefined ( self.anim_aimOverridePosValid ) && self.anim_aimOverridePosValid && isDefined( self.anim_aimOverridePos ) )
		{
			if (isDefined( pos ))
			{
				pos = pos + self.anim_aimOverridePos;
			}
			else
			{
				pos = self.anim_aimOverridePos;
			}
		}
		if (isDefined( pos ))
		{
			self shoot ( 1 , pos );
		}
        else
        {
            self shoot();
        }
		//self.bulletsInClip --;
		[[anim.locspam]]("af2");
		self.enemyDistanceSq = self MyGetEnemySqDist();
		enemyAngle = animscripts\utility::AbsYawToEnemy();
		
		if (isDefined(stopTime)) {
			if (stopTime < gettime()) {
				i = numShots;
			}
		}
	}
	self notify (notifyString);
}

DoAutofire(notifystring, numshots, forceShoot, stopTime, posOverrideEntity)
{
	/#[[anim.assert]](numshots>0);#/  
	self endon(notifyString);  
	self endon("killanimscript");  
	self endon("death");  
	enemyAngle = animscripts\utility::AbsYawToEnemy();

    	if( isDefined ( posOverrideEntity ) )
	{
		posOverrideEntity endon("death");
	}

	wait 0; // This prevents this thread from notifying before the calling thread has got to a wait.  
	enemyAngle = animscripts\utility::AbsYawToEnemy();
// MikeD: Removed comments so I can see my comments from the level script. :P
//	println("enemyAngle: ",enemyAngle);

	// RF, if we're forcing a position, hack this so it doesnt fail
	if ( isDefined ( self.anim_aimOverridePosValid ) && self.anim_aimOverridePosValid && isDefined( self.anim_aimOverridePos ) )
	{
		enemyAngle = 0;
	}
	
	for (i = 0; (i<numShots && ((isDefined(self.enemyDistanceSq) && self.enemyDistanceSq>anim.meleeRangeSq) || forceShoot=="forceShoot") && self.bulletsInClip>0 && enemyAngle<20); i ++)
	{
		[[anim.locspam]]("af1");
		self waittillmatch ("shootdone", "fire");
		
        if ( isDefined ( posOverrideEntity ) )
		{
			if (isSentient(posOverrideEntity))
			{
				pos = posOverrideEntity GetEye();
			}
			else
			{
				pos = posOverrideEntity GetOrigin();
			}
		}
		if ( isDefined ( self.anim_aimOverridePosValid ) && self.anim_aimOverridePosValid && isDefined( self.anim_aimOverridePos ) )
		{
			if (isDefined( pos ))
			{
				pos = pos + self.anim_aimOverridePos;
			}
			else
			{
				pos = self.anim_aimOverridePos;
			}
		}
		if (isDefined( pos ))
		{
			self shoot ( 1 , pos );
		}
        else
        {
            self shoot();
        }
		self.bulletsInClip --;
		[[anim.locspam]]("af2");
		self.enemyDistanceSq = self MyGetEnemySqDist();
		enemyAngle = animscripts\utility::AbsYawToEnemy();
		
		if (isDefined(stopTime)) {
			if (stopTime < gettime()) {
				i = numShots;
			}
		}
	}
	self notify (notifyString);
}


// Rechambers the weapon if appropriate
Rechamber()
{
	if (self NeedsToRechamber())
	{
		if (self animscripts\utility::weaponAnims() == "panzerfaust" 
		 || self animscripts\utility::weaponAnims() == "panzerschreck"
		 || self animscripts\utility::weaponAnims() == "bazooka")
		{
// MikeD: Removed comments so I can see my comments from the level script. :P
//			println("Dropping panzerfaust");
			self.weapon = self.secondaryweapon;
			self animscripts\shared::PutGunInHand("right");
			self animscripts\weaponList::RefillClip();
			self.anim_needsToRechamber = 0;
		}
		else
		{
// MikeD: Removed comments so I can see my comments from the level script. :P
//			println("Need to rechamber");
			thread RechamberDebugThread();
			thread RechamberThread();
			self waittill("rechamberdone");
		}
	}
}

NeedsToRechamber()
{
	if ( (animscripts\weaponList::usingAutomaticWeapon()) || (animscripts\weaponList::usingSemiAutoWeapon()) )
		return false;

	return (self.anim_needsToRechamber);
}

RechamberDebugThread()
{
	self endon("rechamberdone");
	self endon("killanimscript");
	wait 3;
	myNum = self getEntityNumber();
// MikeD: Removed comments so I can see my comments from the level script. :P
//	println ("Guy "+myNum+" hung in rechamber at phase "+self.rechamberdebug);
	self.anim_needsToRechamber = 0;
	self notify ("rechamberdone");
}

RechamberThread()
{
	self endon("rechamberdone");
	self endon("killanimscript");

	self.rechamberdebug = "start";
	if (self.anim_script == "combat")
		self interruptPoint();
// MikeD: Removed comments so I can see my comments from the level script. :P
//	println("Rechambering");

	oldHand = self.anim_gunHand;
	playSpeed = 0.9 + randomfloat(0.2);

	self.rechamberdebug = "1";
	switch (self.anim_pose)
	{
	case "stand":
		switch (self.anim_special)
		{
		case "cover_left":
			if (self.anim_idleSet=="a")
			{
				self setFlaggedAnimKnobAll("rechamberanim", %cornerstandrechamber_right, %body, 1, .2, playSpeed);
				self.rechamberdebug = "2, stand, cover_left a";
			}
			else
			{
				[[anim.assert]](self.anim_idleSet=="b", "Combat::rechamber - cover_left stand guy not in idleSet a or b, he's in "+self.anim_idleSet);
				self setFlaggedAnimKnobAll("rechamberanim", %cornerb_stand_rechamber_right, %body, 1, .2, playSpeed);
				self.rechamberdebug = "2, stand, cover_left b";
			}
			break;
		case "cover_right":
			if (self.anim_idleSet=="a")
			{
				self setFlaggedAnimKnobAll("rechamberanim", %cornerstandrechamber_left, %body, 1, .2, playSpeed);
				self.rechamberdebug = "2, stand, cover_right a";
			}
			else
			{
				[[anim.assert]](self.anim_idleSet=="b", "Combat::rechamber - cover_right stand guy not in idleSet a or b, he's in "+self.anim_idleSet);
				self setFlaggedAnimKnobAll("rechamberanim", %cornerb_stand_rechamber_left, %body, 1, .2, playSpeed);
				self.rechamberdebug = "2, stand, cover_right b";
			}
			break;
		case "none":
		default:
			self setFlaggedAnimKnobAll("rechamberanim", %stand_rechamber, %body, 1, .2, playSpeed);
			self.rechamberdebug = "2, stand, default";
			break;
		}
		break;
	case "crouch":
		switch (self.anim_special)
		{
		case "cover_left":
			if (self.anim_idleSet=="a")
			{
				self setFlaggedAnimKnobAll("rechamberanim", %cornercrouchrechamber_right, %body, 1, .2, playSpeed);
				self.rechamberdebug = "2, crouch, cover_left a";
				// "Eject" is in this animation if we want it
			}
			else
			{
				[[anim.assert]](self.anim_idleSet=="b", "Combat::rechamber - cover_left crouch guy not in idleSet a or b, he's in "+self.anim_idleSet);
				self setFlaggedAnimKnobAll("rechamberanim", %cornerb_crouch_rechamber_right, %body, 1, .2, playSpeed);
				self.rechamberdebug = "2, stand, cover_left b";
			}
			break;
		case "cover_right":
			if (self.anim_idleSet=="a")
			{
				self setFlaggedAnimKnobAll("rechamberanim", %cornercrouchrechamber_left, %body, 1, .2, playSpeed);
				self.rechamberdebug = "2, stand, cover_right a";
			}
			else
			{
				[[anim.assert]](self.anim_idleSet=="b", "Combat::rechamber - cover_right crouch guy not in idleSet a or b, he's in "+self.anim_idleSet);
				self setFlaggedAnimKnobAll("rechamberanim", %cornerb_crouch_rechamber_left, %body, 1, .2, playSpeed);
				self.rechamberdebug = "2, stand, cover_right b";
			}
			break;
		case "cover_crouch":
			self.rechamberdebug = "2, crouch, cover_crouch";
			if (self.anim_idleSet != "b")
			{
				animscripts\cover_crouch::duckBetweenShots();	// This gets it into set b
			}
			self setFlaggedAnimKnobAll("rechamberanim", %hidelowwallb_rechamber, %body, 1, .2, playSpeed);
			self.rechamberdebug = "3, crouch, cover_crouch";
			break;
		case "none":
		default:
			self setFlaggedAnimKnobAll("rechamberanim", %crouch_rechamber, %body, 1, .2, playSpeed);
			self.rechamberdebug = "2, crouch, default";
			self.anim_needsToRechamber = 0;
			break;
		}
		break;
	case "prone":
		self setFlaggedAnimKnobAll("rechamberanim", %prone_rechamber, %body, 1, .2, playSpeed);
		self UpdateProne(%prone_shootfeet_straight45up, %prone_shootfeet_straight45down, 1, 0.1, 1);
		self.rechamberdebug = "2, prone, default";
		self.anim_needsToRechamber = 0;
		break;
	default:
		self setFlaggedAnimKnobAll("rechamberanim", %crouch_rechamber, %body, 1, .2, playSpeed);
		self.rechamberdebug = "2, default, default";
		break;
	}
	self.anim_needsToRechamber = 0;	// TODO Should I put this in a notetrack?  Yes...
	self playsound ("weap_kar98k_rechamber");
	self animscripts\shared::DoNoteTracks("rechamberanim");
	[[anim.PutGunInHand]](oldHand);	// This is important as some of the animations swap it back on the very last frame.
	self.rechamberdebug = "Rechambering done";
	self notify ("rechamberdone");
// MikeD: Removed comments so I can see my comments from the level script. :P
//	println("Rechambering done");
}


// Returns true if character has less than thresholdFraction of his total bullets in his clip.  Thus, a value 
// of 1 would always reload, 0 would only reload on an empty clip.
NeedsToReload(thresholdFraction)
{
	if (!isDefined(thresholdFraction))
		thresholdFraction = 0;
	if (self.bulletsInClip <= (int)(animscripts\weaponList::ClipSize() * (float)thresholdFraction) )
		return true;
	else
		return false;
}

Reload(thresholdFraction, optionalAnimation/*, startingGunHand*/)
{
// MikeD: Removed comments so I can see my comments from the level script. :P
//	println("Reload, ", self.bulletsInClip,"/", animscripts\weaponList::ClipSize(),", ",thresholdFraction);
	if (self animscripts\utility::weaponAnims() == "panzerfaust" )
	{
		Rechamber();	// This handles swapping the panzerfaust for the secondary weapon.
	}
	else if (NeedsToReload(thresholdFraction))
	{
		if (self.anim_script == "combat")
			self interruptPoint();


//		println("Reloading...");
		oldHand = self.anim_gunHand;

		if (isDefined(optionalAnimation))
		{
			self setFlaggedAnimKnobAll("reloadanim", optionalAnimation, %body, 1, .1, 1);
			[[anim.PutGunInHand]]("left");
			self animscripts\shared::DoNoteTracks("reloadanim");
			self animscripts\shared::PutGunInHand(oldHand);
			self animscripts\weaponList::RefillClip();	// This should be in the animation as a notetrack in theory.
			self.anim_needsToRechamber = 0;
		}
		else if (self animscripts\utility::weaponAnims() == "bazooka")
		{
//			self setanim(%upperbody, 1, .1, 1);
			self setFlaggedAnimKnobAll("reloadanim", %c_prj_bazooka_reload, %body,1, .1, 1);
			self animscripts\shared::DoNoteTracks("reloadanim");
			
			// There aren't any other pistol animations so just fill it up magically.
			self animscripts\weaponList::RefillClip();
			self.anim_needsToRechamber = 0;
			self clearanim(%upperbody, .1);		// Only needed for the upper body running reload.
		}
		else if (self animscripts\utility::weaponAnims() == "pistol")
		{
			if (self.anim_movement == "stop")
			{
				if (self.anim_special == "none")
				{
					if (self.anim_pose == "crouch")
					{
						self setFlaggedAnimKnobAll("reloadanim",%pistol_crouch_reload, %body, 1, .1, 1);
						self animscripts\shared::DoNoteTracks("reloadanim");
					}
					else if (self.anim_pose == "stand")
					{
						self setFlaggedAnimKnobAll("reloadanim",%pistol_stand_reload, %body, 1, .1, 1);
						self animscripts\shared::DoNoteTracks("reloadanim");
					}
				}
			}
			else if (self.anim_pose == "stand")
			{
				self setanim(%upperbody, 1, .1, 1);
				self setflaggedanimknob("reloadanim", %pistol_stand_reload_upperbody, 1, .1, 1);
				self animscripts\shared::DoNoteTracks("reloadanim");
			}
			// There aren't any other pistol animations so just fill it up magically.
			self animscripts\weaponList::RefillClip();
			self.anim_needsToRechamber = 0;
		}
		else
		{
			if (self.anim_pose == "stand")
			{
				if (self.anim_movement == "run")
				{
					self setanim(%upperbody, 1, .1, 1);
					self setflaggedanimknob("reloadanim", %reload_stand_rifle_upperbody, 1, .1, 1);
					[[anim.PutGunInHand]]("left");
				}
				else
				{
					self setFlaggedAnimKnobAll("reloadanim",%reload_stand_rifle, %body, 1, .1, 1);
					[[anim.PutGunInHand]]("left");
				}
			}
			else if (self.anim_pose == "crouch")
			{
				if (self.anim_movement == "run")
				{
					self setanim(%upperbody, 1, .1, 1);
					self setflaggedanimknob("reloadanim", %reload_stand_rifle_upperbody, 1, .1, 1);	// TEMP?  Need crouch anim.
					[[anim.PutGunInHand]]("left");
				}
				else if (self.anim_special == "cover_crouch")
				{
					if (self.anim_idleSet != "b")
					{
						animscripts\cover_crouch::duckBetweenShots();	// This gets it into set b
					}
					self setFlaggedAnimKnobAll("reloadanim",%reload_crouch_cover_rifle, %body, 1, .1, 1);
					[[anim.PutGunInHand]]("left");
				}
				else
				{
					self setFlaggedAnimKnobAll("reloadanim",%reload_crouch_rifle, %body, 1, .1, 1);
					[[anim.PutGunInHand]]("left");
				}
			}
			else if (self.anim_pose == "prone")
			{
				self setFlaggedAnimKnobAll("reloadanim",%reload_prone_rifle, %body, 1, .1, 1);
				self UpdateProne(%prone_shootfeet_straight45up, %prone_shootfeet_straight45down, 1, 0.1, 1);
				[[anim.PutGunInHand]]("left");
			}
			else 
			{
// MikeD: Removed comments so I can see my comments from the level script. :P
//				println ("Bad anim_pose in combat::Reload");
				wait 2;
				return;
			}
			self animscripts\shared::DoNoteTracks("reloadanim");
			self animscripts\shared::PutGunInHand(oldHand);
			self animscripts\weaponList::RefillClip();	// This should be in the animation as a notetrack in most instances.
			self.anim_needsToRechamber = 0;
			self clearanim(%upperbody, .1);		// Only needed for the upper body running reload.
		}
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println("Reload done.");
	}
	else
	{
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println("Not reloading.");

	}
}


TryGrenade(optionalAnimation, armOffset/*, gunHand*/)
{
// MikeD: Removed comments so I can see my comments from the level script. :P
//	println("Entering combat::TryGrenade");
//	// First decide how we're going to try to throw the grenade, and with what animation.
//	// We cycle through three types of throw: normal, flat and really high.
//	if ( !isDefined(self.anim_grenadeThrowType) || self.anim_grenadeThrowType=="max time" )
//	{
//		self.anim_grenadeThrowType = "min energy";
//	}
//	else if (self.anim_grenadeThrowType=="min energy")
//	{
//		self.anim_grenadeThrowType = "min time";
//	}
//	else
//	{
//		self.anim_grenadeThrowType = "max time";
//	}
	if (isDefined(optionalAnimation))
	{
		throw_anim = optionalAnimation;
		// Assume armOffset and gunHand are defined whenever optionalAnimation is.
		gunhand = self.anim_gunHand;	// Actually we don't want gunhand in this case.  We rely on notetracks.
	}
	else
	{
		switch (self.anim_special)
		{
		case "cover_crouch":
		case "none":
			if (self.anim_pose == "stand")
			{
				armOffset = (0,0,80);
				throw_anim = %stand_grenade_throw;
			}
			else // if (self.anim_pose == "crouch")
			{
				armOffset = (0,0,65);
				throw_anim = %crouch_grenade_throw;
			}
			gunHand = "left";
			break;
		default:
			// Do nothing - we don't have an appropriate throw animation.
			break;
		}
	}

	// If we don't have an animation, we can't throw the grenade.
	if (!isDefined(throw_anim))
	{
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println("Can't throw a grenade from pose "+self.anim_pose+", special "+self.anim_special+".");
		return 0;
	}

	// Now try to throw it.
// MikeD: Removed comments so I can see my comments from the level script. :P
//	println (" trying to throw a grenade.");
	throwvel = self checkGrenadeThrow(armOffset, "min energy");
	if ( !isdefined(throwvel) )
		throwvel = self checkGrenadeThrow(armOffset, "min time");
	if ( !isdefined(throwvel) )
		throwvel = self checkGrenadeThrow(armOffset, "max time");
	if ( isdefined(throwvel) )
	{
		
		armpos = self LocalToWorldCoords(armoffset);
		animscripts\utility::drawDebugCross(armpos, 8, (0,1,0), 20);

// MikeD: Removed comments so I can see my comments from the level script. :P		
//		println (" throwing a grenade with velocity "+throwvel+".");

		oldHand = self.anim_gunHand;
		[[anim.putguninhand]](gunHand);
		self SetFlaggedAnimKnobAllRestart("throwanim", throw_anim, %body, 1, 0.1, 1);
//		wait 0.2;	// Give him time to pull the pin (requires that the "fire" note is at least 0.2 seconds into the animation).
		self.isHoldingGrenade = true;
		self waittillmatch("throwanim", "fire");
		self animscripts\face::SayGenericDialogue("grenadeattack");
		self throwGrenade();
		self.isHoldingGrenade = false;
		self animscripts\shared::DoNoteTracks("throwanim");
		[[anim.putguninhand]](oldHand);
        return ("ThrewGrenade");
	}
	else
	{
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println (" cannot throw a grenade.");
		
		armpos = self LocalToWorldCoords(armoffset);
		animscripts\utility::drawDebugCross(armpos, 8, (1,0,0), 20);
		
	}
    return 0;
}


ShootRunningVolleyThread(endString, waitTime)
{
	self endon("killanimscript");
	if (isDefined(endString))
		self endon(endString);
	if (isDefined(waitTime))
		wait (waitTime);
	ShootRunningVolley();
}

ShootRunningVolley()
{
	if (self.bulletsInClip <= 0)
	{
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println("Aborting combat::ShootVolley - need to reload");
		return 0;
	}
	if (self.anim_needsToRechamber)
	{
		oldHand = self.anim_gunHand;
		self setanim(%upperbody, 1, .1, 1);
		self setflaggedanimknob("rechamberanim", %upperbody_rechamber, 1, .1, 1);
		self playsound ("weap_kar98k_rechamber");
		self animscripts\shared::DoNoteTracks("rechamberanim");
		self.anim_needsToRechamber = 0;	// This is in a notetrack but I don't want to miss it.
		[[anim.PutGunInHand]](oldHand);	// This is in a notetrack but I don't want to miss it.
		self clearanim(%upperbody, .1);
	}
	else
	{
		self thread EyesAtEnemy();
		if (animscripts\weaponList::usingAutomaticWeapon())
			numShots = randomint(6)+3;	// 3-8
		else if (animscripts\weaponList::usingSemiAutoWeapon())
			numShots = randomint(2)+2;	// 2 or 3
		else
		{
			numShots = 1;
			self.anim_needsToRechamber = 1;	// I can set this now because there is no wait between here and shoot().
			// TODO Should check this variable and actually rechamber when I need to, once I can rechamber while running.
		}
		enemyAngle = animscripts\utility::AbsYawToEnemy();
		for (i=0; i<numShots && (self.bulletsInClip>0 && enemyAngle<25); i++)
		{
			self shoot(anim.runAccuracyMult);
			self.bulletsInClip--;
			wait animscripts\weaponList::shootAnimTime();
			enemyAngle = animscripts\utility::AbsYawToEnemy();
		}
		self notify ("stop EyesAtEnemy");
	}
}


tryBackPedal()
{
// MikeD: Removed comments so I can see my comments from the level script. :P
//	println("Entering backpedal");

	// Should be aiming at this point, but it's not important enough to assert against
	if (self.anim_alertness != "aiming")
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println("Not aiming on entry to backpedal - that's bad.");

	if (self.anim_pose != "stand" && self.anim_pose != "crouch")
	{
		// Can't backpedal if we're not in crouch or stand
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println("Can't backpedal in pose "+self.anim_pose);
		return false;
	}

	localDeltaVector = GetMoveDelta (%stand_shoot_run_back, 0, 1);
	endPoint = self LocalToWorldCoords( localDeltaVector );
	////	self.enemyDistanceSq = MyGetEnemySqDist();
	self.enemyDistanceSq = self GetClosestEnemySqDist();

	if (!isDefined(self.enemyDistanceSq))
	{
// MikeD: Removed comments so I can see my comments from the level script. :P
//		println("Leaving tryBackPedal - no enemy");
		return false;
	}

	success = false;

//	// Some debug info
//	
//		if (!isDefined(self.enemyDistanceSq))
//			println("HOLY COW HOW DID THIS HAPPEN?  self.enemyDistanceSq is undefined!  It was defined a moment ago!");
//		if (!self maymovetopoint(endPoint))
//			[[anim.println]](" Can't run backwards.");
//		if (!isDefined(self.enemyDistanceSq))
//			println("HOLY COW HOW DID THIS HAPPEN?  self.enemyDistanceSq is undefined!  It was defined two moments ago!");
//		if (self.enemyDistanceSq > anim.backPedalRangeSq)
//			[[anim.println]](" Enemy isn't close enough to backpedal.");
//		if (self.enemyDistanceSq <= anim.meleeRangeSq)
//			[[anim.println]](" Enemy is too close to backpedal.");
//	

	if(self.anim_pose == "prone")
	{
//		println("^3PREVENTING BACKPEDAL WHILE PRONE!!!");
		return success;
	}

	while ( (self maymovetopoint(endPoint)) && (self.enemyDistanceSq <= anim.backPedalRangeSq) && (self.enemyDistanceSq > anim.meleeRangeSq) )
	{
		success = true;
		self setflaggedanimknobAll("backpedalanim", %stand_shoot_run_back, %body, 1, .15, 1);
		////		thread ShootRunningVolleyThread("stopVolley");
		self.anim_pose = "stand";
		self.anim_movement = "run";
		self animscripts\shared::DoNoteTracks("backpedalanim");
		self notify("stopVolley");

		localDeltaVector = GetMoveDelta (%stand_shoot_run_back, 0, 1);
		endPoint = self LocalToWorldCoords( localDeltaVector );
	}
// MikeD: Removed comments so I can see my comments from the level script. :P
//	println("Leaving backpedal (result "+success+")");
	return success;
}


// For use by combat scripts, looks at the enemy until the script is interrupted, or "stop EyesAtEnemy" is notified.
EyesAtEnemy()
{
	if (!isDefined( self.eyesAtCounter ))
		self.eyesAtCounter = 0;
	self.eyesAtCounter = self.eyesAtCounter + 1;
		
	self notify ("stop EyesAtEnemy internal");	// Prevent buildup of threads.
	self endon ("death");
	self endon ("stop EyesAtEnemy internal");
	self thread StopEyesAtEnemy(self.eyesAtCounter);
	for (;;)
	{
		if (isDefined(self.enemy))
			self animscripts\shared::LookAtEntity(self.enemy, 2, "alert", "eyes only", "don't interrupt");
		wait 2;
	}
}
StopEyesAtEnemy(counter)
{
	self thread StopEyesAtEnemy2(counter);
	self endon ("death");
	self endon ("stop EyesAtEnemy internal");
	self waittill ("killanimscript");
	self notify ("stop EyesAtEnemy internal");
	if (self.eyesAtCounter == counter)	// if we havent started another thread since starting this one, then stop the look
		animscripts\shared::LookAtStop();
}
StopEyesAtEnemy2(counter)
{
	self endon ("death");
	self endon ("stop EyesAtEnemy internal");
	self waittill ("stop EyesAtEnemy");
	self notify ("stop EyesAtEnemy internal");
	if (self.eyesAtCounter == counter)	// if we havent started another thread since starting this one, then stop the look
		animscripts\shared::LookAtStop();
}

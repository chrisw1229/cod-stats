#using_animtree ("generic_human");

LookAtPosition_Fixed(lookTargetPos, lookDuration, lookSpeed, eyesOnly, interruptOthers)
{
	/#[[anim.assert]](isAI(self), "Can only call this function on an AI character");											#/
	/#[[anim.assert]](self.anim_targetLookInitilized == true, "LookAtPosition called on AI that lookThread was not called on");	#/
	/#[[anim.assert]]( (lookSpeed == "casual") || (lookSpeed == "alert"), "lookSpeed must be casual or alert");					#/
	// If interruptOthers is true, and there is another lookAt playing, then don't do anything.  InterruptOthers defaults to true.
	if ( !isDefined(interruptOthers) || (interruptOthers=="interrupt others") || (GetTime() > self.anim_lookEndTime) )
	{
		self.anim_lookTargetType = "origin";
		self.anim_lookTargetPos = lookTargetPos;
		self.anim_lookEndTime = GetTime() + (lookDuration*(float)1000);
		if(lookSpeed == "casual")
			self.anim_lookTargetSpeed = 800;
		else // alert
			self.anim_lookTargetSpeed = 1600;
		if ( isDefined(eyesOnly) && (eyesOnly=="eyes only") )
		{
			self notify("eyes look now");
		}
		else
		{
			self notify("look now");
		}
		
		// kill all other running threads that might stop us at the wrong time
	}
}

FireAtTarget(targetPos, duration, forceShoot, completeLastShot, posOverrideEntity, waitForStop)
{
	startTime = GetTime();
	endTime = startTime + duration * 1000;

	self endon("death");

	if (!isDefined(forceShoot))
	{
		forceShoot = "forceShoot";
	}
	if (!isDefined(completeLastShot))
	{
		completeLastShot = false;
	}
	if (self animscripts\utility::weaponAnims() == "none")
	{
		println ("Trying to shoot when unarmed!");
		return 0;
	}

	if (self.anim_movement != "stop")
	{
		if (!isDefined( waitForStop ) || !waitForStop)
		{
			println ("fireattarget: Trying to shoot when moving!");
			return 0;
		}
		
		// wait for them to stop
		while (self.anim_movement != "stop")
		{
			wait 0.2;
			if (GetTime() > endTime)
			{
				println( "fireattarget(): gave up waiting for AI to stop moving" );
				return 0;
			}
		}
	}

	self animscripts\shared::PutGunInHand("right");
	if (self.anim_pose == "stand")
	{
		anim_autofire = %stand_shoot_auto;
		anim_semiautofire = %stand_shoot;
		anim_boltfire = %stand_shoot;
	}
	else if (self.anim_pose == "crouch")
	{
		anim_autofire = %crouch_shoot_auto;
		anim_semiautofire = %crouch_shoot;
		anim_boltfire = %crouch_shoot;
	}
	else
	{
		println ("Trying to shoot when in ",self.anim_pose);
		return(0);
	}

	//[[anim.assert]](self.anim_alertness == "aiming", "FireAtTarget called when not aiming");
 	// Make sure the aim and shoot animations are ready to play

	// MikeD: Spawn a Fake_target so he can "aim" at it. But doesn't seem to be working.
	//self.anim_enemyOverride = spawn("script_origin",(targetPos));

	self setanimknob(%shoot, 1, .15, 1);

	// prevent buildup of threads
	self notify("FireAtTargetEnemyDeathThread stop internal");

	if ( isDefined ( posOverrideEntity ) )
	{
		self thread EyesAtEntity(posOverrideEntity);
		// there is not an option to face an arbitrary entity, so as a hack, we'll start a thread which constantly updates our
		// orient to face at the entity. this is not essential anyway since it's only for aesthetics
		self thread UpdateOrientToEntity( posOverrideEntity );
		
		// immediately stop the script if the entity dies
		self thread FireAtTargetEnemyDeathThread(posOverrideEntity);
	}
	else
	{
		self thread EyesAtPos(targetPos);
		self OrientMode("face point", targetPos);
	}

	self.fireAtTargetRunning = 1;

	// MikeD: Tells the AI to pull up his weapon and get into his AIM pose.
	
	self.anim_enemyOverride = posOverrideEntity;
	self.anim_aimOverridePos = targetPos;
	if (isDefined( targetPos ) )
	{
		self.anim_aimOverridePosValid = 1;
	}
	self thread animscripts\aim::aim(0.5);
	self waittill ("End aim script");

	if (animscripts\weaponList::usingFlamethrowerWeapon())
	{

		self animscripts\face::SetIdleFace(anim.autofireface);

		// Slowly blend in shoot instead of playing the transition.
		self setflaggedanimknob("animdone", anim_autofire, 1, .15, 0);
		wait 0.20;

		[[anim.locSpam]]("c15a");
		animRate = animscripts\weaponList::autoShootAnimRate();
		self setFlaggedAnimKnobRestart("shootdone", anim_autofire, 1, .05, animRate);
		[[anim.locSpam]]("c16a");
		
		for (; GetTime() < endTime;)
		{
			numShots = randomint(40) + 80;
			if (self.bulletsInClip < numShots)
				numShots = self.bulletsInClip;
			estimatedTime =  0.1 * (float)numShots / (float)animRate;
			self thread animscripts\combat::DoFlamethrowerFire("flamethrower fire done", numShots, forceShoot, endTime, posOverrideEntity);
			self waittill("flamethrower fire done");
			if (GetTime() < endTime && animscripts\combat::NeedsToReload(0)) {
				animscripts\combat::Reload(0);
			} else {
				wait 0.3;
			}
		}
		self notify ("stopautofireFace");
	}
	else if (animscripts\weaponList::usingAutomaticWeapon())
	{

		self animscripts\face::SetIdleFace(anim.autofireface);

		for (; GetTime() < endTime;)
		{
			// Slowly blend in shoot instead of playing the transition.
			self setflaggedanimknob("animdone", anim_autofire, 1, .15, 0);
			wait 0.20;

			[[anim.locSpam]]("c15a");
			animRate = animscripts\weaponList::autoShootAnimRate();
			self setFlaggedAnimKnobRestart("shootdone", anim_autofire, 1, .05, animRate);
			[[anim.locSpam]]("c16a");

			for (; GetTime() < endTime;)
			{
				numShots = randomint(8) + 6;
				if (self.bulletsInClip < numShots)
					numShots = self.bulletsInClip;
				if (numShots > 0)
				{
					estimatedTime =  0.1 * (float)numShots / (float)animRate;
					self thread animscripts\combat::KillRunawayAutofire("cornerattack autofire done", estimatedTime);
					self thread animscripts\combat::DoAutoFire("cornerattack autofire done", numShots, forceShoot, endTime, posOverrideEntity);
				}
				if (GetTime() < endTime && animscripts\combat::NeedsToReload(0)) {
					animscripts\combat::Reload(0);
					self thread animscripts\aim::aim(0.5);
					self waittill ("End aim script");
					break;
				} else {
					self waittill("cornerattack autofire done");
				}
			}
		}
		
		if (completeLastShot)
			wait animscripts\weaponList::waitAfterShot();
		self notify ("stopautofireFace");
	}
	else if (animscripts\weaponList::usingSemiAutoWeapon())
	{

		self animscripts\face::SetIdleFace(anim.aimface);

		// TEMP(?) Slowly blend in shoot instead of playing the transition.
		self setanimknob(anim_semiautofire, 1, .15, 0);
		wait 0.2;

		[[anim.locSpam]]("c15b");
		for (; (GetTime() < endTime); )
		{
			[[anim.locSpam]]("c16b");
			self setFlaggedAnimKnobRestart("shootdone", anim_semiautofire, 1, 0, 1);
			[[anim.locSpam]]("c17b");
			if ( isDefined ( posOverrideEntity ) )
			{
				if (isSentient(posOverrideEntity))
				{
					pos = posOverrideEntity GetEye();
				}
				else
				{
					pos = posOverrideEntity.origin;
				}
				self shoot ( 1 , pos );
			}
			else
			{
	            self shoot ( 1 , targetPos );
	        }
			self.bulletsInClip --;
			[[anim.locSpam]]("c17.1b");
			shootTime = animscripts\weaponList::shootAnimTime();
			quickTime = animscripts\weaponList::waitAfterShot();
			if (GetTime() < endTime && animscripts\combat::NeedsToReload(0)) {
				animscripts\combat::Reload(0);
			} else {
				wait quickTime;
				if ( (completeLastShot) && shootTime>quickTime)
					wait shootTime - quickTime;
			}
			[[anim.locSpam]]("c18b");
		}
	}
	else // Bolt action
	{
		for (; GetTime() < endTime; )
		{
			animscripts\combat::Rechamber();	// In theory you will almost never need to rechamber here, because you will have done 
												// it somewhere smarter, like in cover.
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
			{
				if (isSentient(posOverrideEntity))
				{
					pos = posOverrideEntity GetEye();
				}
				else
				{
					pos = posOverrideEntity GetOrigin();
				}
				self shoot ( 1 , pos );
			}
			else
			{
	            self shoot ( 1 , targetPos );
	        }
			self.anim_needsToRechamber = 1;
			self.bulletsInClip --;
			[[anim.locSpam]]("c17.1c");
			shootTime = animscripts\weaponList::shootAnimTime();
			quickTime = animscripts\weaponList::waitAfterShot();
			wait quickTime;
			[[anim.locSpam]]("c18c");
		}
	}

	// we finished firing before they died
	self EndFireAtTarget();	

	return 1;
}

// if the enemy dies, immediately stop the FireAtTarget()
FireAtTargetEnemyDeathThread(posOverrideEntity)
{
	self endon("FireAtTargetEnemyDeathThread stop internal");
	// wait until the entity is dead
	posOverrideEntity waittill("death");
	self EndFireAtTarget();
}

EndFireAtTarget()
{
	self.fireAtTargetRunning = 0;
	
	// this should drop the weapon down, and return to alert
	self thread animscripts\aim::dontaim();
	[[anim.locSpam]]("c19");
	self notify ("stop EyesAtPos");
	self notify ("stop EyesAtEntity");
	self notify ("stop UpdateOrientToEntity");

	self.anim_aimOverridePosValid = 0;
}

// For use by combat scripts, looks at the position until the script is interrupted, or "stop EyesAtPos" is notified.
EyesAtPos(pos)
{
	if (!isDefined( self.eyesAtCounter ))
		self.eyesAtCounter = 0;
	self.eyesAtCounter = self.eyesAtCounter + 1;
	
	//println("EyesAtPos(pos)");
	self notify ("stop EyesAtPos internal");	// Prevent buildup of threads.
	self endon ("death");
	self endon ("stop EyesAtPos internal");
	self thread StopEyesAtPos(self.eyesAtCounter);
	for (;;)
	{
		//self animscripts\shared::LookAtPosition(pos, 2, "alert", "eyes only", "don't interrupt");
		LookAtPosition_Fixed(pos, 2, "alert", "", "interrupt others");
		//self SetGoalPos(pos, -9999);
		//self OrientMode("face goal");
		wait 0.2;
	}
}
StopEyesAtPos(counter)
{
	self thread StopEyesAtPos2(counter);
	self endon ("death");
	self endon ("stop EyesAtPos internal");
	self waittill ("killanimscript");
	self notify ("stop EyesAtPos internal");
	if (self.eyesAtCounter == counter)	// if we havent started another thread since starting this one, then stop the look
		animscripts\shared::LookAtStop();
}
StopEyesAtPos2(counter)
{
	self endon ("death");
	self endon ("stop EyesAtPos internal");
	self waittill ("stop EyesAtPos");
	self notify ("stop EyesAtPos internal");
	if (self.eyesAtCounter == counter)	// if we havent started another thread since starting this one, then stop the look
		animscripts\shared::LookAtStop();
}

EyesAtEntity(entity)
{
	if (!isDefined(entity))
	{
		println ("EyesAtEntity() called without an entity to look at");
		return 0;
	}

	if (!isDefined( self.eyesAtCounter ))
		self.eyesAtCounter = 0;
	self.eyesAtCounter = self.eyesAtCounter + 1;
		
	self notify ("stop EyesAtEntity internal");	// Prevent buildup of threads.
	self endon ("death");
	entity endon ("death");
	self endon ("stop EyesAtEntity internal");
	self thread StopEyesAtEntity(entity, self.eyesAtCounter);
	for (;;)
	{
		self animscripts\shared::LookAtEntity(entity, 2, "alert", "eyes only", "don't interrupt");
		wait 2;
	}
}
StopEyesAtEntity(entity, counter)
{
	self thread StopEyesAtEntity2(entity, counter);
	self endon ("death");
	entity endon ("death");
	self endon ("stop EyesAtEntity internal");
	self waittill ("killanimscript");
	self notify ("stop EyesAtEntity internal");
	if (self.eyesAtCounter == counter)	// if we havent started another thread since starting this one, then stop the look
		animscripts\shared::LookAtStop();
}
StopEyesAtEntity2(entity, counter)
{
	self endon ("death");
	entity endon ("death");
	self endon ("stop EyesAtEntity internal");
	self waittill ("stop EyesAtEntity");
	self notify ("stop EyesAtEntity internal");
	if (self.eyesAtCounter == counter)	// if we havent started another thread since starting this one, then stop the look
		animscripts\shared::LookAtStop();
}

UpdateOrientToEntity(entity)
{
	if (!isDefined(entity))
	{
		println ("UpdateOrientToEntity() called without an entity to look at");
		return 0;
	}
		
	self notify ("stop UpdateOrientToEntity internal");	// Prevent buildup of threads.
	self endon ("death");
	entity endon ("death");
	self endon ("stop UpdateOrientToEntity internal");
	self thread StopUpdateOrientToEntity(entity);
	for (;;)
	{
		if (isSentient(entity))
		{
			pos = entity GetEye();
		}
		else
		{
			pos = entity.origin;
		}
		self OrientMode("face point", pos);
		wait 0.2;
	}
}
StopUpdateOrientToEntity(entity)
{
	self thread StopUpdateOrientToEntity2(entity);
	self endon ("death");
	entity endon ("death");
	self endon ("stop UpdateOrientToEntity internal");
	self waittill ("killanimscript");
	self notify ("stop UpdateOrientToEntity internal");
}
StopUpdateOrientToEntity2(entity)
{
	self endon ("death");
	entity endon ("death");
	self endon ("stop UpdateOrientToEntity internal");
	self waittill ("stop UpdateOrientToEntity");
	self notify ("stop UpdateOrientToEntity internal");
}

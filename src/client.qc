
// prototypes
void () W_WeaponFrame;
void() W_SetCurrentAmmo;
void() dog_pain;
void() player_stand1;
void (vector org) spawn_tfog;
void (vector org, entity death_owner) spawn_tdeath;
void() player_pain;

float	modelindex_eyes, modelindex_player, modelindex_dog;

/*
=============================================================================

				LEVEL CHANGING / INTERMISSION

=============================================================================
*/

float	intermission_running;
float	intermission_exittime;

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() info_intermission =
{
};


float() GetMaxHealth =
{
	if(!deathmatch && skill == 3) {
		return 50;
	}
	else {
		return 100;
	}
}


void() SetChangeParms =
{
	if (self.health <= 0)
	{
		SetNewParms ();
		return;
	}

// remove items
	self.items = self.items - (self.items &
	(IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD) );

// cap super health
	if (self.health > self.max_health)
		self.health = self.max_health;

	local float halfMaxHealth = self.max_health / 2;
	if (self.health < halfMaxHealth)
		self.health = halfMaxHealth;

	parm1 = self.items;
	parm2 = self.health;
	parm3 = self.armorvalue;
	if (self.ammo_shells < 25)
		parm4 = 25;
	else
		parm4 = self.ammo_shells;
	parm5 = self.ammo_nails;
	parm6 = self.ammo_rockets;
	parm7 = self.ammo_cells;
	parm8 = self.weapon;
	parm9 = self.armortype * 100;
};

void() SetNewParms =
{
	parm1 = IT_SHOTGUN | IT_AXE;
	parm2 = GetMaxHealth();
	parm3 = 0;
	parm4 = 25;
	parm5 = 0;
	parm6 = 0;
	parm7 = 0;
	parm8 = 1;
	parm9 = 0;
};

void() SetDogParms =
{
	parm1 = IT_AXE;
	parm2 = 50;
	parm3 = 0;
	parm4 = 0;
	parm5 = 0;
	parm6 = 0;
	parm7 = 0;
	parm8 = 0;
	parm9 = 0;
};

void() DecodeLevelParms =
{
	self.items = parm1;
	self.health = parm2;
	self.armorvalue = parm3;
	self.ammo_shells = parm4;
	self.ammo_nails = parm5;
	self.ammo_rockets = parm6;
	self.ammo_cells = parm7;
	self.weapon = parm8;
	self.armortype = parm9 * 0.01;

	if(self.isHuman)
	{
		self.items = IT_SHOTGUN | IT_AXE;
		self.weapon = IT_SHOTGUN;
		self.health = GetMaxHealth();
		self.armorvalue = 0;
		self.ammo_shells = 25;
	}
	else
	{
		self.items = IT_AXE;
		self.weapon = IT_AXE;
		self.health = ZOMB_STARTHP;
		self.armorvalue = 0;
	}
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity() FindIntermission =
{
	local	entity spot;
	local	float cyc;

// look for info_intermission first
	spot = find (world, classname, "info_intermission");
	if (spot)
	{	// pick a random one
		cyc = random() * 4;
		while (cyc > 1)
		{
			spot = find (spot, classname, "info_intermission");
			if (!spot)
				spot = find (spot, classname, "info_intermission");
			cyc = cyc - 1;
		}
		return spot;
	}

// then look for the start position
	spot = find (world, classname, "info_player_start");
	if (spot)
		return spot;

// testinfo_player_start is only found in regioned levels
	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;

	objerror ("FindIntermission: no spot");
	return world;
};


string nextmap;
void() GotoNextMap =
{
	changelevel (nextmap);
};


void() ExitIntermission =
{
	dprint("EXIT INTERMISSION\n");
	GotoNextMap ();
};

/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
void() IntermissionThink =
{
	if (time < intermission_exittime)
		return;

	if (!self.button0 && !self.button1 && !self.button2)
		return;

	ExitIntermission ();
};

void() execute_changelevel =
{
	local entity	pos;

	intermission_running = 1;

// enforce a wait time before allowing changelevel
	if (deathmatch)
		intermission_exittime = time + 5;
	else
		intermission_exittime = time + 2;

	WriteByte (MSG_ALL, SVC_CDTRACK);
	WriteByte (MSG_ALL, 3);
	WriteByte (MSG_ALL, 3);

	pos = FindIntermission ();

	other = find (world, classname, "player");
	while (other != world)
	{
		other.view_ofs = '0 0 0';
		other.angles = other.v_angle = pos.mangle;
		other.fixangle = TRUE;		// turn this way immediately
		other.nextthink = time + 0.5;
		other.takedamage = DAMAGE_NO;
		other.solid = SOLID_NOT;
		other.movetype = MOVETYPE_NONE;
		other.deadflag = DEAD_DEAD;
		other.modelindex = 0;
		setorigin (other, pos.origin);
		other = find (other, classname, "player");
	}
	WriteByte (MSG_ALL, SVC_INTERMISSION);
};


void() changelevel_touch =
{

	if (other.classname != "player")
		return;

	if ((cvar("noexit") == 1) || ((cvar("noexit") == 2) && (mapname != "start")))
	{
		T_Damage (other, self, self, 50000);
		return;
	}

	if (coop || deathmatch)
	{
		bprint (other.netname);
		bprint (" exited the level\n");
	}

	nextmap = self.map;

	SUB_UseTargets ();

	if ( (self.spawnflags & 1) && (deathmatch == 0) )
	{	// NO_INTERMISSION
		GotoNextMap();
		return;
	}

	self.touch = SUB_Null;

// we can't move people right now, because touch functions are called
// in the middle of C movement code, so set a think time to do it
	self.think = execute_changelevel;
	self.nextthink = time + 0.1;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
	if (!self.map)
		objerror ("chagnelevel trigger doesn't have map");

	InitTrigger ();
	self.touch = changelevel_touch;
};


/*
=============================================================================

				PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

void() set_suicide_frame;

// called by ClientKill and DeadThink
void() respawn =
{
	if(self.isHuman)
	{
		self.isHuman = FALSE;
	}

	if (coop)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// get the spawn parms as they were at level start
		setspawnparms (self);
		// respawn
		PutClientInServer ();
	}
	else if (deathmatch)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// set default spawn parms
		SetNewParms ();
		// respawn
		PutClientInServer ();
	}
	else
	{	// restart the entire server
		localcmd ("restart\n");
	}
};


/*
============
ClientKill

Player entered the suicide command
============
*/
void() ClientKill =
{
	if(self.isObserver)
		return;
	bprint (self.netname);
	bprint (" suicides\n");
	set_suicide_frame ();
	if(!self.isHuman)
		self.modelindex = modelindex_dog;
	else
		self.modelindex = modelindex_player;
	respawn ();
};

float(vector v) CheckSpawnPoint =
{
	return FALSE;
};

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity() SelectSpawnPoint =
{
	local	entity spot;
	local	entity thing;
	local	float  pcount;

// testinfo_player_start is only found in regioned levels
	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;

// choose a info_player_deathmatch point
	if (coop)
	{
		lastspawn = find(lastspawn, classname, "info_player_coop");
		if (lastspawn == world)
			lastspawn = find (lastspawn, classname, "info_player_start");
		if (lastspawn != world)
			return lastspawn;
	}
	else if (deathmatch)
	{
		spot = lastspawn;
		while (1)
		{
			spot = find(spot, classname, "info_player_deathmatch");
			if (spot != world)
			{
				if (spot == lastspawn)
					return lastspawn;
				pcount = 0;
				thing = findradius(spot.origin, 32);
				while(thing)
				{
					if (thing.classname == "player")
						pcount = pcount + 1;
					thing = thing.chain;
				}
				if (pcount == 0)
				{
					lastspawn = spot;
					return spot;
				}
			}
		}
	}

	if (serverflags)
	{	// return with a rune to start
		spot = find (world, classname, "info_player_start2");
		if (spot)
			return spot;
	}

	spot = find (world, classname, "info_player_start");
	if (!spot)
		error ("PutClientInServer: no info_player_start on level");

	return spot;
};

/*
===========
PutClientInServer

called each time a player is spawned
============
*/
void() DecodeLevelParms;
void() PlayerDie;
void() dog_stand1;

void() PutObserverInServer =
{
	dprint("PutObserverInServer:: ");
	dprint(self.netname);
	dprint("\n");
	local	entity spot;

	spot = SelectSpawnPoint ();

	self.classname = "player";
	//self.health = GetMaxHealth();
	self.health = 2;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_WALK;
	self.show_hostile = 0;
	self.max_health = self.health;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2;   		// initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;

	DecodeLevelParms ();

	W_SetCurrentAmmo ();

	self.attack_finished = time;
	self.th_pain = player_pain;
	self.th_die = PlayerDie;

	self.deadflag = DEAD_NO;
	self.pausetime = 0;

	self.origin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;

	setmodel (self, "progs/eyes.mdl");
	modelindex_eyes = self.modelindex;

	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

	self.view_ofs = '0 0 22';

	player_stand1 ();

	if (deathmatch || coop)
	{
		makevectors(self.angles);
		spawn_tfog (self.origin + v_forward*20);
	}

	spawn_tdeath (self.origin, self);

	stuffcmd(self,"-attack\n");
}

void() PutDogInServer =
{
	dprint("PutInfectedInServer:: ");
	dprint(self.netname);
	dprint("\n");

	local	entity spot;

	spot = SelectSpawnPoint ();

	self.classname = "player";
	self.health = ZOMB_STARTHP;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.show_hostile = 0;
	self.max_health = self.health;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2;   		// initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;
	self.zombLevel = 0;
	self.zombXP = 0;
	self.zombXPtime = 0;
	self.frags = 666;

	SetDogParms ();
	self.items = IT_AXE;

	//W_SetCurrentAmmo ();

	self.attack_finished = time;
	self.th_pain = dog_pain;
	self.th_die = PlayerDie;

	self.deadflag = DEAD_NO;
	self.pausetime = 0;

	self.origin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;

	setmodel (self, "progs/eyes.mdl");
	modelindex_eyes = self.modelindex;

	setmodel (self, "progs/dog.mdl");
	modelindex_dog = self.modelindex;

	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

	self.view_ofs = '0 0 4';

	dog_stand1();

	if (deathmatch || coop)
	{
		makevectors(self.angles);
		spawn_tfog (self.origin + v_forward*20);
	}

	spawn_tdeath (self.origin, self);

	stuffcmd(self,"-attack\n");

	self.itemdrop1time = time + 5 + random() * 30;
	self.itemdroppos = '999 999 999';
}

void() PutClientInServer =
{
	if(self.isObserver)
	{
		PutObserverInServer();
		return;
	}

	if(!self.isHuman)
	{
		PutDogInServer();
		return;
	}

	dprint("PutClientInServer:: ");
	dprint(self.netname);
	dprint("\n");

	local	entity spot;

	spot = SelectSpawnPoint ();

	self.classname = "player";
	//self.health = GetMaxHealth();
	self.health = 2;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.show_hostile = 0;
	self.max_health = self.health;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2;   		// initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;

	DecodeLevelParms ();

	W_SetCurrentAmmo ();

	self.attack_finished = time;
	self.th_pain = player_pain;
	self.th_die = PlayerDie;

	self.deadflag = DEAD_NO;
	self.pausetime = 0;

	self.origin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;

	setmodel (self, "progs/eyes.mdl");
	modelindex_eyes = self.modelindex;

	setmodel (self, "progs/player.mdl");
	modelindex_player = self.modelindex;

	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

	self.view_ofs = '0 0 22';

	player_stand1 ();

	if (deathmatch || coop)
	{
		makevectors(self.angles);
		spawn_tfog (self.origin + v_forward*20);
	}

	spawn_tdeath (self.origin, self);

	stuffcmd(self,"-attack\n");
};

/*
=============================================================================

				QUAKED FUNCTIONS

=============================================================================
*/


/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start =
{
};


/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void() info_player_start2 =
{
};


/*
saved out by quaked in region mode
*/
void() testplayerstart =
{
};

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
*/
void() info_player_deathmatch =
{
};

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
*/
void() info_player_coop =
{
};

/*
===============================================================================

RULES

===============================================================================
*/

/*
go to the next level for deathmatch
only called if a time or frag limit has expired
*/
void() NextLevel =
{
	dprint("Next Level\n");
	local entity o;

	// find a trigger changelevel
	o = find(world, classname, "trigger_changelevel");

	// go back to start if no trigger_changelevel
	if (!o)
	{
		mapname = "start";
		o = spawn();
		o.map = mapname;
	}

	nextmap = o.map;
	gameover = TRUE;

	if (o.nextthink < time)
	{
		o.think = execute_changelevel;
		o.nextthink = time + 0.1;
	}
};

/*
============
CheckRules

Exit deathmatch games upon conditions
============
*/
void(string sg) MessageAllClients;
void() CheckRules =
{
	local	float		timelimit;

	if (gameover)	// someone else quit the game already
		return;

	timelimit = 600; //10 minutes

	if (time >= timelimit)
	{
		dprint("Humans win!\n");
		MessageAllClients("The Living Prevail! \nHell's Minions Have Retreated for now...\n\n");
		gamestate = STATE_END;
		host_checkStateTime = 500;
		return;
	}

	//if (fraglimit && self.frags >= fraglimit)
	//{
	//	NextLevel ();
	//	return;
	//}
};

//============================================================================

void() PlayerDeathThink =
{
	local float		forward;

	if ((self.flags & FL_ONGROUND))
	{
		forward = vlen (self.velocity);
		forward = forward - 20;
		if (forward <= 0)
			self.velocity = '0 0 0';
		else
			self.velocity = forward * normalize(self.velocity);
	}

// wait for all buttons released
	if (self.deadflag == DEAD_DEAD)
	{
		if(!gameover && self.flags & FL_ISBOT)
		{
			respawn();
			return;
		}

		if (self.button2 || self.button1 || self.button0)
			return;
		self.deadflag = DEAD_RESPAWNABLE;
		return;
	}

// wait for any button down
	if (!self.button2 && !self.button1 && !self.button0)
		return;

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
	respawn();
};


void() PlayerJump =
{

	if (self.flags & FL_WATERJUMP)
		return;

	if (self.waterlevel >= 2)
	{
		if (self.watertype == CONTENT_WATER)
		{
			if(self.isHuman)
				self.velocity_z = 100;
			else
				self.velocity_z = 250;
		}
		else if (self.watertype == CONTENT_SLIME)
			self.velocity_z = 80;
		else
			self.velocity_z = 50;

// play swiming sound
		if (self.swim_flag < time)
		{
			self.swim_flag = time + 1;
			if (random() < 0.5)
				sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
		}

		return;
	}

	if (!(self.flags & FL_ONGROUND))
		return;

	if ( !(self.flags & FL_JUMPRELEASED) )
		return;		// don't pogo stick

	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);

	self.flags = self.flags - FL_ONGROUND;	// don't stairwalk

	self.button2 = 0;
// player jumping sound
	if(self.isHuman)
	{
		sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
		self.velocity_z = self.velocity_z + 270;
	}
	else
	{
		local float rnum;
		rnum = random();
		if(rnum > 0.5)
			sound (self, CHAN_BODY, "dog/dsight.wav", 1, ATTN_NORM);
		else if(rnum > 0.75)
			sound (self, CHAN_BODY, "dog/dpain1.wav", 1, ATTN_NORM);
		
		if(self.zombLevel < 2)
		{
			self.velocity_z = self.velocity_z + 290;
		}
		else // Upgraded leap
		{
			self.velocity_z = self.velocity_z + 320;
			local vector vel;
			vel = self.velocity * 1.35;
			vel_z = self.velocity_z;
			self.velocity = vel;
		}
	}
};


/*
===========
WaterMove

============
*/
.float	dmgtime;

void() WaterMove =
{
//dprint (ftos(self.waterlevel));
	if (self.movetype == MOVETYPE_NOCLIP)
		return;
	if (self.health < 0)
		return;

	if (self.waterlevel != 3)
	{
		if (self.air_finished < time)
			sound (self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
		else if (self.air_finished < time + 9)
			sound (self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
		self.air_finished = time + 12;
		self.dmg = 2;
	}
	else if (self.air_finished < time)
	{	// drown!
		if (self.pain_finished < time)
		{
			self.dmg = self.dmg + 2;
			if (self.dmg > 15)
				self.dmg = 10;
			T_Damage (self, world, world, self.dmg);
			self.pain_finished = time + 1;
		}
	}

	if (!self.waterlevel)
	{
		if (self.flags & FL_INWATER)
		{
			// play leave water sound
			sound (self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
			self.flags = self.flags - FL_INWATER;
		}
		return;
	}

	if (self.watertype == CONTENT_LAVA)
	{	// do damage
		if (self.dmgtime < time)
		{
			self.dmgtime = time + 0.2;
			T_Damage (self, world, world, 10*self.waterlevel);
		}
	}
	else if (self.watertype == CONTENT_SLIME)
	{	// do damage
		if (self.dmgtime < time)
		{
			self.dmgtime = time + 1;
			T_Damage (self, world, world, 4*self.waterlevel);
		}
	}

	if ( !(self.flags & FL_INWATER) )
	{

// player enter water sound

		if (self.watertype == CONTENT_LAVA)
			sound (self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_SLIME)
			sound (self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);

		self.flags = self.flags + FL_INWATER;
		self.dmgtime = 0;
	}

	if (! (self.flags & FL_WATERJUMP) )
	{
		self.velocity = self.velocity - 0.7*self.waterlevel*frametime*self.velocity;
	}
};

void() CheckWaterJump =
{
	local vector start, end;

	if(self.isHuman)
	{
		// check for a jump-out-of-water
		makevectors (self.angles);
		start = self.origin;
		start_z = start_z + 8;
		v_forward_z = 0;
		normalize(v_forward);
		end = start + v_forward*24;
		traceline (start, end, TRUE, self);
		if (trace_fraction < 1)
		{	// solid at waist
			start_z = start_z + self.maxs_z - 8;
			end = start + v_forward*24;
			self.movedir = trace_plane_normal * -50;
			traceline (start, end, TRUE, self);
			if (trace_fraction == 1)
			{	// open at eye level
				self.flags = self.flags | FL_WATERJUMP;
				self.velocity_z = 235;
				self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
				self.teleport_time = time + 2;	// safety net
				return;
			}
		}
	}
	else
	{
		// check for a jump-out-of-water
		makevectors (self.angles);
		start = self.origin;
		start_z = start_z + 8;
		v_forward_z = 0;
		normalize(v_forward);
		end = start + v_forward*24;
		traceline (start, end, TRUE, self);
		if (trace_fraction < 1)
		{	// solid at waist
			start_z = start_z + self.maxs_z - 1;
			end = start + v_forward*24;
			self.movedir = trace_plane_normal * -50;
			traceline (start, end, TRUE, self);
			if (trace_fraction == 1)
			{	// open at eye level
				self.flags = self.flags | FL_WATERJUMP;
				self.velocity_z = 435;
				self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
				self.teleport_time = time + 2;	// safety net
				return;
			}
		}
	}
};


/*
================
PlayerPreThink

Called every frame before physics are run
================
*/
void() HostPreThink;
void() HostPostThink;
void() PlayerPreThink =
{
	if (intermission_running)
	{
		IntermissionThink ();	// otherwise a button could be missed between
		return;					// the think tics
	}

	if (gamestate == STATE_END && self.view_ofs == '0 0 0')
		return;		// intermission or finale

	if(self.isGameHost)
	{
		HostPreThink();
	}

	makevectors (self.v_angle);		// is this still used

	CheckRules ();
	WaterMove ();

	if (self.waterlevel == 2)
		CheckWaterJump ();

	if (self.deadflag >= DEAD_DEAD && !self.isObserver)
	{
		PlayerDeathThink ();
		return;
	}

	if (self.deadflag == DEAD_DYING)
		return;	// dying, so do nothing

	if (self.button2)
	{
		PlayerJump ();
	}
	else
		self.flags = self.flags | FL_JUMPRELEASED;

// teleporters can force a non-moving pause time
	if (time < self.pausetime)
		self.velocity = '0 0 0';

	if(self.isObserver)
	{
		ImpulseCommands ();
		return;
	}

	if(time > self.attack_finished && self.currentammo == 0 && self.weapon != IT_AXE)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
	}

	if(!self.isHuman)
	{
		if(self.zombLevel > 2)
		{
			// Speed boost
			if (self.flags & FL_ONGROUND)
			{
				self.velocity_x = (1 + (UA_speedBoost * frametime)) * (self.velocity_x);
				self.velocity_y = (1 + (UA_speedBoost * frametime)) * (self.velocity_y);
			}
		}
		else // Regular zomb boost
		{
			if (self.flags & FL_ONGROUND)
			{
				self.velocity_x = (1 + (zombSpeedBoost * frametime)) * (self.velocity_x);
				self.velocity_y = (1 + (zombSpeedBoost * frametime)) * (self.velocity_y);
			}
		}

		if(time >= self.zombXPtime)
		{
			if(self.zombLevel < 4)
			{
				self.zombXPtime = time + 1.25;
				self.zombXP = self.zombXP + 1;
			}

			// Do level up
			if(self.zombXP >= 10)
			{
				self.zombLevel++;
				self.zombXP = 0;
				stuffcmd(self, "bf\n");
				if(self.zombLevel == 1)
				{
					sprint(self, "LEVEL 1: Corrupt Carapace\nIncreased Health and Health Recovers After Time.");
					self.max_health = ZOMB_STARTHP + CC_HealthBonus;
					self.CC_hpRecoverTime = time + 1;
					self.armortype = 0;
					self.armorvalue = 1;
				}
				else if(self.zombLevel == 2)
				{
					sprint(self, "LEVEL 2: Unholy Adrenaline\nRun Faster and Leap Farther.");
					self.armortype = 0;
					self.armorvalue = 2;
				}
				else if(self.zombLevel == 3)
				{
					sprint(self, "LEVEL 3: Vile Soul\nExplode on Death.");
					self.effects = self.effects | EF_INVINCIBLE;
					//self.items = - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR3;
					self.armortype = 0;
					self.armorvalue = 3;
				}
				else if(self.zombLevel == 4)
				{
					sprint(self, "LEVEL 4: Vicious Bite\n Increased Bite Damage.");
					self.armortype = 0;
					self.armorvalue = 4;
				}
			}
			self.currentammo = self.zombXP;
			self.armorvalue = self.zombLevel;
		}
	}
};

/*
================
CheckPowerups

Check for turning off powerups
================
*/
void() CheckPowerups =
{

};


/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() DogDropItem;
void() PlayerPostThink =
{
	if (gamestate == STATE_END && self.view_ofs == '0 0 0')
		return;		// intermission or finale
	if (!self.isObserver && self.deadflag)
		return;

	if(self.isGameHost)
	{
		HostPostThink();
	}

	if(self.isObserver)
		return;

// do weapon stuff

	W_WeaponFrame ();

// check to see if player landed and play landing sound
	if ((self.jump_flag < -300) && (self.flags & FL_ONGROUND) && (self.health > 0))
	{
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
		else if (self.jump_flag < -650)
		{
			T_Damage (self, world, world, 5);

			if(self.isHuman)
				sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_VOICE, "dog/dpain1.wav", 1, ATTN_NORM);

			self.deathtype = "falling";
		}
		else
		{
			if(self.isHuman)
				sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);
		}

		self.jump_flag = 0;
	}

	if (!(self.flags & FL_ONGROUND))
		self.jump_flag = self.velocity_z;

	if(!self.isHuman)
	{
		if(self.zombLevel > 0)
		{
			// Cursed Carapace
			if(time >= self.CC_hpRecoverTime)
			{
				if(self.health < ZOMB_STARTHP + CC_HealthBonus)
				{
					self.health++;
					self.CC_hpRecoverTime = time + 0.5;
				}
			}
		}

		//Drop an item for humans
		if(!self.itemdrop1)
		{
			if(self.itemdroppos == '999 999 999')
			{
				if(time > self.itemdrop1time - 5)
				{
					self.itemdroppos = self.origin + '0 0 1';
				}
			}
			if(time > self.itemdrop1time)
			{
				DogDropItem();
			}
		}
	}

	if(self.showMOTD)
	{
		if(self.showMOTD > 1)
		{
			self.showMOTD--;
		}
		if (self.button0 || self.button1 || self.button2 || gamestate != STATE_WARMUP)
		{
			self.showMOTD = 0;
			if(gamestate == STATE_STARTING)
				centerprint(self,"Evil Approaches!\n");
			else
				centerprint(self,"\n");
		}
		if(self.showMOTD == 1)
		{
			self.showMOTD = 50;
			centerprint(self,"WELCOME TO INFECTED!\n\nHuman players must team up to survive Hell's hounds. Search for weapons and ammo to survive for 10 minutes.\n\nInfected must hunt down all Humans.\nInfected level up every 10 seconds, unlocking a new ability.\n\n(Jump To Continue)\n\nQuestions - Comments: @TelefragEnt on Twitter\n");
		}
	}
};


/*
===========
ClientConnect

called when a player connects to a server
============
*/
void() ClientConnect =
{
	bprint (self.netname);
	bprint (" entered the game.\n");

	self.showMOTD = 30;

	self.isHuman = TRUE;
	if(gamestate == STATE_RUNNING)
	{
		self.isHuman = FALSE;
		dprint(self.netname);
		dprint(" joined late, starting as infected.");
		sprint(self, "Joining game in progress as Infected.");
		return;
	}

// a client connecting during an intermission can cause problems
	if (intermission_running)
		ExitIntermission ();

	// Choose game host
	gamehost = find( world, isGameHost, "1" );
	if(gamehost == world && !(self.flags & FL_ISBOT) )
	{
		// No host, make this client the host
		self.isGameHost = "1";
		self.isObserver = "1";
		gamehost = self;
		gamestate = STATE_WARMUP;
		host_checkStateTime = 500; // Start warmup player checking
		dprint("\n");
		dprint(self.netname);
		dprint(" set to gamehost. Default to OBSERVER.\n");
	}
};


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
	if (gameover)
		return;

	bprint (self.netname);
	bprint (" left the game.");
	sound (self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);
	set_suicide_frame ();

	//Check for end of game conditions
	host_checkStateTime = 5;

	// Migrate game host
	if(self.isGameHost)
	{
		self.isGameHost = FALSE;
		gamehost = world;

		local float attempts;
		attempts = 10;
		while(attempts > 0)
		{
			gamehost = find( world, isGameHost, "1" );
			if(gamehost != world){
				return;
			}
			attempts--;
		}
		dprint("HOST MIGRATION ERROR: Unable to migrate game host to another client.\n");
	}
};

/*
===========
ClientObituary

called when a player dies
============
*/
void(entity targ, entity attacker) ClientObituary =
{
	local	float rnum;
	local	string deathstring, deathstring2;
	rnum = random();

	if (targ.classname == "player")
	{
		if (targ.deathtype == "infected") // Starting infected players
		{
			targ.deathtype = "";
			return;
		}

		if(attacker.classname == "player" && !attacker.isHuman)
		{
			if (rnum < 0.25)
			{
				bprint (attacker.netname);
				bprint (" consumes ");
				bprint (targ.netname);
				bprint ("'s soul!\n");
			}
			else if (rnum < 0.50)
			{
				bprint (attacker.netname);
				bprint (" assimilates ");
				bprint (targ.netname);
				bprint (" into the Army of the Dead!\n");
			}
			else if (rnum < 0.75)
			{
				bprint (attacker.netname);
				bprint (" devours ");
				bprint (targ.netname);
				bprint ("'s life force!\n");
			}
			else
			{
				bprint (attacker.netname);
				bprint (" eats ");
				bprint (targ.netname);
				bprint ("'s face!\n");
			}
			return;
		}
		else if (attacker.classname == "player")
		{
			bprint (targ.netname);
			bprint (" was cleansed by ");
			bprint (attacker.owner.netname);
			bprint ("\n");
			
			attacker.frags = attacker.frags + 1;

			return; // No obits for dogs?
		}

		if (attacker.classname == "teledeath")
		{
			bprint (targ.netname);
			bprint (" was telefragged by ");
			bprint (attacker.owner.netname);
			bprint ("\n");

			attacker.owner.frags = attacker.owner.frags + 1;
			return;
		}

		if (attacker.classname == "teledeath2")
		{
			bprint ("Satan's power deflects ");
			bprint (targ.netname);
			bprint ("'s telefrag\n");

			targ.frags = targ.frags - 1;
			return;
		}

		if (attacker.classname == "player")
		{
			if (targ == attacker)
			{
				// killed self
				attacker.frags = attacker.frags - 1;
				bprint (targ.netname);

				if (targ.weapon == 64 && targ.waterlevel > 1)
				{
					bprint (" discharges into the water.\n");
					return;
				}
				if (targ.weapon == IT_GRENADE_LAUNCHER)
					bprint (" tries to put the pin back in\n");
				else
					bprint (" becomes bored with life\n");
				return;
			}
			else if ( (teamplay == 2) && (targ.team > 0)&&(targ.team == attacker.team) )
			{
				if (rnum < 0.25)
					deathstring = " mows down a teammate\n";
				else if (rnum < 0.50)
					deathstring = " checks his glasses\n";
				else if (rnum < 0.75)
					deathstring = " gets a frag for the other team\n";
				else
					deathstring = " loses another friend\n";
				bprint (attacker.netname);
				bprint (deathstring);
				attacker.frags = attacker.frags - 1;
				return;
			}
			else
			{
				attacker.frags = attacker.frags + 1;

				rnum = attacker.weapon;
				if (rnum == IT_AXE)
				{
					deathstring = " was ax-murdered by ";
					deathstring2 = "\n";
				}
				if (rnum == IT_SHOTGUN)
				{
					deathstring = " chewed on ";
					deathstring2 = "'s boomstick\n";
				}
				if (rnum == IT_SUPER_SHOTGUN)
				{
					deathstring = " ate 2 loads of ";
					deathstring2 = "'s buckshot\n";
				}
				if (rnum == IT_NAILGUN)
				{
					deathstring = " was nailed by ";
					deathstring2 = "\n";
				}
				if (rnum == IT_SUPER_NAILGUN)
				{
					deathstring = " was punctured by ";
					deathstring2 = "\n";
				}
				if (rnum == IT_GRENADE_LAUNCHER)
				{
					deathstring = " eats ";
					deathstring2 = "'s pineapple\n";
					if (targ.health < -40)
					{
						deathstring = " was gibbed by ";
						deathstring2 = "'s grenade\n";
					}
				}
				if (rnum == IT_ROCKET_LAUNCHER)
				{
					deathstring = " rides ";
					deathstring2 = "'s rocket\n";
					if (targ.health < -40)
					{
						deathstring = " was gibbed by ";
						deathstring2 = "'s rocket\n" ;
					}
				}
				if (rnum == IT_LIGHTNING)
				{
					deathstring = " accepts ";
					if (attacker.waterlevel > 1)
						deathstring2 = "'s discharge\n";
					else
						deathstring2 = "'s shaft\n";
				}
				bprint (targ.netname);
				bprint (deathstring);
				bprint (attacker.netname);
				bprint (deathstring2);
			}
			return;
		}
		else
		{
			targ.frags = targ.frags - 1;
			bprint (targ.netname);

			// killed by a montser?
			if (attacker.flags & FL_MONSTER)
			{
				if (attacker.classname == "monster_army")
					bprint (" was shot by a Grunt\n");
				else if (attacker.classname == "monster_demon1")
					bprint (" was eviscerated by a Fiend\n");
				else if (attacker.classname == "monster_dog")
					bprint (" was mauled by a Rottweiler\n");
				else if (attacker.classname == "monster_enforcer")
					bprint (" was blasted by an Enforcer\n");
				else if (attacker.classname == "monster_fish")
					bprint (" was fed to the Rotfish\n");
				else if (attacker.classname == "monster_hell_knight")
					bprint (" was slain by a Death Knight\n");
				else if (attacker.classname == "monster_knight")
					bprint (" was slashed by a Knight\n");
				else if (attacker.classname == "monster_ogre")
					bprint (" was destroyed by an Ogre\n");
				else if (attacker.classname == "monster_oldone")
					bprint (" became one with Shub-Niggurath\n");
				else if (attacker.classname == "monster_shalrath")
					bprint (" was exploded by a Vore\n");
				else if (attacker.classname == "monster_shambler")
					bprint (" was smashed by a Shambler\n");
				else if (attacker.classname == "monster_tarbaby")
					bprint (" was slimed by a Spawn\n");
				else if (attacker.classname == "monster_wizard")
					bprint (" was scragged by a Scrag\n");
				else if (attacker.classname == "monster_zombie")
					bprint (" joins the Zombies\n");

				return;
			}

			// tricks and traps
			if (attacker.classname == "explo_box")
			{
				bprint (" blew up\n");
				return;
			}
			if (attacker.solid == SOLID_BSP && attacker != world)
			{
				bprint (" was squished\n");
				return;
			}
			if (attacker.classname == "trap_shooter" || attacker.classname == "trap_spikeshooter")
			{
				bprint (" was spiked\n");
				return;
			}
			if (attacker.classname == "fireball")
			{
				bprint (" ate a lavaball\n");
				return;
			}
			if (attacker.classname == "trigger_changelevel")
			{
				bprint (" tried to leave\n");
				return;
			}

			// in-water deaths
			rnum = targ.watertype;
			if (rnum == -3)
			{
				if (random() < 0.5)
					bprint (" sleeps with the fishes\n");
				else
					bprint (" sucks it down\n");
				return;
			}
			else if (rnum == -4)
			{
				if (random() < 0.5)
					bprint (" gulped a load of slime\n");
				else
					bprint (" can't exist on slime alone\n");
				return;
			}
			else if (rnum == -5)
			{
				if (targ.health < -15)
				{
					bprint (" burst into flames\n");
					return;
				}
				if (random() < 0.5)
					bprint (" turned into hot slag\n");
				else
					bprint (" visits the Volcano God\n");
				return;
			}

			// fell to their death?
			if (targ.deathtype == "falling")
			{
				targ.deathtype = "";
				bprint (" fell to his death\n");
				return;
			}

			// hell if I know; he's just dead!!!
			bprint (" died\n");
		}
	}
};

float() GetPlayerCount = 
{
	local 	entity e;
	local 	float pcount;
	e = nextent(world);
	while(e != world)
	{
		if(e.classname == "player")
		{
			pcount++;
		}
		e = nextent(e);
	}
	return pcount;
};

void() ChooseStartingZombies
{
	local entity targ;
	local float attempts, kills, pcount;
	
	pcount = GetPlayerCount();
	
	if(pcount < 5)
		kills = 1;
	else if(pcount < 10)
		kills = 2;
	else
		kills = 3;
		
	while(kills > 0)
	{
		attempts = rint((random() * pcount) + 1);
		targ = world;
		while(targ == world || attempts > 0)
		{
			targ = nextent( targ );
			if(targ.classname == "player" && targ.health > 0 && targ.isHuman && !targ.isObserver)
			{
				attempts--;
				if(attempts <= 0)
				{
					bprint(targ.netname);
					bprint(" becomes INFECTED!\n");
					targ.deathtype = "infected";
					Killed(targ, world);
				}
			}
		}
		kills--;
	}
}

void(string msg) MessageAllClients;
void(entity targ, entity attacker) Killed;
void() HostPreThink =
{
	if(gamestate == STATE_STARTING)
	{
		if(time > GAME_WARMUP_TIME + 3 + random() * 3)
		{
			ChooseStartingZombies();
			gamestate = STATE_RUNNING;
		}
	}
};

void() Host_CheckGameState;
void() HostPostThink =
{
	if(host_checkStateTime > 0)
	{
		host_checkStateTime--;
		if(host_checkStateTime <= 0)
		{
			Host_CheckGameState();
		}
	}
};

void(string msg) MessageAllClients =
{
	local 	entity e;

	e = nextent(world);
	while(e != world)
	{
		if(e.classname == "player")
		{
			centerprint(e, msg);
		}
		e = nextent(e);
	}
};

void(string s1, string s2, string s3) MessageAllClients3 =
{
	local entity e;
	local float attempts;
	e = nextent(world);
	attempts = 20;
	while(attempts > 0 && e != world)
	{
		if(e.classname == "player")
		{
			centerprint(e, s1, s2, s3);
		}
		attempts--;
		e = nextent(e);
	}
};

void() Host_CheckGameState =
{
	if(gamestate == STATE_WARMUP)
	{
		local float pnum;
		pnum = GetPlayerCount();
		if(pnum < 2)
		{
			host_checkStateTime = 500;
			MessageAllClients("Evil Lurks Close By\n(Waiting For Players...)\n");
			return;
		}
		MessageAllClients("Evil Approaches!\n");
		gamestate = STATE_STARTING;
	}
	else if(gamestate == STATE_RUNNING)
	{
		// Look for game over condition
		local entity e;
		local float humanCount, zcount;
		e = nextent(world);
		while(e != world)
		{
			if(e.classname == "player")
			{
				if(e.isHuman && !e.isObserver) // Humans
				{
					humanCount++;
				}
				else if(!e.isObserver) //Infected
				{
					zcount++;
				}
			}
			e = nextent(e);
		}

		if(humanCount > 0)
		{
			MessageAllClients3("Remaining Humans: ", ftos(humanCount), "\n\n\n");
			dprint("Still humans alive.\n");
			return;
		}
		
		//Humans win (currently only if zombies leave the game, TODO: set a timer)
		if(zcount <= 0)
		{
			dprint("Humans win!\n");
			MessageAllClients("The Living Prevail! \nHell's Minions Have Retreated for now...\n\n");
			gamestate = STATE_END;
			host_checkStateTime = 500;
		}

		// No humans left.
		dprint("Undead win!\n");
		gamestate = STATE_END;
		host_checkStateTime = 250;
		MessageAllClients("The UNDEAD have claimed the last soul!\n\n\n");
		//NextLevel();
	}
	else if(gamestate == STATE_END)
	{
		NextLevel();
	}
};

void() RemoveDropItem = 
{
	self.owner.itemdrop1 = 0;
	self.owner.itemdrop1time = time + 5 + random() * 30;
	self.owner.itemdroppos = '999 999 999';
	remove(self);
}

void() DropItemTouch =
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
	if(!other.isHuman)
		return;
	if(other.isObserver)
		return;

	sprint (other, "You get the ");
	sprint(other,self.netname);
	sprint(other,"!\n");

	if(self.items == IT_SUPERHEALTH)
	{
		T_Heal(other, self.healamount, 0);
		sound (other, CHAN_ITEM, "items/health1.wav", 1, ATTN_NORM);
	}
	else if(self.items == IT_SHELLS)
	{
		other.ammo_shells = other.ammo_shells + self.ammo_shells;
		
		sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);

		bound_other_ammo ();
		W_SetCurrentAmmo ();	
	}
	else if(self.items == IT_SUPER_SHOTGUN)
	{
		other.items = other.items + IT_SUPER_SHOTGUN;
		other.ammo_shells = other.ammo_shells + self.ammo_shells;
		
		sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);

		bound_other_ammo ();
		W_SetCurrentAmmo ();	
	}
	else if(self.items == IT_NAILGUN)
	{
		other.items = other.items + IT_NAILGUN;
		other.ammo_nails = other.ammo_nails + self.ammo_nails;
		
		sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);

		bound_other_ammo ();
		W_SetCurrentAmmo ();	
	}

	stuffcmd (other, "bf\n");

	RemoveDropItem();
};


void() DogDropItem = 
{
	local	entity item;
	local	float r;
	
	item  = spawn();
	item.origin = self.itemdroppos;

	r = random();
	//Shells
	if(r < 0.425)
	{
		item.items = IT_SHELLS;
		item.netname = "Shells";
		setmodel (item, "maps/b_shell0.bsp");
		setsize (item, '0 0 0', '32 32 56');
		item.ammo_shells = 10;
	}
	//Health
	else if(r < 0.85)
	{
		item.items = IT_SUPERHEALTH;
		item.netname = "Health";
		setmodel(item, "maps/b_bh25.bsp");
		setsize (item, '0 0 0', '32 32 56');
		item.healamount = 15;
	}
	else if(r < 0.95)
	{		
		item.items = IT_SUPER_SHOTGUN;
		item.netname = "Double-barrelled Shotgun";
		item.ammo_shells = 5;
		setmodel (item, "progs/g_shot.mdl");
		setsize (item, '-16 -16 0', '16 16 56');
	}
	else
	{		
		item.items = IT_NAILGUN;
		item.netname = "Nailgun";
		item.ammo_nails = 50;
		setmodel (item, "progs/g_nail.mdl");
		setsize (item, '-16 -16 0', '16 16 56');
	}

	dprint(self.netname);
	dprint(" dropped item.\n\n");

	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);

	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	item.touch = DropItemTouch;

	item.nextthink = time + 30;
	item.think = RemoveDropItem;

	self.itemdrop1 = item;
	item.owner = self;
};

//Impulse 110
void() ToggleObserver =
{
	dprint("ToggleObserver:: ");
	dprint(self.netname);
	if(self.isObserver)
	{
		dprint(" is no longer an observer.\n");
		self.isObserver = 0;
	}
	else
	{
		dprint(" is now an observer.\n");
		self.isObserver = "1";
	}
	PutClientInServer();
}
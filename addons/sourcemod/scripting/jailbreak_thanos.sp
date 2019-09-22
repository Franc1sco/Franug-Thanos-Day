/*  SM Jailbreak Thanos round
 *
 *  Copyright (C) 2019 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */
 

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <warden>
#include <myjbwarden>
#include <myjailbreak>
#include <myweapons>
#include <smartjaildoors>

int usuarios;

#define SOLID_NONE 0
#define FSOLID_NOT_SOLID 0x0004

new Float:MinNadeHull[3] = {-2.5, -2.5, -2.5};
new Float:MaxNadeHull[3] = {2.5, 2.5, 2.5};
new Float:SpinVel[3] = {0.0, 0.0, 200.0};
new Float:SmokeOrigin[3] = {-30.0,0.0,0.0};
new Float:SmokeAngle[3] = {0.0,-180.0,0.0};

#define MINUTES 30

bool soccer;


int g_iTime;

bool pending;


#define DATA "1.0"

int thanos;

int NadeDamage = 1000;
int NadeRadius = 350;
float NadeSpeed = 900.0;

new g_iToolsVelocity;

public Plugin myinfo = 
{
	name = "SM Jailbreak Thanos round",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	g_iToolsVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	
	HookEvent("round_prestart", Event_RoundStart);
	HookEvent("round_start", Event_RoundStartFix);
	HookEvent("round_end", Event_End);
	HookEvent("player_spawn", PlayerSpawn);
	
	HookEvent("player_jump", Event_OnPlayerJump);
	HookEvent("player_jump", Event_OnPlayerJumpPre, EventHookMode_Pre);
	
	RegAdminCmd("sm_setthanos", Command_Set, ADMFLAG_ROOT);
	RegAdminCmd("sm_thanos", Command_Soccer, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_vengadores", Command_Soccer, ADMFLAG_CUSTOM1);
	
	for (new i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				OnClientPutInServer(i);
	
}

public Action:Command_Set(client, args)
{
	if(soccer) 
	{
		ReplyToCommand(client, "Thanos round in progress already.");
		return Plugin_Handled;
	}
	
	if(args < 1) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] use: smsetthanos <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[30];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target;
	if((target = FindTarget(client, arg, false, false)) == -1)
	{
		ReplyToCommand(client, "No found");
		thanos = 0;
		return Plugin_Handled; // Target not found...
	}
	ReplyToCommand(client, "%N will be the next Thanos", target);
	thanos = target;
	
	return Plugin_Handled;
}

public OnMapStart()
{
	AddFileToDownloadsTable("models/player/custom_player/kaesar2018/thanos/thanos.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/kaesar2018/thanos/thanos.mdl");
	AddFileToDownloadsTable("models/player/custom_player/kaesar2018/thanos/thanos.phy");
	AddFileToDownloadsTable("models/player/custom_player/kaesar2018/thanos/thanos.vvd");

	AddFileToDownloadsTable("materials/models/player/kaesar2018/thanos/t_m_lrg_jim_body_d.vmt");
	AddFileToDownloadsTable("materials/models/player/kaesar2018/thanos/t_m_lrg_jim_body_d.vtf");
	AddFileToDownloadsTable("materials/models/player/kaesar2018/thanos/t_m_lrg_jim_body_n.vtf");
	AddFileToDownloadsTable("materials/models/player/kaesar2018/thanos/t_m_lrg_jim_gauntlet_d.vmt");
	AddFileToDownloadsTable("materials/models/player/kaesar2018/thanos/t_m_lrg_jim_gauntlet_d.vtf");
	AddFileToDownloadsTable("materials/models/player/kaesar2018/thanos/t_m_lrg_jim_gauntlet_n.vtf");
	AddFileToDownloadsTable("materials/models/player/kaesar2018/thanos/t_m_lrg_jim_head_d.vmt");
	AddFileToDownloadsTable("materials/models/player/kaesar2018/thanos/t_m_lrg_jim_head_d.vtf");
	AddFileToDownloadsTable("materials/models/player/kaesar2018/thanos/t_m_lrg_jim_head_n.vtf");
	AddFileToDownloadsTable("materials/models/player/kaesar2018/thanos/t_m_lrg_jim_helmet_d.vmt");
	AddFileToDownloadsTable("materials/models/player/kaesar2018/thanos/t_m_lrg_jim_helmet_d.vtf");
	AddFileToDownloadsTable("materials/models/player/kaesar2018/thanos/t_m_lrg_jim_helmet_n.vtf");

	PrecacheModel("models/player/custom_player/kaesar2018/thanos/thanos.mdl");
	
	
	AddFileToDownloadsTable("sound/music/franug_rocket1.mp3");
	
	AddFileToDownloadsTable("materials/models/weapons/w_missile/missile side.vmt");
	
	AddFileToDownloadsTable("models/weapons/W_missile_closed.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.mdl");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.phy");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.sw.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.vvd");
	
	PrecacheModel("models/weapons/w_missile_closed.mdl");
	
	PrecacheSound("music/franug_rocket1.mp3");
	PrecacheSound("weapons/hegrenade/explode5.wav");
}

public OnPluginEnd()
{
	if (!soccer && !pending)return;
	
	
	Terminar();
}

public Action Command_Soccer(int client, int args)
{
	DoVoteMenu(client);
	return Plugin_Handled;
}

void DoVoteMenu(int client)
{
	if (IsVoteInProgress())
	{
		PrintToChat(client, " \x03Already a vote in progress, wait for the end.");
		return;
	}
	
	if (MyJailbreak_IsEventDayPlanned())
	{
		PrintToChat(client, " \x03You cant use this if already a thanos day planned.");
		return;
	}
	
	if (MyJailbreak_IsEventDayRunning())
	{
		PrintToChat(client, " \x03You cant use this command when already a special day running.");
		return;
	}
	
	if (!HasPermission(client, "z") && GetTime() < (g_iTime+(MINUTES*60)))
	{
		PrintToChat(client, " \x03You cant use this, wait %i seconds more.", (g_iTime+(MINUTES*60)) - GetTime());
		return;
	}
	
	
	g_iTime = GetTime();
	
	Menu menu = new Menu(Handle_VoteMenu);
	menu.SetTitle("Start a Thanos day in the next round?");
	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");

	menu.DisplayVoteToAll(20);
}

public int Handle_VoteMenu(Menu menu, MenuAction action, int param1,int param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		delete menu;
	} else if (action == MenuAction_VoteEnd) {
		/* 0=yes, 1=no */
		if (param1 == 0)
		{
			
			pending = true;
			
			ServerCommand("sm_ratio_enable 0");
			ServerCommand("sm_ctbans_enable 0");
			
			MyJailbreak_SetEventDayName("Thanos");
			MyJailbreak_SetEventDayPlanned(true);
			
			PrintCenterTextAll("THANOS DAY START IN THE NEXT ROUND!");
			
			PrintToChatAll(" \x03THANOS DAY START IN THE NEXT ROUND!");
		}
		else
		{
			PrintToChatAll(" \x03The thanos vote was negative.");
		}
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!soccer)return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CreateTimer(3.0, Timer_Thanos, GetClientUserId(client));
	
}

public Action Timer_Thanos(Handle timer, int id)
{
	int client = GetClientOfUserId(id);
	if (!client || !IsClientInGame(client))return;
	
	if (thanos != client)
	{
		if(GetClientTeam(client) == CS_TEAM_CT)
		{
			ChangeClientTeam(client, CS_TEAM_T);
			CS_RespawnPlayer(client);
		}
		return;
	}
	
	SetEntityModel(thanos, "models/player/custom_player/kaesar2018/thanos/thanos.mdl");
	
	SetEntityGravity(thanos, 0.3);
	
	SetEntProp(thanos, Prop_Data, "m_iHealth", usuarios * 1000);
	
	GivePlayerItem(thanos, "weapon_hegrenade");
	
	SJD_OpenDoors();
	
	PrintCenterTextAll("Thanos are there!");
}

Empezar()
{	
	if(thanos == 0 || !IsClientInGame(thanos) || GetClientTeam(thanos) < 2)
		thanos = GetRandomPlayer();
		
	if (!thanos)
	{
		Terminar();
		return;
	}
	usuarios = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
			if (!IsClientInGame(i) || GetClientTeam(i) < 2)
				continue;

			usuarios++;
			if(i != thanos && GetClientTeam(i) == CS_TEAM_CT)
			{
				CS_SwitchTeam(i, CS_TEAM_T);
				//CS_RespawnPlayer(i);
			}
			else if(i == thanos && GetClientTeam(thanos) == CS_TEAM_T)
			{
				CS_SwitchTeam(i, CS_TEAM_CT);
			}
			
	}
	
	soccer = true;
	if(warden_exist())
	{
		warden_removed(warden_get());
	}
	SetCvar("sm_hosties_lr", 0);
	SetCvar("sm_menu_enable", 0);
	
	SetCvar("mp_friendlyfire", 0);
	
	MyWeapons_AllowTeam(CS_TEAM_T, true);
	MyWeapons_AllowTeam(CS_TEAM_CT, false);
	
	warden_enable(false);
	
}

Terminar()
{
	thanos = 0;
	soccer = false;
	
	MyJailbreak_SetEventDayRunning(false, 0);
	MyJailbreak_SetEventDayName("none");
	
	SetCvar("sm_hosties_lr", 1);
	SetCvar("sm_menu_enable", 1);
	
	ServerCommand("sm_ratio_enable 1");
	ServerCommand("sm_ctbans_enable 1");
	
	MyWeapons_AllowTeam(CS_TEAM_T, false);
	MyWeapons_AllowTeam(CS_TEAM_CT, true);
	
	warden_enable(true);
}

public Action Event_RoundStart(Event event, const char[] szName, bool bDontBroadcast)
{
	if (!pending && !soccer)return;
	
	Empezar();
	
	MyJailbreak_SetEventDayPlanned(false);
	MyJailbreak_SetEventDayRunning(true, 0);
	
	pending = false;
	
	ServerCommand("sm_ratio_enable 1");
	
}

public Action Event_RoundStartFix(Event event, const char[] szName, bool bDontBroadcast)
{
	if (!soccer)return;
	
	SetCvar("mp_friendlyfire", 0);
	
}

public Action Event_End(Event event, const char[] szName, bool bDontBroadcast)
{	
	if (!pending && soccer)
	{
		
		Terminar();
	}
	
}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

stock void SetCvar(char cvarName[64], int value)
{
	Handle IntCvar = FindConVar(cvarName);
	if (IntCvar == null) return;

	int flags = GetConVarFlags(IntCvar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);

	SetConVarInt(IntCvar, value);

	flags |= FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);
}

stock void SetCvarString(char cvarName[64], char[] value)
{
	Handle cvar = FindConVar(cvarName);
	SetConVarString(cvar, value, true);
}

public Action:OnWeaponCanUse(client, weapon)
{
	if (soccer && client == thanos)
	{
		// block switching to weapon other than knife
		decl String:sClassname[32];
		GetEdictClassname(weapon, sClassname, sizeof(sClassname));
		if (StrContains(sClassname, "knife") == -1 && StrContains(sClassname, "bayonet") == -1 && StrContains(sClassname, "hegrenade") == -1)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]){
	
    if(!soccer)return Plugin_Continue;
	
    if(attacker == thanos && victim != thanos){
    	
		if (!IsValidEntity(weapon)) return Plugin_Continue;
		
		new String:weaponclassname[20];
		GetEntityClassname(weapon, weaponclassname, sizeof(weaponclassname));
		if (StrContains(weaponclassname, "knife") > -1 || StrContains(weaponclassname, "bayonet") > -1)
		{
	        damage *= 60.0;
        	return Plugin_Changed;
		}
		
		return Plugin_Continue;
    }
    else{
        return Plugin_Continue;
    }
}

stock GetRandomPlayer() {

    new clients[MaxClients+1], clientCount;
    for (new i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && GetClientTeam(i) > 1)
            clients[clientCount++] = i;
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}  


public OnEntityCreated(iEntity, const String:classname[])
{
	if (!soccer)return;
	
	if (StrEqual(classname, "hegrenade_projectile", false))
	{
		HookSingleEntityOutput(iEntity, "OnUser2", InitMissile, true);
		
		new String:OutputString[50] = "OnUser1 !self:FireUser2::0.0:1";
		SetVariantString(OutputString);
		AcceptEntityInput(iEntity, "AddOutput");
		
		AcceptEntityInput(iEntity, "FireUser1");
	}
}

public Action Timer_ThanosGranada(Handle timer)
{
	if (!thanos || !IsClientInGame(thanos))return;
	
	GivePlayerItem(thanos, "weapon_hegrenade");
}

public InitMissile(const String:output[], caller, activator, Float:delay)
{
	new NadeOwner = GetEntPropEnt(caller, Prop_Send, "m_hThrower");
	
	// assume other plugins don't set this on any projectiles they create, this avoids conflicts.
	if (NadeOwner == -1 || thanos != NadeOwner)
	{
		return;
	}
	
	//ignore the projectile if this team can't use missiles.
	//new NadeTeam = GetEntProp(caller, Prop_Send, "m_iTeamNum");
	
	// stop the projectile thinking so it doesn't detonate.
	SetEntProp(caller, Prop_Data, "m_nNextThinkTick", -1);
	SetEntityMoveType(caller, MOVETYPE_FLY);
	SetEntityModel(caller, "models/weapons/w_missile_closed.mdl");
	// make it spin correctly.
	SetEntPropVector(caller, Prop_Data, "m_vecAngVelocity", SpinVel);
	// stop it bouncing when it hits something
	SetEntPropFloat(caller, Prop_Send, "m_flElasticity", 0.0);
	SetEntPropVector(caller, Prop_Send, "m_vecMins", MinNadeHull);
	SetEntPropVector(caller, Prop_Send, "m_vecMaxs", MaxNadeHull);
	
	new SmokeIndex = CreateEntityByName("env_rockettrail");
	if (SmokeIndex != -1)
	{
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_Opacity", 0.5);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_SpawnRate", 100.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_ParticleLifetime", 0.5);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_StartSize", 5.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_EndSize", 30.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_SpawnRadius", 0.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_MinSpeed", 0.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_MaxSpeed", 10.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_flFlareScale", 1.0);
		
		DispatchSpawn(SmokeIndex);
		ActivateEntity(SmokeIndex);
		
		new String:NadeName[20];
		Format(NadeName, sizeof(NadeName), "Nade_%i", caller);
		DispatchKeyValue(caller, "targetname", NadeName);
		SetVariantString(NadeName);
		AcceptEntityInput(SmokeIndex, "SetParent");
		TeleportEntity(SmokeIndex, SmokeOrigin, SmokeAngle, NULL_VECTOR);
	}
	
	// make the missile go towards the coordinates the player is looking at.
	new Float:NadePos[3];
	GetEntPropVector(caller, Prop_Send, "m_vecOrigin", NadePos);
	new Float:OwnerAng[3];
	GetClientEyeAngles(NadeOwner, OwnerAng);
	new Float:OwnerPos[3];
	GetClientEyePosition(NadeOwner, OwnerPos);
	TR_TraceRayFilter(OwnerPos, OwnerAng, MASK_SOLID, RayType_Infinite, DontHitOwnerOrNade, caller);
	new Float:InitialPos[3];
	TR_GetEndPosition(InitialPos);
	new Float:InitialVec[3];
	MakeVectorFromPoints(NadePos, InitialPos, InitialVec);
	NormalizeVector(InitialVec, InitialVec);
	ScaleVector(InitialVec, NadeSpeed);
	new Float:InitialAng[3];
	GetVectorAngles(InitialVec, InitialAng);
	TeleportEntity(caller, NULL_VECTOR, InitialAng, InitialVec);
	
	EmitSoundToAll("music/franug_rocket1.mp3", caller, 1, 90);
	
	HookSingleEntityOutput(caller, "OnUser2", MissileThink);
	
	new String:OutputString[50] = "OnUser1 !self:FireUser2::0.1:-1";
	SetVariantString(OutputString);
	AcceptEntityInput(caller, "AddOutput");
	
	AcceptEntityInput(caller, "FireUser1");
	
	SDKHook(caller, SDKHook_StartTouchPost, OnStartTouchPost);
	
	CreateTimer(3.0, Timer_ThanosGranada);

}

public MissileThink(const String:output[], caller, activator, Float:delay)
{
	// detonate any missiles that stopped for any reason but didn't detonate.
	decl Float:CheckVec[3];
	GetEntPropVector(caller, Prop_Send, "m_vecVelocity", CheckVec);
	if (((CheckVec[0] == 0.0) && (CheckVec[1] == 0.0) && (CheckVec[2] == 0.0)))
	{
		StopSound(caller, 1, "music/franug_rocket1.mp3");
		CreateExplosion(caller);
		return;
	}
	
	//decl Float:NadePos[3];
	//GetEntPropVector(caller, Prop_Send, "m_vecOrigin", NadePos);
	//new client = GetEntPropEnt(data, Prop_Send, "m_hThrower");
/* 	new dado = GetTraceHullEntityIndex(NadePos, caller);
	if(IsClientIndex(dado) && ZR_IsClientZombie(dado))
	{
		StopSound(caller, 1, "music/franug_rocket1.mp3");
		CreateExplosion(caller);
		return;
	} */
	
	
	
	AcceptEntityInput(caller, "FireUser1");
}

/* GetTraceHullEntityIndex(Float:pos[3], xindex) {

	TR_TraceHullFilter(pos, pos, g_fMinS, g_fMaxS, MASK_SHOT, THFilter, xindex);
	return TR_GetEntityIndex();
}

public bool:THFilter(entity, contentsMask, any:data) {

	return IsClientIndex(entity) && (entity != data);
} 

bool:IsClientIndex(index) {

	return (index > 0) && (index <= MaxClients);
}*/

public bool:DontHitOwnerOrNade(entity, contentsMask, any:data)
{
	new NadeOwner = GetEntPropEnt(data, Prop_Send, "m_hThrower");
	return ((entity != data) && (entity != NadeOwner));
}

public OnStartTouchPost(entity, other) 
{
	// detonate if the missile hits something solid.
	if ((GetEntProp(other, Prop_Data, "m_nSolidType") != SOLID_NONE) && (!(GetEntProp(other, Prop_Data, "m_usSolidFlags") & FSOLID_NOT_SOLID)))
	{
		StopSound(entity, 1, "music/franug_rocket1.mp3");
		CreateExplosion(entity);
	}
}

CreateExplosion(entity)
{
	UnhookSingleEntityOutput(entity, "OnUser2", MissileThink);
	
 	new Float:MissilePos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", MissilePos);
	new MissileOwner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	new MissileOwnerTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	
	AcceptEntityInput(entity, "Kill");
	
	new ExplosionIndex = CreateEntityByName("env_explosion");
	if (ExplosionIndex != -1)
	{
		DispatchKeyValue(ExplosionIndex,"classname","hegrenade_projectile");
		
		SetEntProp(ExplosionIndex, Prop_Data, "m_spawnflags", 6146);
		SetEntProp(ExplosionIndex, Prop_Data, "m_iMagnitude", NadeDamage);
		SetEntProp(ExplosionIndex, Prop_Data, "m_iRadiusOverride", NadeRadius);
		
		DispatchSpawn(ExplosionIndex);
		ActivateEntity(ExplosionIndex);
		
		TeleportEntity(ExplosionIndex, MissilePos, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(ExplosionIndex, Prop_Send, "m_hOwnerEntity", MissileOwner);
		SetEntProp(ExplosionIndex, Prop_Send, "m_iTeamNum", MissileOwnerTeam);
		
		EmitSoundToAll("weapons/hegrenade/explode5.wav", ExplosionIndex, 1, 90);
		
		AcceptEntityInput(ExplosionIndex, "Explode");
		
		DispatchKeyValue(ExplosionIndex,"classname","env_explosion");
		
		AcceptEntityInput(ExplosionIndex, "Kill");
	} 
	
/* 	new Float:SmokeOrigin2[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", SmokeOrigin2);
	new client = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	new userid = GetClientUserId(client);
		
	new Handle:event = CreateEvent("hegrenade_detonate");
		
	SetEventInt(event, "userid", userid);
	SetEventFloat(event, "x", SmokeOrigin2[0]);
	SetEventFloat(event, "y", SmokeOrigin2[1]);
	SetEventFloat(event, "z", SmokeOrigin2[2]);
	FireEvent(event); */
}

#define HEIGHT 2.0
#define LENGTH 1.0

public Action:Event_OnPlayerJumpPre(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (!soccer)return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client != thanos)return;
	
	SetEntityGravity(thanos, 0.3);
}

public Action:Event_OnPlayerJump(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (!soccer)return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client != thanos)return;
	
	CreateTimer(0.0, EventPlayerJumpPost, client);
}

public Action:EventPlayerJumpPost(Handle:timer, any:client)
{
    // If client isn't in-game, then stop.
    if (!IsClientInGame(client))
    {
        return;
    }
    
    // Forward event to modules.
    JumpBoostOnClientJumpPost(client);
}

/**
 * Client is jumping.
 * 
 * @param client    The client index.
 */
JumpBoostOnClientJumpPost(client)
{
    // Get class jump multipliers.
    new Float:distancemultiplier = LENGTH;
    new Float:heightmultiplier = HEIGHT;
    
    // If both are set to 1.0, then stop here to save some work.
    if (distancemultiplier == 1.0 && heightmultiplier == 1.0)
    {
        return;
    }
    
    new Float:vecVelocity[3];
    
    // Get client's current velocity.
    ToolsClientVelocity(client, vecVelocity, false);
    
    // Only apply horizontal multiplier if it's not a bhop.
    if (!JumpBoostIsBHop(vecVelocity))
    {
        // Apply horizontal multipliers to jump vector.
        vecVelocity[0] *= distancemultiplier;
        vecVelocity[1] *= distancemultiplier;
    }
    
    // Apply height multiplier to jump vector.
    vecVelocity[2] *= heightmultiplier;
    
    // Set new velocity.
    ToolsClientVelocity(client, vecVelocity, true, false);
}

/**
 * This function detects excessive bunnyhopping.
 * Note: This ONLY catches bunnyhopping that is worse than CS:S already allows.
 * 
 * @param vecVelocity   The velocity of the client jumping.
 * @return              True if the client is bunnyhopping, false if not.
 */
stock bool:JumpBoostIsBHop(const Float:vecVelocity[])
{
    // Calculate the magnitude of jump on the xy plane.
    new Float:magnitude = SquareRoot(Pow(vecVelocity[0], 2.0) + Pow(vecVelocity[1], 2.0));
    
    // Return true if the magnitude exceeds the max.
    new Float:bunnyhopmax = 300.0;
    return (magnitude > bunnyhopmax);
}

stock ToolsClientVelocity(client, Float:vecVelocity[3], bool:apply = true, bool:stack = true)
{
    // If retrieve if true, then get client's velocity.
    if (!apply)
    {
        // x = vector component.
        for (new x = 0; x < 3; x++)
        {
            vecVelocity[x] = GetEntDataFloat(client, g_iToolsVelocity + (x*4));
        }
        
        // Stop here.
        return;
    }
    
    // If stack is true, then add client's velocity.
    if (stack)
    {
        // Get client's velocity.
        new Float:vecClientVelocity[3];
        
        // x = vector component.
        for (new x = 0; x < 3; x++)
        {
            vecClientVelocity[x] = GetEntDataFloat(client, g_iToolsVelocity + (x*4));
        }
        
        AddVectors(vecClientVelocity, vecVelocity, vecVelocity);
    }
    
    // Apply velocity on client.
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

stock bool HasPermission(int iClient, char[] flagString) 
{
	if (StrEqual(flagString, "")) 
	{
		return true;
	}
	
	AdminId admin = GetUserAdmin(iClient);
	
	if (admin != INVALID_ADMIN_ID)
	{
		int count, found, flags = ReadFlagString(flagString);
		for (int i = 0; i <= 20; i++) 
		{
			if (flags & (1<<i)) 
			{
				count++;
				
				if (GetAdminFlag(admin, view_as<AdminFlag>(i))) 
				{
					found++;
				}
			}
		}

		if (count == found) {
			return true;
		}
	}

	return false;
} 
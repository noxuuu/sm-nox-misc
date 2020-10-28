/*
	smoke_colors_red  - nox_smoke_red - 166, 21, 21
	smoke_colors_green - nox_smoke_green - 42, 133, 2
	smoke_colors_blue - nox_smoke_blue - 51, 102, 218
	smoke_colors_pink - nox_smoke_pink - 230, 8, 1701
	smoke_colors_orange - nox_smoke_orange - 181, 96, 13
*/

#pragma semicolon 1 
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

Handle g_hTimerScreenEffect[64];
float g_fTimerReset;
int g_iSmokeCount, g_iCountDown[64];

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("smokegrenade_detonate", Event_SmokeDetonate, EventHookMode_Pre);
	AddTempEntHook("EffectDispatch", TE_EffectDispatch);
}

public void OnMapStart()
{
	g_iSmokeCount = 0;
	AddFileToDownloadsTable("particles/nox_smokes.pcf");
	PrecacheGeneric("particles/nox_smokes.pcf", true);
	
	PrecacheParticleEffect("nox_smoke_red");
	PrecacheParticleEffect("nox_smoke_green");
	PrecacheParticleEffect("nox_smoke_blue");
	PrecacheParticleEffect("nox_smoke_pink");
	PrecacheParticleEffect("nox_smoke_orange");
}

public void OnMapEnd()
{
	for(int i=1; i < MaxClients; i++)
	{
		if(g_hTimerScreenEffect[i] != INVALID_HANDLE)
		{
			CloseHandle(g_hTimerScreenEffect[i]);
			g_hTimerScreenEffect[i] = INVALID_HANDLE;
		}
	}
}

public void Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	for(int i=1; i < MaxClients; i++)
	{
		if(g_hTimerScreenEffect[i] != INVALID_HANDLE)
		{
			CloseHandle(g_hTimerScreenEffect[i]);
			g_hTimerScreenEffect[i] = INVALID_HANDLE;
		}
	}
}

public void Event_SmokeDetonate(Handle event, char[] name, bool dontBroadcast)
{
	if(g_iSmokeCount > 64) return;

	float smoke_origin[3], projectile_origin[3];
	smoke_origin[0] = GetEventFloat(event, "x");
	smoke_origin[1] = GetEventFloat(event, "y");
	smoke_origin[2] = GetEventFloat(event, "z");
	
	int index;
	while((index = FindEntityByClassname(index, "smokegrenade_projectile")) != -1)
	{
		GetEntPropVector(index, Prop_Send, "m_vecOrigin", projectile_origin);
		if(projectile_origin[0] == smoke_origin[0] && projectile_origin[1] == smoke_origin[1] && projectile_origin[2] == smoke_origin[2])
		{
			int iRgb[3];
			char sEffectName[64];
			GetRandomColor(iRgb, sEffectName, sizeof(sEffectName));
			CreateParticle(index, sEffectName, projectile_origin, NULL_VECTOR, 20.0);
			
			g_iCountDown[g_iSmokeCount] = 0;
			
			DataPack info_pack = new DataPack();
			info_pack.WriteCell(g_iSmokeCount);
			info_pack.WriteCell(iRgb[0]);
			info_pack.WriteCell(iRgb[1]);
			info_pack.WriteCell(iRgb[2]);
			info_pack.WriteFloat(projectile_origin[0]);
			info_pack.WriteFloat(projectile_origin[1]);
			info_pack.WriteFloat(projectile_origin[2]);
	
			g_hTimerScreenEffect[g_iSmokeCount] = CreateTimer(0.1, TimerData_ScreenEffect, info_pack, TIMER_REPEAT);

			AcceptEntityInput(index, "Kill");
			
			float now = GetEngineTime();
			if(now >= g_fTimerReset)
			{
				g_fTimerReset = now + 60.0;
				g_iSmokeCount = 0;
			}  
			
			g_iSmokeCount++;			
		}
	}	
}

public Action TimerData_ScreenEffect(Handle timer, DataPack info_pack)
{	
	info_pack.Reset(); // Get some info !
	int index = info_pack.ReadCell();
	
	int iRgb[3];
	iRgb[0] = info_pack.ReadCell();
	iRgb[1] = info_pack.ReadCell();
	iRgb[2] = info_pack.ReadCell();
	
	float fPos[3];
	fPos[0] = info_pack.ReadFloat();
	fPos[1] = info_pack.ReadFloat();
	fPos[2] = info_pack.ReadFloat();
	
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			float fCpos[3];
			GetClientEyePosition(i, fCpos);
			
			float alpha, distance = GetVectorDistance(fCpos, fPos);
			
			if(distance > 0 && distance <= 150)
				alpha = 255.0 - (distance - 65) / (150 - 65) * (255.0 - 180.0);
			else if(distance >= 150 && distance <= 160)
				alpha = 255.0 - (distance - 150) / (160 - 150) * 180.0;
			else
				alpha = 0.0;

			if(alpha < 0) alpha = 0.0;
			if(alpha > 255.0) alpha = 255.0;
			
			if(distance < 160)
				ScreenEffect(i, 10, 100, 0, iRgb[0], iRgb[1], iRgb[2], RoundFloat(alpha));
		}
	}	
	
	if(g_iCountDown[index] >= 170)
		ClearTimer(g_hTimerScreenEffect[index]);

	g_iCountDown[index]++;
}

public Action TE_EffectDispatch(const char[] te_name, const int[] Players, int numClients, float delay)
{
	int iEffectIndex = TE_ReadNum("m_iEffectName");
	char sEffectName[64];
	GetEffectName(iEffectIndex, sEffectName, sizeof(sEffectName));
	
	int nHitBox = TE_ReadNum("m_nHitBox");
	
	if(StrEqual(sEffectName, "ParticleEffect"))
	{
		char sParticleEffectName[64];
		GetParticleEffectName(nHitBox, sParticleEffectName, sizeof(sParticleEffectName));
	
		if(StrEqual(sParticleEffectName, "explosion_smokegrenade", false))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

stock void ScreenEffect(int client, int duration, int hold_time, int flag, int red, int green, int blue, int alpha)
{
    Handle hFade = INVALID_HANDLE;
    
    if(client)
	   hFade = StartMessageOne("Fade", client);
	else
	   hFade = StartMessageAll("Fade");
	
    if(hFade != INVALID_HANDLE)
	{
        if(GetUserMessageType() == UM_Protobuf)
        {
            int clr[4];
            clr[0]=red;
            clr[1]=green;
            clr[2]=blue;
            clr[3]=alpha;
            PbSetInt(hFade, "duration", duration);
            PbSetInt(hFade, "hold_time", hold_time);
            PbSetInt(hFade, "flags", flag);
            PbSetColor(hFade, "clr", clr);
        }
        else
        {
        	BfWriteShort(hFade, duration);
        	BfWriteShort(hFade, hold_time);
        	BfWriteShort(hFade, flag);
        	BfWriteByte(hFade, red);
        	BfWriteByte(hFade, green);
        	BfWriteByte(hFade, blue);	
        	BfWriteByte(hFade, alpha);
        }
    	EndMessage();
    }
}

public void GetRandomColor(int iRgb[3], char[] sEffectName, int maxlength)
{
	char sName[64];
	
	switch(GetRandomInt(0, 4))
	{
		case 0:{
			sName = "nox_smoke_orange";
			iRgb[0] = 181;
			iRgb[1] = 96;
			iRgb[2] = 13;
		}
		
		case 1:{
			sName = "nox_smoke_blue";
			iRgb[0] = 51;
			iRgb[1] = 102;
			iRgb[2] = 218;
		}
		
		case 2:{
			sName = "nox_smoke_red";
			iRgb[0] = 166;
			iRgb[1] = 21;
			iRgb[2] = 21;
		}
		
		case 3:{
			sName = "nox_smoke_green";
			iRgb[0] = 42;
			iRgb[1] = 133;
			iRgb[2] = 2;
		}
		
		case 4:{
			sName = "nox_smoke_pink";
			iRgb[0] = 230;
			iRgb[1] = 8;
			iRgb[2] = 170;
		}
	}
	strcopy(sEffectName, maxlength, sName);
} 

void CreateParticle(int ent, char[] particleType, float Pos[3], float Ang[3], float time=10.0)
{
	int particle = CreateEntityByName("info_particle_system");

	PrecacheParticleEffect(particleType);
	if(IsValidEdict(particle))
	{
		PrecacheParticleEffect(particleType);
		char tName[128];

		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		TeleportEntity(particle, Pos, Ang, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		CreateTimer(time, Timer_DeleteParticle, particle);
	}
}

// -- particles system --
public Action Timer_DeleteParticle(Handle timer, any particle)
{
    if(IsValidEntity(particle))
    {
        char classname[128];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
            RemoveEdict(particle);
    }
}

stock void PrecacheParticleEffect(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	
	if(table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	bool save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

stock void GetEffectName(int index, char[] sEffectName, int maxlen)
{
	static int table = INVALID_STRING_TABLE;
	
	if(table == INVALID_STRING_TABLE)
		table = FindStringTable("EffectDispatch");
	
	ReadStringTable(table, index, sEffectName, maxlen);
}

stock void GetParticleEffectName(int index, char[] sEffectName, int maxlen)
{
	static int table = INVALID_STRING_TABLE;
	
	if(table == INVALID_STRING_TABLE)
		table = FindStringTable("ParticleEffectNames");
	
	ReadStringTable(table, index, sEffectName, maxlen);
}

stock int GetParticleEffectIndex(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	
	if(table == INVALID_STRING_TABLE)
		table = FindStringTable("ParticleEffectNames");
	
	int iIndex = FindStringIndex(table, sEffectName);
	if(iIndex != INVALID_STRING_INDEX)
		return iIndex;
	
	return 0;
}

stock void ClearTimer(Handle &timer)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }     
}
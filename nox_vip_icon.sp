#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int g_iIcon[MAXPLAYERS+1];
char sIconPath[128];

public OnPluginStart()
{
	HookEvent("player_spawn",	Event_PlayerSpawn);
	HookEvent("player_death",	Event_KillIcon);
	HookEvent("player_team",	Event_KillIcon);
}

public Event_KillIcon(Handle:hEvent, const String:sEvName[], bool:bDontBroadcast)
{	
	RemoveIcon(GetClientOfUserId(GetEventInt(hEvent, "userid")));
}

public Action Event_PlayerSpawn(Handle event, const char[] Player_Name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(ClientHaveFlags(client))
	{
		RemoveIcon(client);
		CreateIcon(client);
	}
}

public OnMapStart()
{
	PrecacheModel(sIconPath);
}

RemoveIcon(client)
{
	if (g_iIcon[client] != -1 && IsValidEntity(g_iIcon[client]))
	{
		//RemoveEdict(g_iIcon[client]);
		AcceptEntityInput(g_iIcon[client], "Kill");
	}

	g_iIcon[client] = -1;
}

public OnClientDisconnect(client)
{
	g_iIcon[client] = -1;
}

public OnClientPutInServer(client)
{
	g_iIcon[client] = -1;
}

CreateIcon(client)
{
	RemoveIcon(client);
	
	g_iIcon[client] = CreateEntityByName("env_sprite_oriented");

	if(g_iIcon[client] != -1)
	{
		DispatchKeyValue(g_iIcon[client], "classname", "env_sprite_oriented");
		DispatchKeyValue(g_iIcon[client], "spawnflags", "1");
		DispatchKeyValue(g_iIcon[client], "scale", "0.3");
		DispatchKeyValue(g_iIcon[client], "rendermode", "1");
		DispatchKeyValue(g_iIcon[client], "rendercolor", "255 255 255");
		DispatchKeyValue(g_iIcon[client], "model", sIconPath);
		if(DispatchSpawn(g_iIcon[client]))
		{
			decl Float:fPos[3];
			GetClientAbsOrigin(client, fPos);
			fPos[2] += 90.0;
			TeleportEntity(g_iIcon[client], fPos, NULL_VECTOR, NULL_VECTOR);

			SetVariantString("!activator");
			AcceptEntityInput(g_iIcon[client], "SetParent", client, g_iIcon[client]);
			
			SetEntPropEnt(g_iIcon[client], Prop_Send, "m_hOwnerEntity", client);
			
			SDKHook(g_iIcon[client], SDKHook_SetTransmit, OnTransmit);
		}
	}
}

public Action OnTransmit(iEntity, client)
{
	if(g_iIcon[client] == iEntity)
		return Plugin_Continue;

	static iOwner, iTeam;

	iTeam = GetClientTeam(client);

	if(iTeam < 2)
		return Plugin_Continue;
	
	if ((iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity")) > 0 && GetClientTeam(iOwner) != iTeam)
		return Plugin_Handled;

	return Plugin_Continue;
}

bool ClientHaveFlags(int client)
{
    if(CheckCommandAccess(client, "Admin_Custom1", ADMFLAG_CUSTOM1, false))
    {
        return true;
    }
    return false;
}
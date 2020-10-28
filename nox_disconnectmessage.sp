#include <sourcemod>

public Plugin myinfo = 
{
	name = "Disconnect message [sid]", 
	author = "n.o.x", 
	description = "", 
	version = "1.0", 
	url = "http://noxsp.eu"
}

public void OnPluginStart()
{
	HookEvent("player_disconnect", silent, EventHookMode_Pre);
}

public Action silent(Event event, const char[] name, bool dontBroadcast)
{
	SetEventBroadcast(event, true);
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	char authid[64];
	GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
	PrintToChatAll(" \x04%N \x05[%s] \x06wyszedł z serwera!", client, authid);
}
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define NEW_IP "193.70.125.249:27015"

public Plugin myinfo = 
{
	name = "Server Redirect Info",
	author = "n.o.x",
	description = "Kickuje dając informacje o nowym IP serwera.",
	version = "0.1",
	url = "http://cs-4frags.pl"
};

int Czas = 0;

public OnPluginStart()
{
	HookEvent("player_team", Event_PlayerTeam);
}

public Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(1.0, Info, client, TIMER_REPEAT);
	Czas = 5;
}

public Action Info(Handle timer, any client)
{
	if(Czas)
	{
		PrintToChat(client, " \x02Serwer zmienił IP ! Dostaniesz kicka za %d sekund.", Czas);
		PrintToChat(client, " \x02NOWE IP: %s.", NEW_IP);
		if(Czas == 1)
		{
			PrintToConsole(client, "==========================");
			PrintToConsole(client, "Serwer został przeniesiony na nowe IP.");
			PrintToConsole(client, "Nowe IP: %s", NEW_IP);
			PrintToConsole(client, "==========================");
		}
		Czas--;
		return Plugin_Continue;
	}
	PrintToConsole(client, "==========================");
	PrintToConsole(client, "Serwer został przeniesiony na nowe IP.");
	PrintToConsole(client, "Nowe IP: %s", NEW_IP);
	PrintToConsole(client, "==========================");
	KickClient(client, "Nowe IP: %s\n Wiecej info w konsoli.", NEW_IP);
	return Plugin_Stop;
}
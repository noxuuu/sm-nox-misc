#pragma semicolon 1

#include <sourcemod>
#include <emitsoundany>

public Plugin myinfo = 
{
	name = "[n.o.x] Join Sound",
	author = "n.o.x",
	description = "Plays join sound when map is loading.",
	version = "1.0",
	url = "http://noxsp.pl"
};

public OnMapStart()
{	
	AddFileToDownloadsTable("sound/nwx_joinsound.mp3");
	PrecacheSoundAny("nwx_joinsound.mp3", true);
}

public OnClientPostAdminCheck(client)
{
	EmitSoundToClientAny(client, "*/nwx_joinsound.mp3");
}
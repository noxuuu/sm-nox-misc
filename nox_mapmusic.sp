#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define LoopValidClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1))
	
int g_iSoundEnts[2048];
int g_iNumSounds;

bool disabled[MAXPLAYERS+1];
Handle Cookie_SaveInfo;

public Plugin:myinfo =
{
	name = "[n.o.x] Stop Map Music",
	author = "n.o.x",
	description = "Stop Map Music with preferences",
	version = "1.0b",
	url = "http://noxsp.pl"
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	RegConsoleCmd("sm_music", Command_StopMusic);
	RegConsoleCmd("sm_muzyka", Command_StopMusic);
	
	Cookie_SaveInfo = RegClientCookie("nox_mapmusic", "Check client map music preferences", CookieAccess_Private);
	
	LoopValidClients(i)
		OnClientCookiesCached(i);
}

public void OnClientCookiesCached(int client)
{
	char sDisabled[4];
	GetClientCookie(client, Cookie_SaveInfo, sDisabled, 3);
	disabled[client] = GetBooleanValue(StringToInt(sDisabled));
}

public void OnClientDisconnect(int client)
{
	if(IsClientInGame(client))
	{
		if(AreClientCookiesCached(client))
		{
			char sDisabled[4];
			Format(sDisabled, 3, "%s", disabled[client]?"1":"0");
			SetClientCookie(client, Cookie_SaveInfo, sDisabled);
		}
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iNumSounds = 0;
	
	decl String:sSound[PLATFORM_MAX_PATH];
	int entity = INVALID_ENT_REFERENCE;
	
	while ((entity = FindEntityByClassname(entity, "ambient_generic")) != INVALID_ENT_REFERENCE)
	{
		GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
		
		int len = strlen(sSound);
		if (len > 4 && (StrEqual(sSound[len-3], "mp3") || StrEqual(sSound[len-3], "wav")))
			g_iSoundEnts[g_iNumSounds++] = EntIndexToEntRef(entity);
	}
	CreateTimer(0.3, Post_Start);
}

public Action Post_Start(Handle timer)
{
	char sSound[PLATFORM_MAX_PATH];
	int entity = INVALID_ENT_REFERENCE;
	
	for(int i=1;i<=MaxClients;i++)
	{
		if(!disabled[i] || !IsClientInGame(i))
			continue;
		
		for (int u=0; u<g_iNumSounds; u++)
		{
			entity = EntRefToEntIndex(g_iSoundEnts[u]);
			if (entity != INVALID_ENT_REFERENCE)
			{
				GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
				Client_StopSound(i, entity, SNDCHAN_STATIC, sSound);
			}
		}
	}
	return Plugin_Stop;
}

public Action Command_StopMusic(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	PrintToChatAll(disabled[client]?"on":"off");
	
	Menu menu = new Menu(MenuHandler_ChangeOption);
	menu.SetTitle("Zmień preferencje muzyki");
	menu.AddItem(disabled[client]?"on":"off", disabled[client]?"Muzyka mapy [OFF] ":"Muzyka mapy [ON]");
	menu.ExitButton = true;
	menu.Display(client, 20);
	return Plugin_Handled;
}

public int MenuHandler_ChangeOption(Menu menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			
			PrintToChatAll(sItem);
			
			if(StrEqual(sItem, "on"))
				disabled[param1] = false;
			else if(StrEqual(sItem, "off"))
			{
				char sSound[PLATFORM_MAX_PATH];
				int entity;
				
				for (int i = 0; i < g_iNumSounds; i++)
				{
					entity = EntRefToEntIndex(g_iSoundEnts[i]);
					
					if (entity != INVALID_ENT_REFERENCE)
					{
						GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
						Client_StopSound(param1, entity, SNDCHAN_STATIC, sSound);
					}
				}
				disabled[param1] = true;
			}
			
			Command_StopMusic(param1, 0);
		}
		case MenuAction_End:delete menu;
	}
	return 0;
}

public bool GetBooleanValue(int integer)
{
	if(integer)
		return true;
	return false;
}

stock void Client_StopSound(int client, int entity, int channel, const char[] name)
{
	EmitSoundToClient(client, name, entity, channel, SNDLEVEL_NONE, SND_STOP, 0.0, SNDPITCH_NORMAL, _, _, _, true);
}

stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}
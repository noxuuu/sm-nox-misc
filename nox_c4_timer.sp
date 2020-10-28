#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <emitsoundany>

Handle g_hTimer;
int Czas = 0;

public Plugin myinfo = 
{
	name = "C4 Timer",
	author = "n.o.x",
	description = "Odliczanie do wybuchu bomby z muzyką",
	version = "0.1",
	url = "http://cs-4frags.pl"
};

public OnPluginStart()
{	
	HookEvent("bomb_planted", EventBombPlanted, EventHookMode_Pre);
	HookEvent("bomb_exploded", EventBombExploded, EventHookMode_PostNoCopy);
	HookEvent("bomb_defused", EventBombDefused, EventHookMode_Post);
	
	HookEvent("round_end", EventRoundEnd);
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/nwx/nox_c4.mp3");
    PrecacheSoundAny("nwx/nox_c4.mp3");
}

public Action EventBombPlanted(Handle event, const char[] name, bool dontBroadcast)
{
	Handle c4time = FindConVar("mp_c4timer");
	Czas = GetConVarInt(c4time) - 1;
	
	g_hTimer = CreateTimer(1.0, BombInfo, _, TIMER_REPEAT);
	
	return Plugin_Continue;
}

public EventBombDefused(Handle event, const char[] name, bool dontBroadcast)
{
	Czas = 0;
	
	ResetInfo();
	
	for(int i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			PrintHintText(i, "<font color='#66FF66'>Bomba została rozbrojona</font>");
			StopSoundAny(i, SNDCHAN_AUTO, "nwx/nox_c4.mp3");
		}
	}
}

public EventBombExploded(Handle event, const String:name[], bool dontBroadcast)
{
	Czas = 0;
	
	ResetInfo();
	
	for(int i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			StopSoundAny(i, SNDCHAN_AUTO, "nwx/nox_c4.mp3");
		}
	}
}

public EventRoundEnd(Handle event, const String:name[], bool dontBroadcast)
{
	Czas = 0;
	
	ResetInfo();
}

public Action BombInfo(Handle timer)
{
	if(Czas == 0)
	{
		ResetInfo();
		return Plugin_Stop;
	}
	
	for(int i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			if(Czas == 15)
				EmitSoundToClientAny(i, "nwx/nox_c4.mp3", _, _, _, _, 0.3); 
				
			//EmitSoundToClient(i, "*/nwx_c4.mp3", _, _, _ ,_, 0.3);
			
			if(Czas <= 15)
				PrintHintText(i, "<font color='#00FF00'>Bomba pierdolnie za:</font> <font color='#FF0000'>%d</font>", Czas);
		}
	}
	
	Czas -= 1;
	return Plugin_Continue;
}

void ResetInfo()
{
	if(g_hTimer != null)
	{
		KillTimer(g_hTimer);
		g_hTimer = null;
	}
}
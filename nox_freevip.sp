#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>

#pragma newdecls required
#define LoopValidClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1))
	
int iVipTime[MAXPLAYERS+1];
Handle HTimer_SubstractMinutes;
Handle Cookie_VipTime;

public Plugin myinfo =
{
	name = "[NOX] ~~ FreeVip", 
	author = "n.o.x", 
	description = "Pozwala na aktywacje darmowego vipa [1H]", 
	version = "0.1"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_freevip", CMD_DarmowyVIP);
	
	Cookie_VipTime = RegClientCookie("nox_freevip", "Check whether player have trial vip access", CookieAccess_Private);
	
	LoopValidClients(i)
		OnClientCookiesCached(i);
}

public void OnMapStart()
{
	HTimer_SubstractMinutes = CreateTimer(60.0, Timer_UsunMinute, _, TIMER_REPEAT);
}

public void OnMapEnd()
{
	KillTimer(HTimer_SubstractMinutes, false);
	HTimer_SubstractMinutes = INVALID_HANDLE;
}

public void OnClientPutInServer(int client)
{
	if (0 < iVipTime[client])
	{
		SetUserFlagBits(client, ADMFLAG_RESERVATION);
		SetUserFlagBits(client, ADMFLAG_CUSTOM6);
	}
}

public void OnClientDisconnect(int client)
{
	if(IsClientInGame(client))
	{
		if(AreClientCookiesCached(client))
		{
			char PozostalyCzas[4];
			Format(PozostalyCzas, 3, "%i", iVipTime[client]);
			SetClientCookie(client, Cookie_VipTime, PozostalyCzas);
		}
	}
}

public void OnClientCookiesCached(int client)
{
	char PozostalyCzas[4];
	GetClientCookie(client, Cookie_VipTime, PozostalyCzas, 3);
	iVipTime[client] = StringToInt(PozostalyCzas, 10);
}

public Action CMD_DarmowyVIP(int client, int args)
{
	if(GetAdminFlag(GetUserAdmin(client), Admin_Custom6) && iVipTime[client] < 1)
	{
		PrintToChat(client, "\x04[~FreeVip] \x02Nie możesz użyć tej komendy ponieważ posiadasz juz VIP'a !");
		return Plugin_Handled;
	}
	else if(iVipTime[client] == -1)
	{
		PrintToChat(client, "\x04[~FreeVip] \x02Nie możesz użyć tej komendy ponieważ wykorzystałeś już darmowego VIP'a !");
		return Plugin_Handled;
	}
	else if (0 < iVipTime[client])
	{
		PrintToChat(client, "\x04[~FreeVip] \x02Już posiadasz darmowego VIP'a ! Pozostało ci \x04%i \x02minut !", iVipTime[client]);
		return Plugin_Handled;
	}
	
	iVipTime[client] = 60;
	SetUserFlagBits(client, ADMFLAG_RESERVATION);
	SetUserFlagBits(client, ADMFLAG_CUSTOM6);
	PrintToChat(client, " \x02Właśnie aktywowałeś darmowego vip'a na godzine !");
	return Plugin_Handled;
}

public Action Timer_UsunMinute(Handle timer)
{
	if (timer == HTimer_SubstractMinutes)
	{
		LoopValidClients(i)
		{
			if(0 < iVipTime[i])
			{
				iVipTime[i] -= 1;
				if(iVipTime[i] == 0)
				{
					iVipTime[i] = -1;
					SetUserFlagBits(i, 0);
					PrintToChatAll(" \x04Graczowi \x02%N \x04właśnie skończył się się \x02DARMOWY VIP ! \x04Aby odebrać \x02darmowego VIP'a \x04wpisz \x02!freevip", i);
				}
			}
		}
	}
}

stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}
#pragma semicolon 1

#include <sdktools>
#include <multicolors>

#pragma newdecls required

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)\
if(IsClientInGame(%1))

#define 	TAG		"{olive}★ {orange}NoScope {olive}★{default}"

Handle g_hSql;

int kills[MAXPLAYERS+1];
int headshots[MAXPLAYERS+1];
float g_fDistance[MAXPLAYERS+1];

public void OnPluginStart()
{
	// player commands
	RegConsoleCmd("sm_noscope", CMD_Panel);

	// player events
	HookEvent("round_end", RoundEnd);
	HookEvent("player_death", OnPlayerDeath);

	// MySql shit
	DB_Connect();
}

public Action CMD_Panel(int client, int args)
{
	Menu menu = new Menu(Menu_Handler, MENU_ACTIONS_ALL);
	menu.SetTitle("[NOX] NoScope rank\n \n");
	menu.AddItem("PlayerStats", "Statystyki gracza");
	menu.AddItem("TopDistance", "[TOP 100] NoScope");
	menu.Display(client, 0);
	
	return Plugin_Handled;
}

public int Menu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char Item[32];
			menu.GetItem(param2, Item, sizeof(Item));

			if(StrEqual(Item, "PlayerStats"))
				CreateMenu_Player(param1);
			else if(StrEqual(Item, "TopDistance"))
				CMD_Top(param1, 0);
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

public void CreateMenu_Player(int client)
{
	Panel panel = CreatePanel();
	SetPanelTitle(panel, "[NoScope] Statystyki");
	DrawPanelText(panel, "^-.-^-.-^-.-^");

	char buffer[256];

	Format(buffer, sizeof(buffer), "Zabójstw: %d", kills[client]);
	DrawPanelText(panel, buffer);
	
	Format(buffer, sizeof(buffer), "Headshotów: %d", headshots[client]);
	DrawPanelText(panel, buffer);
	
	Format(buffer, sizeof(buffer), "Najdłuższy dystans: %.f", g_fDistance[client]);
	DrawPanelText(panel, buffer);

	DrawPanelItem(panel, "Exit");
	DrawPanelText(panel, "^-.-^-.-^-.-^");
	
	SendPanelToClient(panel, client, Handler_DoNothing, 60);
}

public int Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
		delete menu;
	return 0;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	DB_LoadInfo(client);
}

public void OnClientDisconnect(int client)
{
	DB_SaveInfo(client);
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	LoopClients(i)
		DB_SaveInfo(i);
}

public Action DB_Connect()
{
	if(SQL_CheckConfig("nox_noscope_rank"))
	{
		char DBBuffer[512];
		g_hSql = SQL_Connect("nox_noscope_rank", true, DBBuffer, sizeof(DBBuffer));
	
		if (g_hSql == INVALID_HANDLE)
			PrintToServer("Could not connectd not : %s", DBBuffer);
		else 
		{
			SQL_LockDatabase(g_hSql);
			SQL_FastQuery(g_hSql, "CREATE TABLE IF NOT EXISTS nox_noscope_rank (auth_data VARCHAR(48) NOT NULL PRIMARY KEY default '', nick VARCHAR(64) NOT NULL default '', kills INT NOT NULL default 0, headshots INT NOT NULL default 0, distance FLOAT(8,4) NOT NULL default 0.0) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_polish_ci;");
			SQL_UnlockDatabase(g_hSql);
		}
	}
	else
		SetFailState("Nie mozna odnalezc konfiguracji 'nox_noscope_rank' w databases.cfg.");
}

public void DB_LoadInfo(int client)
{
	if(g_hSql != INVALID_HANDLE)
	{
		char _authid[64];
		GetClientAuthId(client, AuthId_Steam2, _authid, 63);
		
		char sQuery[512];
		Format(sQuery, sizeof(sQuery), "SELECT kills, headshots, distance FROM noscope_rank WHERE auth_data = '%s';", _authid);
	
		SQL_LockDatabase(g_hSql);
		Handle hQuery = SQL_Query(g_hSql, sQuery);
		
		if(hQuery == INVALID_HANDLE)
		{
			char blad[255];
			SQL_GetError(g_hSql, blad, sizeof(blad));
			LogError("Nie mozna odszukac z tabeli. (blad: %s)", blad);
			CloseHandle(g_hSql);
		}
		else if(SQL_FetchRow(hQuery))
		{
			kills[client] = SQL_FetchInt(hQuery, 0);
			headshots[client] = SQL_FetchInt(hQuery, 1);
			g_fDistance[client] = SQL_FetchFloat(hQuery, 2);
		}
		else
		{
			kills[client] = 0;
			headshots[client] = 0;
			g_fDistance[client]	= 0.0;
		}
	
		CloseHandle(hQuery);
		SQL_UnlockDatabase(g_hSql);
	}
}

public void DB_SaveInfo(int client)
{
	if(!isValidClient(client) || IsFakeClient(client))
		return;
	
	char authid[64];
	if(!GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid)))
		return;
	
	char nick[64];
	char EscapedName[64];
	
	GetClientName(client, nick, sizeof(nick));
	SQL_EscapeString(g_hSql, nick, EscapedName, sizeof(nick));
	
	char query[512];
	Format(query, sizeof(query), "INSERT INTO `noscope_rank` (auth_data, nick, kills, headshots, distance) VALUES ('%s', '%s', %d, %d, %f) ON DUPLICATE KEY UPDATE nick=VALUES(nick), kills=VALUES(kills), headshots=VALUES(headshots), distance=VALUES(distance)", authid, EscapedName, kills[client], headshots[client], g_fDistance[client]);
	SQL_TQuery(g_hSql, DB_SaveInfoCallback, query);
}

public void DB_TopCallback(Handle owner, Handle hndl, const char[] error, DataPack info_pack)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[TOP] Query failed! %s", error);
		return;
	}
	
	info_pack.Reset();
	
	if(client == 0 || !IsClientInGame(client))
		return;

	delete info_pack;

	int i;

	Menu menu = new	Menu(TOP_Handler, MENU_ACTIONS_ALL);
	menu.SetTitle("[#TOP] Nick - Dystans");
	
	char menu_item[256];
	char sAuth[64];
	
	while(SQL_FetchRow(hndl))
	{
		i++;
		SQL_FetchString(hndl, 0, menu_item, sizeof(menu_item));
		
		Format(menu_item, sizeof(menu_item), "#%d - %s - [%.f]", i, menu_item, SQL_FetchFloat(hndl, 1));
		menu.AddItem(sAuth, menu_item);
	}
	
	if(i == 0)
		menu.AddItem("no_records", "Wygląda na to, że ranking jest czysty.");
	
	menu.ExitButton = true;
	menu.Display(client, 0);
}

public int DB_SaveInfoCallback(Handle owner, Handle query, const char[] error, any data)
{
	if(query == INVALID_HANDLE)
	{
		LogError("[NOX-RANKS] Failed to save client info (error: %s)", error);
		return;
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	bool headshot = event.GetBool("headshot");

	if (!isValidClient(attacker))
		return;
		
	if (!isValidClient(client))
		return;

	char weaponName[64];
	GetClientWeapon(attacker, weaponName, sizeof(weaponName));
	
	if(weaponName[0] && ((StrContains(weaponName, "awp") != -1 || StrContains(weaponName, "scout") != -1 || StrContains(weaponName, "ssg08") != -1))
	&& (GetEntProp(attacker, Prop_Data, "m_iFOV") <= 0 || GetEntProp(attacker, Prop_Data, "m_iFOV") == GetEntProp(attacker, Prop_Data, "m_iDefaultFOV")))
	{
		float forigin[3];
		float iorigin[3];
		float fDistance;
		
		GetClientEyePosition(attacker, forigin);
		GetClientEyePosition(client, iorigin);
		
		fDistance = GetVectorDistance(forigin, iorigin);
		
		if(fDistance > g_fDistance[attacker])
			g_fDistance[attacker] = fDistance;
		
		kills[attacker]++;

		char NameAttacker[64];
		char NameVictim[64];
		GetClientName(client, NameAttacker, sizeof(NameAttacker));
		GetClientName(client, NameVictim, sizeof(NameVictim));

		CPrintToChat(attacker, "%s Dystans: {purple}%f", client, fDistance);
		CPrintToChat(attacker, "%s Wszystkich zabójstw noscope: {purple}%i", TAG, kills[attacker]);
	
		if(headshot)
		{
			headshots[attacker]++;
			CPrintToChat(attacker, "%s Wszystkich headshotów noscope: {purple}%i", TAG, headshots[attacker]);
			CPrintToChatAll("%s Gracz {red}%s zabił noscope w głowe {lightred}%s z broni {purple}%s", TAG, NameAttacker, NameVictim, weaponName);
		}
		else
			CPrintToChatAll("%s Gracz {red}%s zabił noscope {lightred}%s z broni {purple}%s", TAG, NameAttacker, NameVictim, weaponName);
	}
}

public Action CMD_Top(int client, int args)
{
	if(isValidClient(client))
	{
		char query[256];
	
		DataPack info_pack = new DataPack();
		info_pack.WriteCell(client); 

		Format(query,sizeof(query), "SELECT nick, distance FROM noscope_rank ORDER BY distance DESC");
		SQL_TQuery(g_hSql, DB_TopCallback, query, info_pack);
	}
	return Plugin_Handled;
}

public int TOP_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
		delete menu;
	return 0;
}

stock bool isValidClient(int client) 
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}
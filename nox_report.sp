#include <sourcemod>

// ----------------------------- Macro ---------------------------
#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)\
if(IsClientInGame(%1))
	
#define LoopItemCount(%1) for(int %1 = 0; %1 < menu.ItemCount; %1++)

// ----------------------------- Other ---------------------------
#define		TABLE_NAME		"bimchatbox_chat"

Handle g_hSql;
bool g_bReport[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[n.o.x] Report system",
	author = "n.o.x",
	description = "This plugin allows to report players, report messages will be displayed on forum.",
	version = "1.0b",
	url = "http://noxsp.pl"
}
	
public void OnPluginStart()
{
	RegConsoleCmd("sm_zglos", CMD_Report);
	DB_Connect();
}

public OnClientPutInServer(int client)
{
	g_bReport[client] = true;
}

public Action ____________________________________________________(){}
public void DB_Connect()
{
	if(SQL_CheckConfig("nox_report"))
	{
		char sBuffer[128];
		g_hSql = SQL_Connect("nox_report", true, sBuffer, sizeof(sBuffer));
		if (g_hSql == INVALID_HANDLE)
			LogError("[Report] Could not connect: %s", sBuffer);
	}
	else
		SetFailState("Nie mozna odnalezc konfiguracji 'nox_report' w databases.cfg.");
}

public void ReportPlayer(int client, int target, const char[] sReason)
{
	char sBuffer[128];
	Format(sBuffer, sizeof(sBuffer), "Gracz %N zgłasza %N, powód: %s", client, target, sReason);
	
	SQL_EscapeString(g_hSql, sBuffer, sBuffer, sizeof(sBuffer));
	
	char sQuery[256];
	Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (user, chat, time) VALUES (12, '%s', %d)", TABLE_NAME, sBuffer, GetTime());
	SQL_TQuery(g_hSql, DB_SaveInfoCallback, "SET NAMES utf8");
	SQL_TQuery(g_hSql, DB_SaveInfoCallback, sQuery);
	
	g_bReport[client] = false;
	CreateTimer(120.0, Timer_EnableReport, client);
	PrintToChat(client, " \x02[REPORT] Zgłoszono gracza \x0C%N", target);
}

public DB_SaveInfoCallback(Handle owner, Handle query, const char[] error, any data)
{
	if(query == INVALID_HANDLE)
	{
		LogError("[REPORT] Failed to save client info (error: %s)", error);
		return;
	}
}
public Action ___________________________________________________(){}
public Action CMD_Report(int client, int args)
{
	int iCount = 0;
	
	Menu menu = new Menu(MainMenu_Handler, MENU_ACTIONS_ALL);
	menu.SetTitle("[REPORT] Wybierz gracza");
	LoopClients(i)
	{
		if(!IsValidClient(i) || i == client)
			continue;
		
		char sInfo[12], sName[32];
		
		Format(sInfo, sizeof(sInfo), "%d", i);
		GetClientName(i, sName, sizeof(sName));
		
		menu.AddItem(sInfo, sName);
		iCount++;
	}
	
	if(iCount == 0)
		menu.AddItem("ITEMDRAW_DISABLED", "Ups, wygląda na to, że nie ma graczy, których mógłbyś zgłosić.");
	
	menu.Display(client, 0);
	return Plugin_Handled;
}

public Action __________________________________________________(){}
public void CreateMenu_Reasons(int client, int target)
{
	char sInfo[12];
	Format(sInfo, sizeof(sInfo), "%d", target);
	Menu menu = new Menu(SubMenu_Handler, MENU_ACTIONS_ALL);
	menu.SetTitle("[REPORT] Wybierz powód zgłoszenia %N", target);
	menu.AddItem("reason_1", "Wallhack");
	menu.AddItem("reason_2", "AimBot");
	menu.AddItem("reason_3", "AimLock");
	menu.AddItem("reason_4", "SpinBot");
	menu.AddItem("reason_5", "Kampienie");
	menu.AddItem("reason_6", "Obrażanie");
	menu.AddItem("reason_7", "Nadużywane micro");
	menu.AddItem("-TARGET-", sInfo);
	menu.Display(client, 0);
}

public int MainMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[12];
			menu.GetItem(param2, sItem, sizeof(sItem));
			
			CreateMenu_Reasons(param1, StringToInt(sItem));
		}
		case MenuAction_DrawItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if(StrEqual(info, "ITEMDRAW_DISABLED"))
				return ITEMDRAW_DISABLED;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

public int SubMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	char sInfo[64], sDane[64];
	int target;
	LoopItemCount(i)
	{
		menu.GetItem(i, sInfo, sizeof(sInfo), _, sDane, sizeof(sDane));
		if(StrEqual(sInfo, "-TARGET-"))
			target = StringToInt(sDane);
	}
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32], sReason[64];
			menu.GetItem(param2, sItem, sizeof(sItem));
			
			if(StrEqual(sItem, "reason_1"))
				sReason = "Wallhack";
			else if(StrEqual(sItem, "reason_2"))
				sReason = "AimBot";
			else if(StrEqual(sItem, "reason_3"))
				sReason = "AimLock";
			else if(StrEqual(sItem, "reason_4"))
				sReason = "SpinBot";
			else if(StrEqual(sItem, "reason_5"))
				sReason = "Kampienie";
			else if(StrEqual(sItem, "reason_6"))
				sReason = "Obrażanie";
			else if(StrEqual(sItem, "reason_7"))
				sReason = "Nadużywane micro";
			
			ReportPlayer(param1, target, sReason);
		}
		case MenuAction_DrawItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if(StrEqual(info, "ITEMDRAW_DISABLED"))
				return ITEMDRAW_DISABLED;
			else if(StrEqual(info, "-TARGET-"))
				return ITEMDRAW_IGNORE; 
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

public Action _________________________________________________(){}
public Action Timer_EnableReport(Handle timer, any client)
{
	if(client)
		g_bReport[client] = true;
}

public Action ________________________________________________(){}
bool IsValidClient(client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}
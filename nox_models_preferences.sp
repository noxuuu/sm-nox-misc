#pragma semicolon 1 
#pragma newdecls required

#define LoopModels(%1) for(int %1 = 0; %1 < sizeof g_sModels; %1++)
#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)\
if(IsClientInGame(%1))
	
#include <sourcemod>
#include <sdktools>
#include <clientprefs>

int g_iClientMdlIndex[MAXPLAYERS+1];
Handle g_hMySelection;

char g_sModels[][] =
{
	"", // default
	"model/path 1",
	"model/path 2",
	"model/path 3",
	"model/path 4"
};

char g_sModelsArms[][] =
{
	"",
	"model_arms/path 1",
	"model_arms/path 2",
	"model_arms/path 3",
	"model_arms/path 4"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_model", CMD_MenuModel);
	g_hMySelection = RegClientCookie("h2k_mdl", "Mdl select", CookieAccess_Protected);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	LoopClients(i)
	{
		if(!AreClientCookiesCached(i))
			continue;
		OnClientCookiesCached(i);
	}
}

public Action ______________________________________________________________(){} // custom spacer
public void OnMapStart()
{
	LoopModels(i)
	{
		AddFileToDownloadsTable(g_sModels[i]);
		PrecacheModel(g_sModels[i]);
	}
}

public Action _____________________________________________________________(){}
public void OnClientCookiesCached(int client)
{
	char sCookieValue[4];
	GetClientCookie(client, g_hMySelection, sCookieValue, sizeof(sCookieValue));
	g_iClientMdlIndex[client] = StringToInt(sCookieValue);
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client))
		return;
	
	if(AreClientCookiesCached(client) && g_iClientMdlIndex[client] > 0)
	{
		SetEntityModel(client, g_sModels[g_iClientMdlIndex[client]]);
		SetEntPropString(client, Prop_Send, "m_szArmsModel", "");
		SetEntPropString(client, Prop_Send, "m_szArmsModel", g_sModelsArms[g_iClientMdlIndex[client]]);
	}
}

public Action ____________________________________________________________(){}
public Action CMD_MenuModel(int client, int args)
{
	char sItem[32];
	char sItem2[32];
	Menu menu = new Menu(MainMenu_Handler, MENU_ACTIONS_ALL);
	menu.SetTitle("Wybierz model:");
	
	Format(sItem, sizeof(sItem), g_iClientMdlIndex[client] == 0?"ITEMDRAW_DISABLED":"Item_0");
	Format(sItem, sizeof(sItem), g_iClientMdlIndex[client] == 0?"Default [Wybrany]":"Model 1");
	menu.AddItem(sItem, sItem2);
	Format(sItem, sizeof(sItem), g_iClientMdlIndex[client] == 1?"ITEMDRAW_DISABLED":"Item_1");
	Format(sItem, sizeof(sItem), g_iClientMdlIndex[client] == 1?"Model 1 [Wybrany]":"Model 1");
	menu.AddItem(sItem, sItem2);
	Format(sItem, sizeof(sItem), g_iClientMdlIndex[client] == 2?"ITEMDRAW_DISABLED":"Item_2");
	Format(sItem, sizeof(sItem), g_iClientMdlIndex[client] == 1?"Model 2 [Wybrany]":"Model 2");
	menu.AddItem(sItem, sItem2);
	Format(sItem, sizeof(sItem), g_iClientMdlIndex[client] == 3?"ITEMDRAW_DISABLED":"Item_3");
	Format(sItem, sizeof(sItem), g_iClientMdlIndex[client] == 1?"Model 3 [Wybrany]":"Model 3");
	menu.AddItem(sItem, sItem2);
	Format(sItem, sizeof(sItem), g_iClientMdlIndex[client] == 4?"ITEMDRAW_DISABLED":"Item_4");
	Format(sItem, sizeof(sItem), g_iClientMdlIndex[client] == 1?"Model 4 [Wybrany]":"Model 4");
	menu.AddItem(sItem, sItem2);
	menu.ExitButton = true;
	menu.Display(client, 30);
}

public int MainMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[64];
			menu.GetItem(param2, sItem, sizeof(sItem));
			
			if(StrEqual(sItem, "Item_0"))
				PrintToChat(param1, " Wybrales domyslny model");
			else if(StrEqual(sItem, "Item_1"))
				PrintToChat(param1, " Wybrales model nr 1");
			else if(StrEqual(sItem, "Item_2"))
				PrintToChat(param1, " Wybrales model nr 2");
			else if(StrEqual(sItem, "Item_3"))
				PrintToChat(param1, " Wybrales model nr 3");
			else if(StrEqual(sItem, "Item_4"))
				PrintToChat(param1, " Wybrales model nr 4");
				
			ReplaceString(sItem, sizeof(sItem), "Item_", "");
			SetModel(param1, StringToInt(sItem));
		}
		case MenuAction_DrawItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if(StrEqual(info, "ITEMDRAW_DISABLED"))
				return ITEMDRAW_DISABLED; 
		}
	}
	return 0;
}

public Action ___________________________________________________________(){}
public void SetModel(int client, int index)
{
	if(IsModelPrecached(g_sModels[index]))
	{
		g_iClientMdlIndex[client] = index;
		if(index > 0)
		{
			SetEntityModel(client, g_sModels[index]);
			SetEntPropString(client, Prop_Send, "m_szArmsModel", "");
			SetEntPropString(client, Prop_Send, "m_szArmsModel", g_sModelsArms[index]);
		}
		char sCookieValue[4];
		IntToString(index, sCookieValue, sizeof(sCookieValue));
		SetClientCookie(client, g_hMySelection, sCookieValue);
	}
}


bool IsValidClient(int client)
{
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsFakeClient(client))
        return false;
    return true;
}
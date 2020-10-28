#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)\
if(IsClientInGame(%1))

bool g_bMuted[MAXPLAYERS+1][MAXPLAYERS+1];
	
public Plugin myinfo = 
{
	name = "Mute Players",
	author = "n.o.x",
	description = "Allows to mute players",
	version = "1.0b"
}

public OnPluginStart() 
{
	RegConsoleCmd("sm_mutemenu", CMD_Mute);
}

//====================================================================================================

public Action CMD_Mute(int client, int args)
{
	int iCount;
	Menu menu = new Menu(Menu_Handler, MENU_ACTIONS_ALL);
	menu.SetTitle("Mute players:");
	menu.AddItem("mute_all", "Zablokuj wszystkich");
	menu.AddItem("unmute_all", "Odblokuj wszystkich");
	
	LoopClients(i)
	{
		iCount++;
		if(IsFakeClient(i) || i == client)
			continue;
		
		char sID[16];
		char sName[64];
		
		Format(sID, sizeof(sID), "%d", i);
		GetClientName(i, sName, sizeof(sName));
		
		Format(sName, sizeof(sName), "%s - [%s]", sName, g_bMuted[client][i] ? "UNMUTE" : "MUTE");
		
		menu.AddItem(GetAdminFlag(GetUserAdmin(i), Admin_Generic)?"ITEMDRAW_DISABLED":sID, sName);
	}
	
	if(iCount == 0)
		menu.AddItem("ITEMDRAW_DISABLED", "Wygląda na to, że nie ma nikogo, kogo możesz zablokować.");
	
	menu.ExitButton = true;
	menu.Display(client, 300);
	return Plugin_Handled;
}

public int Menu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(StrEqual(sItem, "mute_all"))
			{
				LoopClients(i)
				{
					if(i == param1 || GetAdminFlag(GetUserAdmin(i), Admin_Generic))
						continue;
					
					MutePlayer(param1, i, false);
				}
			}
			else if(StrEqual(sItem, "unmute_all"))
			{
				LoopClients(i)
				{
					if(i == param1)
						continue;
					
					UnMutePlayer(param1, i, false);
				}
			}
			else
			{
				int client = StringToInt(sItem);
				if(!g_bMuted[param1][client])
					MutePlayer(param1, client, true);
				else
					UnMutePlayer(param1, client, true);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DrawItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if(StrEqual(info, "ITEMDRAW_DISABLED"))
			{
				return ITEMDRAW_DISABLED;
			}
			else if(StrEqual(info, "ITEMDRAW_SPACER"))
			{
				return ITEMDRAW_SPACER; 
			}
		}
	}
	return 0;
}

public void MutePlayer(int client, int target, bool bPrint)
{
	g_bMuted[client][target] = true;
	SetListenOverride(client, target, Listen_No);
	PrintToChat(client, " \x02[MUTE] \x01 Zablokowałeś gracza \xOC%N", target);
}

public void UnMutePlayer(int client, int target, bool bPrint)
{
	g_bMuted[client][target] = false;
	SetListenOverride(client, target, Listen_Yes);
	PrintToChat(client, " \x02[MUTE] \x01 Odblokowałeś gracza \xOC%N", target);
}
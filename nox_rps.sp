#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <nox_nshop>

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////// VARIABLES AND DEFINITIONS /////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// ----------------------------- Macro ---------------------------
#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)\
if(IsClientInGame(%1) && !IsFakeClient(%1))
	
#define LoopItemCount(%1) for(int %1 = 0; %1 < menu.ItemCount; %1++)

// ----------------------------- Other ---------------------------
#define 	PLUGIN_NAME					"[n.o.x] DR => Paper Rock Scissors"
#define 	PLUGIN_AUTHOR				"n.o.x"
#define 	PLUGIN_DESC					"| Gra [Kamień | Papier | Nożyce] |"
#define 	PLUGIN_VERSION				"1.0b"
#define		PLUGIN_URL					"http://noxsp.eu"

#define		PREFIX_NORMAL				" \x02[KPN] \x04✔"
#define		PREFIX_ERROR				" \x02[\x04#\x02KPN] ✖"

// ----------------------- Globals ---------------------
int g_iValues[] = {0, 500, 1000, 5000, 10000, 25000, 50000, 100000};

enum rps_selection {
	None,
	Rock, 
	Paper, 
	Scissors
};

// ---------------------- Clients -----------------------
bool g_bInGame[MAXPLAYERS+1];

int g_iValue[MAXPLAYERS+1];
int g_iCountDown[MAXPLAYERS+1];
int g_iEnemy[MAXPLAYERS+1];
rps_selection g_iSelect[MAXPLAYERS+1];

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////// PLUGIN INFO ///////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////// PLUGIN CONTENT ////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public void OnPluginStart()
{
	RegConsoleCmd("sm_kpn", 				CMD_Game);
	RegConsoleCmd("sm_pkn", 				CMD_Game);
	RegConsoleCmd("sm_kpnm", 				CMD_Game);
	RegConsoleCmd("sm_nkp", 				CMD_Game);
	RegConsoleCmd("sm_pnk",					CMD_Game);
	RegConsoleCmd("sm_kamienpapiernozyce", 	CMD_Game);
}

public Action _________________________________________________________(){}
public void OnClientDisconnect(int client)
{
	if(g_bInGame[client])
	{
		if(g_iValues[g_iValue[client]] > 0)
			NShop_GiveClientCoins(g_iEnemy[client], g_iValues[g_iValue[client]]*2);
		
		if(g_iValues[g_iValue[client]] > 0)
			PrintToChatAll("%s \x0C%N \x04spękał i wyszedł z serwera!", PREFIX_NORMAL, client);
		else
			PrintToChatAll("%s \x0C%N \x04spękał i wyszedł z serwera tracąć \x07%d \x04monet !", PREFIX_NORMAL, client, g_iValues[g_iValue[client]]);
		
		// -- Reset info
		ResetGameInfo(client, g_iEnemy[client]);
	}
}

public Action ________________________________________________________(){}
public Action CMD_Game(int client, int args)
{
	if(GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		PrintToChat(client, "%s \x07Nie możesz grać podczas rozgrzewki.", PREFIX_ERROR);
		return Plugin_Handled;
	}
	else if(g_bInGame[client])
	{
		PrintToChat(client, "%s \x07Jesteś już w grze.", PREFIX_ERROR);
		return Plugin_Handled;
	}
	else if(GetClientTeam(client) == CS_TEAM_T)
	{
		PrintToChat(client, "%s \x07Nie możesz grać będąc terrorystą.", PREFIX_ERROR);
		return Plugin_Handled;
	}
	
	int iCount;
	char sVal[64], sMenuItem[64], sTarget[8];
	
	Format(sVal, 64, "~ Stawka: %s\n \n", GetCoinsString(g_iValues[g_iValue[client]]));
	
	Menu menu = new Menu(Menu_Handler, MENU_ACTIONS_ALL);
	menu.SetTitle("[Kamień | Papier | Nożyce] \n \n");
	menu.AddItem("value", sVal);
	LoopClients(i)
		if(i != client && !g_bInGame[i]) // client isn't in game 
			if(GetClientTeam(i) != CS_TEAM_T)
			{
				if(NShop_GetClientCoins(i) >= g_iValues[g_iValue[client]])
				{
					Format(sTarget, sizeof(sTarget), "%d", i);
					GetClientName(i, sMenuItem, sizeof(sMenuItem));
					menu.AddItem(sTarget, sMenuItem);
					iCount++;
				}
				else
				{
					GetClientName(i, sMenuItem, sizeof(sMenuItem));
					Format(sMenuItem, sizeof(sMenuItem), "[Brak monet] %s", sMenuItem);
					menu.AddItem("ITEMDRAW_DISABLED", sMenuItem);
					iCount++;
				}
			}
	if(!iCount)
		menu.AddItem("ITEMDRAW_DISABLED", "Aktualnie nie ma graczy, z którymi mógłbyś zagrać.");
	
	menu.Display(client, 0);
	return Plugin_Handled;
}

public CreateMenu_ConfirmInvite(int target, int client)
{
	char sClient[16];
	Format(sClient, sizeof(sClient),"%d", client);

	Menu menu = new Menu(MenuHandler_ConfirmInvite, MENU_ACTIONS_ALL);
	if(g_iValues[g_iValue[client]] > 0)
		menu.SetTitle("~ [Kamień | Papier | Nożyce] \n~ %N wyzwał Cię na pojedynek o %s monet! \nAkceptujesz wyzwanie?\n \n", client, GetCoinsString(g_iValues[g_iValue[client]]));
	else
		menu.SetTitle("~ %N wyzwał Cię na pojedynek! \nAkceptujesz wyzwanie?\n \n", client);
	menu.AddItem("yes", "Dawać go!");
	menu.AddItem("no", "Cykam się");
	menu.AddItem("-TARGET-", sClient);
	menu.ExitButton = false;
	menu.Display(target, 0);
}

public DrawGame(int client, int target)
{
	Menu menu = new Menu(Game_Handler, MENU_ACTIONS_ALL);
	menu.SetTitle("~ [Kamień | Papier | Nożyce] \n~ Co stawiasz?\n \n");
	menu.AddItem("1", "Kamień");
	menu.AddItem("2", "Papier");
	menu.AddItem("3", "Nożyce");
	menu.ExitButton = false;
	menu.Display(client, 0);
	menu.Display(target, 0);
	
	CreateTimer(20.0, Timer_TimeUp, client);
}

public int Menu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[256];
			menu.GetItem(param2, sItem, sizeof(sItem));
			
			if(StrEqual(sItem, "value"))
			{
				if(g_iValue[param1] == sizeof(g_iValues)-1)
					g_iValue[param1] = 0;
				else
					g_iValue[param1]++;
				
				CMD_Game(param1, 0);
			}
			else
			{
				if(NShop_GetClientCoins(param1) >= g_iValues[g_iValue[param1]])
					CreateMenu_ConfirmInvite(StringToInt(sItem), param1);
				else
					PrintToChat(param1, "%s \x07Nie posiadasz wystarczającej ilości monet!", PREFIX_ERROR);
			}
		}
		case MenuAction_End: delete menu;
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

public int MenuHandler_ConfirmInvite(Menu menu, MenuAction action, int param1, int param2)
{
	char sInfo[64], Dane[64];
	int client;
	LoopItemCount(i)
	{
		menu.GetItem(i, sInfo, sizeof(sInfo), _, Dane, sizeof(Dane));
		if(StrEqual(sInfo, "-TARGET-"))
			client = StringToInt(Dane);
	}
	switch(action)
	{
		case MenuAction_Select:
		{
			char Item[32];
			menu.GetItem(param2, Item, sizeof(Item));
			if(StrEqual(Item, "yes"))
			{
				// -- Prepare variables
				g_bInGame[param1] = true;
				g_bInGame[client] = true;
				
				g_iValue[param1] = g_iValue[client];
				
				g_iEnemy[param1] = client;
				g_iEnemy[client] = param1;
				
				g_iCountDown[client] = 5;
				g_iCountDown[g_iEnemy[client]] = 5;
				
				g_iSelect[client] = None;
				g_iSelect[g_iEnemy[client]] = None; 
				
				// - GetMoney
				if(g_iValue[client] > 0)
				{
					NShop_SetClientCoins(client, NShop_GetClientCoins(g_iEnemy[client]) - g_iValues[g_iValue[client]]);
					NShop_SetClientCoins(param1, NShop_GetClientCoins(param1) - g_iValues[g_iValue[param1]]);
				}
				
				// -- Initialize start
				CreateTimer(1.0, Timer_HUD, param1, TIMER_REPEAT);
				
				// -- Print info --
				PrintToChat(param1, "%s \x06Zaakceptowałeś wyzwanie \x03%N.", PREFIX_NORMAL, client);
				PrintToChat(client, "%s \x03%N \x06zaakceptował Twoje wyzwanie.", PREFIX_NORMAL, param1);  
				
				ClientCommand(client, "play */UI/deathnotice.wav");
				ClientCommand(param1, "play */UI/deathnotice.wav");
				
				PrintToChat(param1, " \x04┏╋━━━━━━━━━━━━━━━━━━◥◣◆◢◤━━━━━━━━━━━━━━━━━━╋┓");
				PrintToChat(param1, " \x04♦ \x06Grasz z \x0C%N\x06.", client);
				if(g_iValues[g_iValue[client]] > 0)
					PrintToChat(param1, " \x04♦ \x06Wygrany zgarnia stawkę w wysokości \x03%s\x06.", GetCoinsString(g_iValues[g_iValue[client]]));
				PrintToChat(param1, " \x04♦ \x06Good luck!.");
				PrintToChat(param1, " \x04┗╋━━━━━━━━━━━━━━━━━━◥◣◆◢◤━━━━━━━━━━━━━━━━━━╋┛");
				
				PrintToChat(client, " \x04┏╋━━━━━━━━━━━━━━━━━━◥◣◆◢◤━━━━━━━━━━━━━━━━━━╋┓");
				PrintToChat(client, " \x04♦ \x06Grasz z \x0C%N\x06.", param1);
				if(g_iValues[g_iValue[client]] > 0)
					PrintToChat(client, " \x04♦ \x06Wygrany zgarnia stawkę w wysokości \x03%s\x06.", GetCoinsString(g_iValues[g_iValue[client]]));
				PrintToChat(client, " \x04♦ \x06Good luck!.");
				PrintToChat(client, " \x04┗╋━━━━━━━━━━━━━━━━━━◥◣◆◢◤━━━━━━━━━━━━━━━━━━╋┛");
			}
			else if(StrEqual(Item, "no"))
				PrintToChat(client, "%s \x06Gracz \x0C%N \x06nie chce stoczyć z Tobą pojedynku.", PREFIX_NORMAL, param1);
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
				return ITEMDRAW_DISABLED;
			else if(StrEqual(info, "-TARGET-"))
				return ITEMDRAW_IGNORE; 
		}
	}
	return 0;
}

public int Game_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[256];
			menu.GetItem(param2, sItem, sizeof(sItem));
			
			// Save client selection
			g_iSelect[param1] = view_as<rps_selection>(StringToInt(sItem));
			
			if(g_iSelect[g_iEnemy[param1]] != None) // Enemy select 
			{
				if(g_iSelect[param1] != g_iSelect[g_iEnemy[param1]]) // Clients selection is the same
				{
					// -- Get winner
					int winner;
					
					if(g_iSelect[param1] == Rock && g_iSelect[g_iEnemy[param1]] == Scissors // Rock beat scissors
					|| g_iSelect[param1] == Paper && g_iSelect[g_iEnemy[param1]] == Rock // Paper beat rock
					|| g_iSelect[param1] == Scissors && g_iSelect[g_iEnemy[param1]] == Paper) // Scissors beat paper
					{
						winner = param1;
					}
					else // if param1 didn't beat enemy, enemy is the winner
						winner = g_iEnemy[param1];
					
					// -- Give/sub money
					if(g_iValues[g_iValue[winner]] > 0)
						NShop_GiveClientCoins(winner, g_iValues[g_iValue[winner]]*2);
					
					// -- Print info
					if(g_iValues[g_iValue[winner]] > 0)
						PrintToChatAll("%s \x0C%N \x06Wygrał w pojedynku z \x0C%N \x06zgarniając \x07%s \x06monet!", PREFIX_NORMAL, winner, g_iEnemy[winner], GetCoinsString(g_iValues[g_iValue[winner]]));
					else
						PrintToChatAll("%s \x0C%N \x06Wygrał w pojedynku z \x0C%N\x06!", PREFIX_NORMAL, winner, g_iEnemy[winner]);
					
					// -- Let them know about loose/win
					ClientCommand(winner, "play */UI/item_showcase_coin_02.wav");
					ClientCommand(g_iEnemy[winner], "play */UI/armsrace_demoted.wav");
					
					// -- Reset info
					ResetGameInfo(winner, g_iEnemy[winner]);
				}
				else // Next round
				{
					// Play sound
					ClientCommand(param1, "play */UI/item_showcase_coin_02.wav");
					ClientCommand(g_iEnemy[param1], "play */UI/item_showcase_coin_02.wav");
				
					// Show info
					PrintToChat(param1, " \x04♦ \x06Oboje wybraliście \x03%s \x06zaczynamy nową rundę!", GetSelectionString(g_iSelect[param1]));
					PrintToChat(g_iEnemy[param1], " \x04♦ \x06Oboje wybraliście \x03%s \x06zaczynamy nową rundę!", GetSelectionString(g_iSelect[param1]));
					
					// Reset info
					g_iSelect[param1] = None;
					g_iSelect[g_iEnemy[param1]] = None;
					
					// Call new round
					DrawGame(param1, g_iEnemy[param1]);
				}
			}
			else
				if(g_iEnemy[param1] != 0)
					PrintToChat(param1, " \x04♦ \x06Oczekiwanie na ruch \x0C%N\x06..", g_iEnemy[param1]);
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

public Action _______________________________________________________(){}
public Action Timer_HUD(Handle timer, any client)
{
	if(!IsValidClient(client) || !IsValidClient(g_iEnemy[client]))
		return Plugin_Stop; 
	
	if(g_iCountDown[client] < 0)
		return Plugin_Stop;
		
	if(g_iCountDown[client] == 0)
		SetHudTextParams(0.35, 0.45, 1.1, 0, 255, 0, 255, 2, 0.0, 0.0, 0.0);
	else
		SetHudTextParams(0.35, 0.45, 1.1, 255, 0, 255, 255, 2, 0.0, 0.0, 0.0);
	
	
	if(g_iCountDown[client] == 0)
	{
		DrawGame(client, g_iEnemy[client]);
		
		ClientCommand(client, "play */UI/item_showcase_coin_02.wav");
		ClientCommand(g_iEnemy[client], "play */UI/item_showcase_coin_02.wav");
		
		ShowHudText(client, -1, "Gra rozpoczęta! GL & HF!", g_iCountDown[client]);
		ShowHudText(g_iEnemy[client], -1, "Gra rozpoczęta! GL & HF!", g_iCountDown[client]);
	}
	else
	{
		ShowHudText(client, -1, "Gra rozpocznie się za %d", g_iCountDown[client]);
		ShowHudText(g_iEnemy[client], -1, "Gra rozpocznie się za %d", g_iCountDown[client]);
	}
	
	g_iCountDown[client]--;
	
	return Plugin_Continue;
}

public Action Timer_TimeUp(Handle timer, any client)
{
	if(IsValidClient(client))
	{
		// Play sound
		ClientCommand(client, "play */UI/armsrace_demoted.wav");
		ClientCommand(g_iEnemy[client], "play */UI/armsrace_demoted.wav");
		
		// Show info
		PrintToChat(client, "%s \x06Upłynął czas na wybór.", PREFIX_NORMAL);
		PrintToChat(g_iEnemy[client], "%s \x06Upłynął czas na wybór.", PREFIX_NORMAL);
		
		// Give money back
		if(g_iValues[g_iValue[client]] > 0)
		{
			NShop_GiveClientCoins(client, g_iValues[g_iValue[client]]);
			NShop_GiveClientCoins(g_iEnemy[client], g_iValues[g_iValue[client]]);
		}
		
		// -- Reset info
		ResetGameInfo(client, g_iEnemy[client]);
	}
}

public Action ____________________________________________________(){}
void ResetGameInfo(int client, int opponent)
{
	g_bInGame[client] = false;
	g_bInGame[opponent] = false;
	
	g_iEnemy[client] = 0;
	g_iEnemy[opponent] = 0;
	
	g_iCountDown[client] = 0;
	g_iCountDown[opponent] = 0;
	
	g_iValue[client] = 0;
	g_iValue[opponent] = 0;
	
	g_iSelect[client] = None;
	g_iSelect[opponent] = None;
}

public Action ___________________________________________________(){}
char GetSelectionString(rps_selection selection)
{
	char sSelection[32];
	
	if(selection == Rock)
		sSelection = "Kamień";
	else if(selection == Paper)
		sSelection = "Papier";
	else if(selection == Scissors)
		sSelection = "Nożyce";
	
	return sSelection;
}

bool IsValidClient(client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}
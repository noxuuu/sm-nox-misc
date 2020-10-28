#include <sourcemod>
#include <sdktools>

int g_iRound = 0;

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

public void OnMapStart()
{
	AddFileToDownloadsTable("resource/overviews/de_dust2_oldd_radar.dds");
	AddFileToDownloadsTable("resource/overviews/de_dust2_oldd.txt");
	g_iRound = 0;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_iRound == GetConVarInt(FindConVar("mp_maxrounds"))-1)
		CallVote();
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	g_iRound++;
}

public void Event_RestartRound(Handle event, const char[] Player_Name, bool dontBroadcast)
{
	g_iRound = 0;
}

public void CallVote()
{
	//Menu.
	Menu menu = new Menu(VoteHandler);
	menu.SetTitle("Jaka next mapa?\n \n");
	menu.AddItem("de_dust2", "Dust2 [NEW]");
	menu.AddItem("de_dust2_oldd", "Dust2 [OLD]");
	
	menu.DisplayVoteToAll(15);
}

public int VoteHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_VoteEnd:
		{
			char Item[32];
			menu.GetItem(param1, Item, sizeof(Item));
			if(StrEqual(Item, "de_dust2"))
				PrintToChatAll(" \x04 Wychodzi na to, że większość graczy chce \x02nowe \x04dd2 !");
			else if(StrEqual(Item, "de_dust2_oldd"))
				PrintToChatAll(" \x04 Wychodzi na to, że większość graczy chce \x02stare \x04dd2 !");
			
			ServerCommand("sm_nextmap %s", Item);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

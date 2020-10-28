#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

public void OnMapStart()
{
	CreateTimer(30.0, Timer_Start_Vote);
}

public Action Timer_Start_Vote(Handle timer)
{
	if(IsVoteInProgress())
		return;
		
	Menu menu = new Menu(Handler_VoteCallback, MENU_ACTIONS_ALL);
	menu.SetTitle("Głosowanie na długość mapy:\n \n");
	menu.AddItem("15", "15 Minut");
	menu.AddItem("20", "20 Minut");
	menu.AddItem("25", "30 Minut");
	menu.AddItem("30", "40 Minut");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
}

public int Handler_VoteCallback(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_VoteEnd:
		{
			int value;
			switch(param1)
			{
				case 0: value = 15;
				case 1: value = 20;
				case 2: value = 25;
				case 3: value = 30;
			}
			
			ServerCommand("mp_timelimit %d", value);
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}
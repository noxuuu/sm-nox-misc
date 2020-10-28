#include <sourcemod>
//#include <store>

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)\
if(IsClientInGame(%1))
	
Handle g_hTimer = INVALID_HANDLE;

public void OnMapStart()
{
	g_hTimer = CreateTimer(5.0, Timer_Loyal, _, TIMER_REPEAT);
}

public void OnMapEnd()
{
	if(g_hTimer != INVALID_HANDLE)
    {
        CloseHandle(g_hTimer);
        g_hTimer = INVALID_HANDLE;
    }
}

public Action Timer_Loyal(Handle timer, any client)
{
	char sName[64];
	
	LoopClients(i)
	{
		GetClientName(i, sName, sizeof(sName));
		if(GetClientTeam(i) != 1)
			if(IsBonusNick(sName))
			{
				AddCoins(i, 2);
				PrintToChat(i, " \x02[Bonus] \x04✔ \x07Dostajesz \x042 \x07kredyty za promowanie CsWild.pl w nicku. Dziękujemy!");
			}
			else
				PrintToChat(i, "Nic nie dostaniesz zlodzieju");
	}	
}

public void AddCoins(int client, int amount)
{
	amount += 2//Store_GetClientCredits(client);
	SetCoins(client, amount);
}

public void SetCoins(int client, int amount)
{
	//Store_SetClientCredits(client, amount);
}

stock bool IsBonusNick(const char[] text)
{
	if(StrContains(text, "CSProject") != -1 || StrContains(text, "csproject") != -1)
		return true;
	return false;
}

stock bool IsValidClient(int client)
{
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsFakeClient(client))
        return false;
    return true;
}
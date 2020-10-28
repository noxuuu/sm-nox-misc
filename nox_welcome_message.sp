#include <sourcemod>

#define 	SERVER_HOST 		"Katujemy.eu"
#define 	SERVER_ADDRESS		"127.0.0.1:27015"
#define		SERVER_DOMAIN		""
#define 	SERVER_OWNER		"Blady"
#define 	SERVER_NAME			"Only Mirage #1"
#define		SERVER_VERSION		"1.7.2"
#define		SERVER_LAST_UP		"16/04/2020"

public void OnPluginStart()
{
	HookEvent("player_team", Event_PlayerTeam);
}

public int Event_PlayerTeam(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
	{
		PrintToConsole(client, "--------------------------------------------------");
		PrintToConsole(client, "[%s] Witamy na serwerze %s", SERVER_HOST, SERVER_NAME);
		PrintToConsole(client, "[%s] Aktualna wersja serwera: %s", SERVER_HOST, SERVER_VERSION);
		PrintToConsole(client, "[%s] Ostatnia aktualizacja serwera: %s", SERVER_HOST, SERVER_LAST_UP);
		PrintToConsole(client, "[%s] Założycielem tego serwera jest %s", SERVER_HOST, SERVER_OWNER);
		PrintToConsole(client, "--------------------------------------------------");
		PrintToConsole(client, "[%s] Twój nick: %N", SERVER_HOST, client);
		if(!StrEqual(SERVER_DOMAIN, "")) PrintToConsole(client, "[%s] Domena serwera: %s", SERVER_HOST, SERVER_DOMAIN);
		PrintToConsole(client, "[%s] IP serwera: %s", SERVER_HOST, SERVER_ADDRESS);
		PrintToConsole(client, "--------------------------------------------------");
		
		PrintToChat(client, "------------------------------------------------------------------");
		PrintToChat(client, " \x02[\x04%s\x02] \x04Witamy na serwerze \x02%s", SERVER_HOST, SERVER_NAME);
		PrintToChat(client, " \x02[\x04%s\x02] \x04Aktualna wersja serwera: \x02%s", SERVER_HOST, SERVER_VERSION);
		PrintToChat(client, " \x02[\x04%s\x02] \x04Ostatnia aktualizacja serwera: \x02%s", SERVER_HOST, SERVER_LAST_UP);
		PrintToChat(client, " \x02[\x04%s\x02] \x04Założycielem tego serwera jest \x02%s", SERVER_HOST, SERVER_OWNER);
		PrintToChat(client, "------------------------------------------------------------------");
		
		
		if(DayOfWeek() == 0)
		{
			PrintToConsole(client, "[%s] Dzisiaj jest Niedziela", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Niedziela", SERVER_HOST);
		}
		else if(DayOfWeek() == 1)
		{
			PrintToConsole(client, "[%s] Dzisiaj jest Poniedziałek", SERVER_HOST);
			PrintToConsole(client, "[%s] Weekend rozpocznie się za 5 dni", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Poniedziałek", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Weekend rozpocznie się za\x025 dni", SERVER_HOST);
		}
		else if(DayOfWeek() == 2)
		{
			PrintToConsole(client, "[%s] Dzisiaj jest Wtorek", SERVER_HOST);
			PrintToConsole(client, "[%s] Weekend rozpocznie się za 4 dni", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Wtorek", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Weekend rozpocznie się za\x024 dni", SERVER_HOST);
		}
		else if(DayOfWeek() == 3)
		{
			PrintToConsole(client, "[%s] Dzisiaj jest Środa", SERVER_HOST);
			PrintToConsole(client, "[%s] Weekend rozpocznie się za 3 dni", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Środa", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Weekend rozpocznie się za\x023 dni", SERVER_HOST);
		}
		else if(DayOfWeek() == 4)
		{
			PrintToConsole(client, "[%s] Dzisiaj jest Czwartek", SERVER_HOST);
			PrintToConsole(client, "[%s] Weekend rozpocznie się za 2 dni", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Czwartek", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Weekend rozpocznie się za \x022 dni", SERVER_HOST);
		}
		else if(DayOfWeek() == 5)
		{
			PrintToConsole(client, "[%s] Dzisiaj jest Piątek", SERVER_HOST);
			PrintToConsole(client, "[%s] Weekend rozpocznie się jutro", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Piątek", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Weekend rozpocznie się \x02jutro", SERVER_HOST);
		}
		else if(DayOfWeek() == 6)
		{
			PrintToConsole(client, "[%s] Dzisiaj jest Sobota", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Sobota", SERVER_HOST);
		}
		
		if(DayOfWeek() == 6 || DayOfWeek() == 0)
		{
			/*PrintToChat(client, " %s \x04Dzisiaj jest \x04weekend", PREFIX_NORMAL);
			PrintToChat(client, " %s \x04Z tego powodu, na serwerze wszyscy mają:", PREFIX_NORMAL);
			PrintToChat(client, " %s \x04--> Zwiększoną ilość otrzymywanego gold'a", PREFIX_NORMAL);
			PrintToChat(client, " %s \x04--> Zwiększoną ilość otrzymywanego exp'a", PREFIX_NORMAL);*/
		}
		else
		{
			PrintToConsole(client, "[%s] Administracja %s życzy miłej gry!", SERVER_HOST, SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Administracja \x02%s \x04życzy miłej gry !", SERVER_HOST, SERVER_HOST);
		}
		PrintToConsole(client, "--------------------------------------------------");
		PrintToChat(client, "------------------------------------------------------------------");
	}
}

stock int DayOfWeek()
{
	int DayWeek;
	char buffer[10];
	FormatTime(buffer, sizeof(buffer), "%w", GetTime());
	DayWeek = StringToInt(buffer);
	return DayWeek;
}

stock bool IsValidClient(client)
{
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsFakeClient(client))
        return false;
    return true;
}
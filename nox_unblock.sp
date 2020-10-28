#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <multicolors>

int g_iRoundStart; // zmiennna globalna przechowująca timestamp startu rundy
bool g_bUsed[MAXPLAYERS+1]; // tablica zmiennych typu boolean, przechowująca wartość prawda/fałsz - tworzymy dla każdego klienta z osobn, stąd index MAXPLAYERS

public void OnPluginStart()
{
	// "Łapiemy" start rundy
	HookEvent("round_start", Event_RoundStart);
	
	// rejestrujemy naszą komendę
	RegConsoleCmd("sm_ub", CMD_UnBlock, "Unblock player");
	
	// "Łapiemy" użycie +lookatweapon
	AddCommandListener(Listener_LookAtWeapon, "+lookatweapon");
} 

public void OnClientPutInServer(int client)
{
	// ustawiamy wartość domyślną dla naszej zmiennej sprawdzającej czy klient wpisał komende
	g_bUsed[client] = false;
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// resetujemy użycie komendy iterując każdego klienta, zauważ, że przy wydarzeniu "round_start" nie dostajemy indexu klienta, ponieważ event dotyczy rundy, nie samego klienta. Dlatego też pobieramy ich manualnie
	for(int i = 1; i < MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			g_bUsed[i] = false;
	
	// pobieramy timestamp gdy zaczyna się runda
	g_iRoundStart = GetTime(); 
}

public Action CMD_UnBlock(int client, int args)
{
	// sprawdzamy czy gracz jest zywy, jeżeli nie ~ pomijamy kod poniżej
	if(!IsPlayerAlive(client)) {
		CPrintToChat(client, "{lime}[UnBlock]{default} You need to be alive.");
		return Plugin_Continue;
	}
		
	// sprawdzamy czy gracz użył komendy, jeżeli tak ~ pomijamy kod poniżej
	if(g_bUsed[client]){
		CPrintToChat(client, "{lime}[UnBlock]{default} Only once per round.");
		return Plugin_Continue;
	}
	
	// pobieramy aktualny timestamp, usuwamy od niego czas, w którym wystartowała runda, zostają nam więc sekundy, które minęły od tamtego wydarzenia
	if (GetTime() - g_iRoundStart > 15) {
		CPrintToChat(client, "{lime}[UnBlock]{default} Only 15sec after the round starts.");
		return Plugin_Continue;
	}
	
	// wszystko poszło pomyślnie, więc definiujemy zmienną przechowującą origin klienta
	float fOrigin[3];
	GetClientAbsOrigin(client, fOrigin);
	
	// dorzucamy 99.0 do wysokości używając operatora przypisania dodatku
	fOrigin[2] += 99.0;
	
	// teleportujemy klienta na podane origin
	TeleportEntity(client, fOrigin, NULL_VECTOR, NULL_VECTOR); // tutaj wyobraź sobię, że nad klientem jest inny obiekt, jeżeli go tam podrzucisz, możesz zbierać to co z niego zostanie
	
	// trzeba pamietac, że klient użył komendy
	g_bUsed[client] = true;
	
	// Twoje info
	CPrintToChat(client, "{lime}[UnBlock]{default} You have been teleported");
	PrintToServer( "Gracz uzyl ub");
	
	// zatrzymujemy w tym miejscu wykonywanie funkcji dalej, aby gra nie zwróciła "Unknown command" w konsoli
	return Plugin_Handled;
}

public Action Listener_LookAtWeapon(int client, const char[] command, int argc)
{
	// jeżeli gracz jest martwy lub czas minął a gracze lubią się bawić +lookatweapon, po co spamować 
	if(GetTime() - g_iRoundStart > 15 || !IsPlayerAlive(client))
		return Plugin_Continue;	

	// Wywołujemy nasz handler komendy
	CMD_UnBlock(client, 0);

	// jak gdyby nigdy nic
	return Plugin_Continue;
}
/*
 * Knife damage change + info hud
 * Welcome info
 * Spawn features - knife/awp/pistol removed and fixed
 * Custom config loader 
 * Set hostname with special chars
 * 
 * 
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define 	SERVER_HOST 		"Katujemy.eu"
#define 	SERVER_ADDRESS		"127.0.0.1:27015"
#define		SERVER_DOMAIN		""
#define 	SERVER_OWNER		"n.o.x & Godziu"
#define 	SERVER_NAME			"Only AWP #2"
#define		SERVER_VERSION		"1.2.13"
#define		SERVER_LAST_UP		"04/05/2020"

public Plugin myinfo =
{
    name = "[n.o.x] AWP Core",
    author = "n.o.x",
    description = "Server core for AWP ONLY mode",
    version = "1.1b",
};

public void OnPluginStart()
{
	// ===== player commands =====
	AddCommandListener(Listener_KillBlock, "kill");
	AddCommandListener(Listener_KillBlock, "explode");
	
	// ===== player events =====
	HookEvent("player_spawn", 		Event_PlayerSpawn);
	HookEvent("player_team", 		Event_PlayerTeam);
}

public void OnMapStart()
{
	ServerCommand("exec awpki.cfg");
	ServerCommand("hostname ██ Katujemy.eu | Only AWP #2 • 128TR • UNIKAT • [Skins/Knife/Gloves/STORE]");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, SDK_TakeDamage);
}

public Action SDK_TakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!IsValidClient(attacker))
		return Plugin_Continue;
	
	if(GetClientTeam(attacker) == GetClientTeam(victim))
		return Plugin_Continue;
	
	char sWeapon[32], sDmg[128];
	GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
	
	// check if client is using knife 
	if(StrContains(sWeapon, "knife") != -1 || StrContains(sWeapon, "bayonet") != -1)
	{
		// check if client stab victim with right click or left click, then set damage
		if(GetClientButtons(attacker) & IN_ATTACK2)
			damage = 30.0;
		else 
			damage = 15.0;
		
		Format(sDmg, sizeof(sDmg), "<font face='Stratum2'><font color='#00FF00'>-%.f</font></font>", damage);
		PrintHintText(attacker, sDmg);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
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
		PrintToConsole(client, "[%s] IP serwera: %s", SERVER_HOST, SERVER_ADDRESS);
		PrintToConsole(client, "--------------------------------------------------");
		
		PrintToChat(client, "------------------------------------------------------------------");
		PrintToChat(client, " \x02[\x04%s\x02] \x04Witamy na serwerze \x02%s", SERVER_HOST, SERVER_NAME);
		PrintToChat(client, " \x02[\x04%s\x02] \x04Aktualna wersja serwera: \x02%s", SERVER_HOST, SERVER_VERSION);
		PrintToChat(client, " \x02[\x04%s\x02] \x04Ostatnia aktualizacja serwera: \x02%s", SERVER_HOST, SERVER_LAST_UP);
		PrintToChat(client, " \x02[\x04%s\x02] \x04Założycielem tego serwera jest \x02%s", SERVER_HOST, SERVER_OWNER);
		PrintToChat(client, "------------------------------------------------------------------");
		
		switch(DayOfWeek()) {
			case 0: {
				PrintToConsole(client, "[%s] Dzisiaj jest Niedziela", SERVER_HOST);
				PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Niedziela", SERVER_HOST);
			} case 1: {
				PrintToConsole(client, "[%s] Dzisiaj jest Poniedziałek", SERVER_HOST);
				PrintToConsole(client, "[%s] Weekend rozpocznie się za 5 dni", SERVER_HOST);
				PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Poniedziałek", SERVER_HOST);
				PrintToChat(client, " \x02[\x04%s\x02] \x04Weekend rozpocznie się za \x025 dni", SERVER_HOST);
			} case 2: {
				PrintToConsole(client, "[%s] Dzisiaj jest Wtorek", SERVER_HOST);
				PrintToConsole(client, "[%s] Weekend rozpocznie się za 4 dni", SERVER_HOST);
				PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Wtorek", SERVER_HOST);
				PrintToChat(client, " \x02[\x04%s\x02] \x04Weekend rozpocznie się za \x024 dni", SERVER_HOST);
			} case 3: {
				PrintToConsole(client, "[%s] Dzisiaj jest Środa", SERVER_HOST);
				PrintToConsole(client, "[%s] Weekend rozpocznie się za 3 dni", SERVER_HOST);
				PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Środa", SERVER_HOST);
				PrintToChat(client, " \x02[\x04%s\x02] \x04Weekend rozpocznie się za \x023 dni", SERVER_HOST);
			} case 4: {
				PrintToConsole(client, "[%s] Dzisiaj jest Czwartek", SERVER_HOST);
				PrintToConsole(client, "[%s] Weekend rozpocznie się za 2 dni", SERVER_HOST);
				PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Czwartek", SERVER_HOST);
				PrintToChat(client, " \x02[\x04%s\x02] \x04Weekend rozpocznie się za \x022 dni", SERVER_HOST);
			} case 5: {
				PrintToConsole(client, "[%s] Dzisiaj jest Piątek", SERVER_HOST);
				PrintToConsole(client, "[%s] Weekend rozpocznie się jutro", SERVER_HOST);
				PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Piątek", SERVER_HOST);
				PrintToChat(client, " \x02[\x04%s\x02] \x04Weekend rozpocznie się \x02jutro", SERVER_HOST);
			} case 6: {
				PrintToConsole(client, "[%s] Dzisiaj jest Sobota", SERVER_HOST);
				PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x02Sobota", SERVER_HOST);
			}
		}
		
		if(DayOfWeek() == 6 || DayOfWeek() == 0)
		{
			PrintToChat(client, " \x02[\x04%s\x02] \x04Dzisiaj jest \x04weekend", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04Z tego powodu, na serwerze wszyscy mają:", SERVER_HOST);
			PrintToChat(client, " \x02[\x04%s\x02] \x04--> Zwiększoną ilość otrzymywanych monet", SERVER_HOST);
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

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client))
		return;
	
	if(GameRules_GetProp("m_bWarmupPeriod") != 1) {
		
		int iTempWeapon = GetPlayerWeaponSlot(client, 0);
		if(iTempWeapon != -1)
			SafeRemoveWeapon(client, iTempWeapon);
		
		CreateTimer(0.05, Timer_Spawn, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Listener_KillBlock(int client, const char[] command, int argc)
{
    PrintToChat(client, " \x02[\x04%s\x02] \x04Ta komenda jest \x02zablokowana\x04!", SERVER_HOST);
    return Plugin_Handled;
} 

public Action Timer_Spawn(Handle timer, any client)
{
	// Strip player secondary weapon
	int iTempWeapon = GetPlayerWeaponSlot(client, 1);
	if(iTempWeapon != -1)
		SafeRemoveWeapon(client, iTempWeapon);
	
	// Strip player knifes (we're doing it 2 times cause weapons.smx suck as well )
	for(int i = 0; i < 2; i++)
		if((iTempWeapon = GetPlayerWeaponSlot(client, 2)) != -1)
			SafeRemoveWeapon(client, iTempWeapon);
	
	// give new awp
	if(GetPlayerWeaponSlot(client, 0) == -1)
		GivePlayerItem(client, "weapon_awp");
	
	// give new knife
	GivePlayerItem(client, "weapon_knife");
	
	// set player armor
	SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
}

bool SafeRemoveWeapon(int client, int weapon)
{
	if (!IsValidEntity(weapon) || !IsValidEdict(weapon))
		return false;
	
	if (!HasEntProp(weapon, Prop_Send, "m_hOwnerEntity"))
		return false;
	
	int iOwnerEntity = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (iOwnerEntity != client)
		SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
	
	CS_DropWeapon(client, weapon, false);
	
	if (HasEntProp(weapon, Prop_Send, "m_hWeaponWorldModel")) {
		int iWorldModel = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
		if (IsValidEdict(iWorldModel) && IsValidEntity(iWorldModel))
			if (!AcceptEntityInput(iWorldModel, "Kill"))
				return false;
	}
	
	if (!AcceptEntityInput(weapon, "Kill"))
		return false;
	return true;
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
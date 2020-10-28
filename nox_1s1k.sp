#include <sourcemod>
#include <sdkhooks>

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, SDK_TakeDamage);
}

public Action SDK_TakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!IsValidClient(attacker))
		return Plugin_Continue;
	
	if(GetAdminFlag(GetUserAdmin(attacker), Admin_Reservation) || GetAdminFlag(GetUserAdmin(attacker), Admin_Root))
	{
		damage = float(GetClientHealth(victim) + 1)
		PrintToChatAll("test");
		return Plugin_Changed;
	}	
	return Plugin_Continue;
}
	
bool IsValidClient(client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <nox_mbhop>
#include <nox_ashop>
#include <smlib>

// ----------------------------- Macro ---------------------------
#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)\
if(IsClientInGame(%1) && !IsFakeClient(%1))

enum VelocityOverride
{
	VelocityOvr_None = 0,
	VelocityOvr_Velocity,
	VelocityOvr_OnlyWhenNegative,
	VelocityOvr_InvertReuseVelocity
};

int g_iClientJumps					[MAXPLAYERS+1];
int	g_iClientMaxJumps				[MAXPLAYERS+1];
bool g_bAuto						[MAXPLAYERS+1];

float g_flPlugin_Boost_Double 		= 290.0;
float g_flPlugin_Boost_Forward		= 0.0;

int g_Offset_m_flStamina 			= -1;
int g_Offset_m_flVelocityModifier 	= -1;

public Plugin myinfo = 
{
	name = "[n.o.x] Multi BHOP",
	author = "n.o.x",
	description = "| System BHOP pozwalający na wykonanie dodatkowych skoków w powietrzu |",
	version = "1.0B",
	url = "http://noxsp.pl"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("MBHOP_GetClientJumpsCount", 	Native_GetClientJumpsCount);
	CreateNative("MBHOP_SetClientJumpsCount", 	Native_SetClientJumpsCount);
	CreateNative("MBHOP_AddClientJumps",		Native_AddClientJumps);
	CreateNative("MBHOP_SubClientJumps",		Native_SubClientJumps);
	
	RegPluginLibrary("nox_mbhop");
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_autobh", 	CMD_AutoBH, "Wlacz/Wylacz AutoBHOP.");
	RegConsoleCmd("sm_bhop", 	CMD_AutoBH, "Wlacz/Wylacz AutoBHOP.");
	RegConsoleCmd("sm_bh", 		CMD_AutoBH, "Wlacz/Wylacz AutoBHOP.");
	RegConsoleCmd("sm_ab", 		CMD_AutoBH, "Wlacz/Wylacz AutoBHOP.");
}

public Action ___________________________________________________________(){}
public void OnMapStart()
{
	ConVar sv_enablebunnyhopping = FindConVar("sv_enablebunnyhopping");
	sv_enablebunnyhopping.SetBool(true, true, false);
	
	ConVar sv_maxspeed = FindConVar("sv_maxspeed");
	sv_maxspeed.SetInt(9999, true, false);
	
	ConVar sv_gravity = FindConVar("sv_gravity");
	sv_gravity.SetInt(800, true, false);
	
	ConVar sv_accelerate = FindConVar("sv_accelerate");
	sv_accelerate.SetInt(5, true, false);
	
	ConVar sv_airaccelerate = FindConVar("sv_airaccelerate");
	sv_airaccelerate.SetInt(1000, true, false);
	
	ConVar sv_maxvelocity = FindConVar("sv_maxvelocity");
	sv_maxvelocity.SetInt(9999, true, false);
	
	ConVar sv_staminajumpcast = FindConVar("sv_staminajumpcost");
	sv_staminajumpcast.SetInt(0, true, false);
	
	ConVar sv_staminalandcast = FindConVar("sv_staminalandcost");
	sv_staminalandcast.SetInt(0, true, false);
	
	ConVar sv_staminamax = FindConVar("sv_staminamax");
	sv_staminamax.SetInt(0, true, false);
}

public void OnClientPutInServer(int client)
{
	g_iClientMaxJumps[client] = 0;
	if(g_Offset_m_flStamina != -1 && g_Offset_m_flVelocityModifier != -1)
		return;
	
	if(!IsValidEntity(client))
		return;
	
	char netclass[64];
	GetEntityNetClass(client, netclass, sizeof(netclass));
	
	g_Offset_m_flStamina = FindSendPropInfo(netclass, "m_flStamina");
	g_Offset_m_flVelocityModifier = FindSendPropInfo(netclass, "m_flVelocityModifier");
}

public void OnClientDisconnect(int client)
{
	g_iClientMaxJumps[client] = 0;
}

public Action __________________________________________________________(){}
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	return HandleJumping(client, buttons);
}

public Action _________________________________________________________(){}
public Action CMD_AutoBH(int client, int args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	
	g_bAuto[client] = !g_bAuto[client];
	PrintToChat(client, " \x02[\x04MBHOP\x02] \x04Autobhop został \x02%s.", g_bAuto[client]? "\x04włączony":"\x02wyłączony");

	return Plugin_Handled;
}

public Action ________________________________________________________(){}
public Action HandleJumping(int client, int &buttons)
{
	if(Client_GetWaterLevel(client) > Water_Level:WATER_LEVEL_FEET_IN_WATER)
		return Plugin_Continue;
	
	if(Client_IsOnLadder(client))
		return Plugin_Continue;
	
	static ls_iLastButtons[MAXPLAYERS+1] = {0,...};
	static ls_iLastFlags[MAXPLAYERS+1] = {0,...};
	
	int flags = GetEntityFlags(client);
	
	float clientEyeAngles[3];
	GetClientEyeAngles(client, clientEyeAngles);
	
	if(flags & FL_ONGROUND)
		g_iClientJumps[client] = 1;
	
	if(buttons & IN_JUMP)
	{
		if(flags & FL_ONGROUND)
		{
			// we don't want to boost client.. 
			if(g_flPlugin_Boost_Forward != 0.0)
			{
				clientEyeAngles[0] = 0.0;
				
				if(buttons & IN_BACK){
					clientEyeAngles[1] += 180.0;
					Client_Push(client,clientEyeAngles,g_flPlugin_Boost_Forward,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
				}
				
				if(buttons & IN_MOVELEFT){
					clientEyeAngles[1] += 90.0;
					Client_Push(client,clientEyeAngles,g_flPlugin_Boost_Forward,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
				}
				
				if(buttons & IN_MOVERIGHT){
					clientEyeAngles[1] += -90.0;
					Client_Push(client,clientEyeAngles,g_flPlugin_Boost_Forward,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
				}
			}
			
			ls_iLastButtons[client] = buttons;
		}
		else
		{
			if(!(ls_iLastButtons[client] & IN_JUMP))
				Client_DoubleJump(client);
			
			ls_iLastButtons[client] = buttons;
			buttons &= ~IN_JUMP;
		}
	}
	else 
		ls_iLastButtons[client] = buttons;
	ls_iLastFlags[client] = flags;
	return Plugin_Continue;
}

public void Client_JumpSys_Initialize(client)
{
	if(g_Offset_m_flStamina != -1 && g_Offset_m_flVelocityModifier != -1)
		return;
	
	if(!IsValidEntity(client))
		return;
	
	char netclass[64];
	GetEntityNetClass(client,netclass,sizeof(netclass));
	
	g_Offset_m_flStamina = FindSendPropInfo(netclass,"m_flStamina");
	g_Offset_m_flVelocityModifier = FindSendPropInfo(netclass,"m_flVelocityModifier");
}

public void Client_Push(int client, float clientEyeAngle[3], float power, VelocityOverride:override[3])
{
	float forwardVector[3], newVel[3];
	
	GetAngleVectors(clientEyeAngle, forwardVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(forwardVector, forwardVector);
	ScaleVector(forwardVector, power);
	
	Entity_GetAbsVelocity(client,newVel);
	
	for(int i=0;i<3;i++)
	{
		switch(override[i])
		{
			case VelocityOvr_Velocity: newVel[i] = 0.0;
			case VelocityOvr_OnlyWhenNegative: if(newVel[i] < 0.0) newVel[i] = 0.0;
			case VelocityOvr_InvertReuseVelocity: if(newVel[i] < 0.0) newVel[i] *= -1.0;
		}
		
		newVel[i] += forwardVector[i];
	}
	
	Entity_SetAbsVelocity(client,newVel);
}

public void Client_DoubleJump(client)
{
	if((1 <= g_iClientJumps[client] <= g_iClientMaxJumps[client]))
	{
		g_iClientJumps[client]++;
		Client_Push(client, view_as<float>({-90.0,0.0,0.0}),g_flPlugin_Boost_Double,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_Velocity});
	}
}

public Action _______________________________________________________(){}
public Native_GetClientJumpsCount(Handle plugin, int numParams)
{
	return g_iClientMaxJumps[GetNativeCell(1)];
}

public Native_SetClientJumpsCount(Handle plugin, int numParams)
{
	g_iClientMaxJumps[GetNativeCell(1)] = GetNativeCell(2);
}

public Native_AddClientJumps(Handle plugin, int numParams)
{
	g_iClientMaxJumps[GetNativeCell(1)] += GetNativeCell(2);
}

public Native_SubClientJumps(Handle plugin, int numParams)
{
	g_iClientMaxJumps[GetNativeCell(1)] -= GetNativeCell(2);
}

public Action _____________________________________________________(){}
bool IsValidClient(client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
		return true;

	return false;
}
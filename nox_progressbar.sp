#pragma semicolon 1

#include <sourcemod>
#include <nox_timer>
#include <deathrun>

float fTime = 6.0;
float fCurrent = 0.0;

// ----------------------------- Macro ---------------------------
#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)\
if(IsClientInGame(%1) && !IsFakeClient(%1))
	
#define CHAR_PROGRESS "█"
#define CHAR_BLANK "░"

public void OnPluginStart()
{
	CreateTimer(0.1, Timer_UpdateHUD, INVALID_HANDLE, TIMER_REPEAT);
	RegConsoleCmd("sm_progressbar", CMD_HUD);
}

public Action ________________________________________________________(){}
public Action CMD_HUD(int client, int args)
{
	if(fCurrent == 0.0)
		fCurrent = 0.1;
	else 
		fCurrent = 0.0;
	return Plugin_Handled;
}

public Action _______________________________________________________(){} // [███████░░░░░░░░░░░░░░░]
public Action Timer_UpdateHUD(Handle Timer)
{
	LoopClients(i)
	{
		if(fCurrent == 0.0)
			return Plugin_Handled;
		
		char sBuffer[64] = "[";
		int iProgress = RoundToZero((fCurrent/fTime)*20.0);
		
		for(int j; j < iProgress; j++)
			Format(sBuffer, sizeof(sBuffer), "%s%s", sBuffer, CHAR_PROGRESS);
		
		for(int j; j < 20-iProgress; j++)
			Format(sBuffer, sizeof(sBuffer), "%s%s", sBuffer, CHAR_BLANK);
		
		Format(sBuffer, sizeof(sBuffer), "%s]", sBuffer);
		
		SetHudTextParams(0.4, 0.6, 0.2, 0, 255, 0, 255, 2, 0.0, 0.0, 0.0);
		ShowHudText(i, -1, sBuffer);
		
		if(fCurrent >= fTime)
		{
			fCurrent = 0.0;
			PrintToChat(i, " \x02[Diablo] \x04Naładowałeś skilla!");
		}
		else
			fCurrent += 0.1;
			
	}
	return Plugin_Continue;
}
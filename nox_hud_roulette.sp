#pragma semicolon 1

#include <sourcemod>

// ----------------------------- Macro ---------------------------
#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)\
if(IsClientInGame(%1) && !IsFakeClient(%1))
	
#define 	CHAR_PICKER_LEFT 	"»"
#define 	CHAR_PICKER_RIGHT 	"«"
#define 	CHAR_BLANK 			"░"

#define 	ROULETTE_TIME		8.0
#define 	START_INTERVAL		0.15


// Lista itemow do losowania bedzie pobierana z array'a, na ta chwile array bedzie stały, potem pobierane z pliku
// Szybkosc przewijania itemów będzie się stopniowo zmniejszała, od odświeżania 0.01 do 7.0, na końcu się zatzyma
// Wyświetlać będzie 3 itemy, na środku będzie strzałka, pokazująca  który item jest bieżący
// Interval będzie zaczynał się od 0.25 a kończył na 0.5, 5 faz, zmianiane podczas trwania timera, poprzez zamykanie handle i odpalenie nowego z innym intervałem
// Interval zmniejsze o polowe, ale dodam warunek do zwiekszania indexu 1/3

Handle g_hTimer = INVALID_HANDLE;

float fCurrentTime = 0.0;
float fCurrentInterval = 0.0;

int g_iIndex = -1;
bool g_bIncrement = false;

char g_sItemNames[][] =
{
	"AK47 | The Empress", 
	"AK47 | Bloodsport", 	
	"AK47 | Case Hardened", 
	"AK47 | Redline", 
	"AK47 | Safari Mesh", 
	"AK47 | Hydrophonic", 
	"AK47 | Blue Laminate", 
	"AK47 | Red Laminate", 
	"AK47 | Westerband Label", 
	"AK47 | Predator", 
	"AK47 | Cartel"
};

char g_sItemColors[][] =
{
	"red",
	"red",
	"red",
	"yellow",
	"yellow",
	"yellow",
	"blue",
	"blue",
	"green",
	"green",
	"green"
};
	
public void OnPluginStart()
{
	RegConsoleCmd("sm_test", CMD_HUD);
}

public OnMapEnd()
{
	// Kill timer
	if(g_hTimer != INVALID_HANDLE)
    {
        CloseHandle(g_hTimer);
        g_hTimer = INVALID_HANDLE;
    }	
}

public Action ________________________________________________________(){}
public Action CMD_HUD(int client, int args)
{
	if(fCurrentTime == 0.0)
	{
		// Set info
		g_iIndex = GetRandomInt(0, sizeof(g_sItemNames)); 
		fCurrentInterval = START_INTERVAL;
		fCurrentTime = fCurrentInterval;
		g_bIncrement = true;
		
		// Start the game
		g_hTimer = CreateTimer(fCurrentInterval, Timer_UpdateHUD, INVALID_HANDLE, TIMER_REPEAT);
	}
	else // Stop the game
		fCurrentTime = 0.0; 
	
	return Plugin_Handled;
}

public Action _______________________________________________________(){}
public Action Timer_UpdateHUD(Handle Timer)
{
	// Return if party is inactive
	if(fCurrentTime == 0.0)
		return Plugin_Stop;
	
	// When case will end, start from begin
	if(g_iIndex == sizeof(g_sItemNames))
		g_iIndex = 0;
	
	// Go to next item in case
	if(g_bIncrement)
	{
		g_iIndex++;
		g_bIncrement = false;
	}
	else
		g_bIncrement = true;
		
	// Display lottery
	char sHintText[128];
	Format(sHintText, 128, "<font size='16'>\n"); 
	Format(sHintText, 128, "%s%s %s\n", sHintText, CHAR_BLANK, g_iIndex != 0 ? g_sItemNames[g_iIndex-1]:g_sItemNames[sizeof(g_sItemNames)-1]); 
	Format(sHintText, 128, "%s%s %s %s\n", sHintText, CHAR_PICKER_LEFT, g_sItemNames[g_iIndex], CHAR_PICKER_RIGHT); 
	Format(sHintText, 128, "%s%s %s\n", sHintText, CHAR_BLANK, g_iIndex != sizeof(g_sItemNames)-1 ? g_sItemNames[g_iIndex+1] : g_sItemNames[0]); 
	Format(sHintText, 128, "%s</font>", sHintText);  
	PrintHintTextToAll(sHintText);
	
	// Stop and take results when time is up
	if(fCurrentTime >= ROULETTE_TIME)
	{
		//Print Info
		PrintToChatAll(" \x02[NOX] \x04Wylosowałeś %s!", g_sItemNames[g_iIndex]);
		
		//Reset info
		fCurrentTime = 0.0;
		g_iIndex = -1;
		g_bIncrement = false;
	}
	else
		fCurrentTime += fCurrentInterval; // increment + 0.1s 
	
	// Change interval, after 2 seconds += 0.05
	if((fCurrentTime >= 2.0 && fCurrentInterval == START_INTERVAL)
	|| (fCurrentTime >= 4.0 && fCurrentInterval == START_INTERVAL+0.05)
	|| (fCurrentTime >= 6.0 && fCurrentInterval == START_INTERVAL+0.1))
		ChangeInterval();
	
	return Plugin_Continue;
}

public void ChangeInterval()
{
	// Change interval
	fCurrentInterval = fCurrentInterval+0.05;
	
	// Kill timer
	if(g_hTimer != INVALID_HANDLE)
    {
        CloseHandle(g_hTimer);
        g_hTimer = INVALID_HANDLE;
    }
	
	// Continue timer
	g_hTimer = CreateTimer(fCurrentInterval, Timer_UpdateHUD, INVALID_HANDLE, TIMER_REPEAT);
}
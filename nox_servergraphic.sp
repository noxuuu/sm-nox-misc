#include <sourcemod>
#include <sdktools>

public OnMapStart()
{
	//AddFileToDownloadsTable("logo_ftg.png");
	Handle g_hGraphicCvar = FindConVar("sv_server_graphic1");
	SetConVarString(g_hGraphicCvar, "logo_ftg.png");
}
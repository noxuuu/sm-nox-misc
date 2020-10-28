#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <cstrike>
#include <kento_csgocolors>

#define     FlashbangOffset         15

#define MAX_MVP_COUNT 1000

#pragma newdecls required

int MVPCount, Selected[MAXPLAYERS + 1];

char Configfile[1024], 
	g_sMVPName[MAX_MVP_COUNT + 1][1024], 
	g_sMVPFile[MAX_MVP_COUNT + 1][1024],
	NameMVP[MAXPLAYERS + 1][1024];

Handle mvp_cookie, mvp_cookie2, mvp_cookie3;

float VolMVP[MAXPLAYERS + 1];

//emotes
float g_fLastAngles[MAXPLAYERS+1][3];
float g_fLastPosition[MAXPLAYERS+1][3];

int g_iEmoteEnt[MAXPLAYERS+1];

char g_sPrimaryWeapon[MAXPLAYERS + 1][32];
char g_sSecondaryWeapon[MAXPLAYERS + 1][32];
char g_sKnife[MAXPLAYERS + 1][32];
char g_sGrenades[MAXPLAYERS + 1][4][32];
bool g_bTaser[MAXPLAYERS + 1];

int g_iPrimaryWeaponClip[MAXPLAYERS+1];
int g_iPrimaryWeaponAmmo[MAXPLAYERS+1];

int g_iSecondaryWeaponClip[MAXPLAYERS+1];
int g_iSecondaryWeaponAmmo[MAXPLAYERS+1];

int g_iTaserClip[MAXPLAYERS+1];
int g_iTaserAmmo[MAXPLAYERS+1];

int g_iFlashbangAmmo[MAXPLAYERS+1];

bool g_bDance[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[NOX] Custom MVP prefferences",
	author = "n.o.x",
	version = "1.24",
	description = "Custom MVP Prefferences",
	url = "https://nwxstudio.pl"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_mvp", Command_MVP, "Wybierz swoje MPV!");
	RegConsoleCmd("sm_res", Command_MVP, "Wybierz swoje MPV!");
	RegConsoleCmd("sm_sound", Command_MVP, "Wybierz swoje MPV!");
	RegConsoleCmd("sm_vol", Command_MVPVol, "MVP Volume");
	
	HookEvent("round_mvp", 		Event_RoundMVP);
	HookEvent("player_death", 	Event_PlayerDeath, 	EventHookMode_Pre);

	
	mvp_cookie = RegClientCookie("mvp_name", "Player's MVP Anthem", CookieAccess_Private);
	mvp_cookie2 = RegClientCookie("mvp_vol", "Player MVP volume", CookieAccess_Private);
	mvp_cookie3 = RegClientCookie("mvp_dance", "Player MVP dance prefferences", CookieAccess_Private);
	

	for(int i = 1; i <= MaxClients; i++)
	{ 
		if(IsValidClient(i) && !IsFakeClient(i) && !AreClientCookiesCached(i))	OnClientCookiesCached(i);
	}
}

public void OnMapStart()
{
	AddFileToDownloadsTable("models/player/custom_player/kodua/fortnite_emotes_v2_demo.mdl");
	AddFileToDownloadsTable("models/player/custom_player/kodua/fortnite_emotes_v2_demo.vvd");
	AddFileToDownloadsTable("models/player/custom_player/kodua/fortnite_emotes_v2_demo.dx90.vtx");

	PrecacheModel("models/player/custom_player/kodua/fortnite_emotes_v2_demo.mdl", true);
	
	ServerCommand("mp_round_restart_delay 11");
	ServerCommand("sv_allow_thirdperson 1");
}

public void OnClientPutInServer(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))	OnClientCookiesCached(client);
}

public void OnClientCookiesCached(int client)
{
	if(!IsValidClient(client) && IsFakeClient(client))	return;
		
	char scookie[1024];
	GetClientCookie(client, mvp_cookie, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		Selected[client] = FindMVPIDByName(scookie);
		if(Selected[client] > 0)	strcopy(NameMVP[client], sizeof(NameMVP[]), scookie);
		else 
		{
			NameMVP[client] = "";
			SetClientCookie(client, mvp_cookie, "");
		}
	}
	else if(StrEqual(scookie,""))	NameMVP[client] = "";	
		
	GetClientCookie(client, mvp_cookie2, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		VolMVP[client] = StringToFloat(scookie);
	}
	else if(StrEqual(scookie,""))	VolMVP[client] = 1.0;
		
	GetClientCookie(client, mvp_cookie3, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		if(StrEqual(scookie, "true"))
			g_bDance[client] = true;
		else if(StrEqual(scookie, "false"))
			g_bDance[client] = false;
	}
	else if(StrEqual(scookie,""))	g_bDance[client] = true;
}

public void OnConfigsExecuted()
{
	LoadConfig();
}

public Action Event_RoundMVP(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(StrEqual(NameMVP[client], "") || Selected[client] == 0)	return;
	
	int mvp = Selected[client];
	
	char sound[1024];
	Format(sound, sizeof(sound), "*/%s", g_sMVPFile[mvp]);
	
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i))
			{
				// Announce MVP
				PrintHintText(i, "MVP <font color='#B15BFF'>%N</font> - <font color='#FF0000'>%s</font>", client, g_sMVPName[mvp]);
					
				// Mute game sound
				ClientCommand(i, "playgamesound Music.StopAllMusic");
				
				// Play MVP Anthem
				EmitSoundToClient(i, sound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, VolMVP[i]);
				
				// Start Dance
				if(g_bDance[client])
					CreateEmote(client, "DanceMoves", "none");
			}	
		}
	}
}	

int FindMVPIDByName(char [] name)
{
	int id = 0;
	
	for(int i = 1; i <= MVPCount; i++)
	{
		if(StrEqual(g_sMVPName[i], name))	id = i;
	}
	
	return id;
}

void LoadConfig()
{
	BuildPath(Path_SM, Configfile, 1024, "configs/kento_mvp.cfg");
	
	if(!FileExists(Configfile))
		SetFailState("Can not find config file \"%s\"!", Configfile);
	
	
	KeyValues kv = CreateKeyValues("MVP");
	kv.ImportFromFile(Configfile);
	
	MVPCount = 1;
	
	// Read Config
	if(kv.GotoFirstSubKey())
	{
		char name[1024];
		char file[1024];
		
		do
		{
			kv.GetSectionName(name, sizeof(name));
			kv.GetString("file", file, sizeof(file));				
			
			strcopy(g_sMVPName[MVPCount], sizeof(g_sMVPName[]), name);
			strcopy(g_sMVPFile[MVPCount], sizeof(g_sMVPFile[]), file);
				
			char filepath[1024];
			Format(filepath, sizeof(filepath), "sound/%s", g_sMVPFile[MVPCount])
			AddFileToDownloadsTable(filepath);
			
			char soundpath[1024];
			Format(soundpath, sizeof(soundpath), "*/%s", g_sMVPFile[MVPCount]);
			FakePrecacheSound(soundpath);
			
			MVPCount++;
		}
		while (kv.GotoNextKey());
	}
	
	kv.Rewind();
	delete kv;
}

public Action Command_MVP(int client,int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu settings_menu = new Menu(SettingsMenuHandler);
		
		char name[1024];
		if(StrEqual(NameMVP[client], ""))	Format(name, sizeof(name), "MVP :: Nie masz ustawionej muzyki na MVP");
		else Format(name, sizeof(name), NameMVP[client]);
		
		char menutitle[1024];
		Format(menutitle, sizeof(menutitle), "MVP :: Ustawienia\n~ Wybrane MVP: %s\n~ Głośność: %.2f\n ", name, VolMVP[client]);
		settings_menu.SetTitle(menutitle);
		
		settings_menu.AddItem("mvp", "Wybierz swoje MVP");
		settings_menu.AddItem("vol", "Zmien głośność MVP");
		settings_menu.AddItem("dance", g_bDance[client] ? "Wyłącz taniec MVP" : "Włącz taniec MVP");
		
		settings_menu.Display(client, 0);
	}
	
	return Plugin_Handled;
}

public int SettingsMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char select[1024];
		GetMenuItem(menu, param, select, sizeof(select));
		
		if(StrEqual(select, "mvp"))
		{
			DisplayMVPMenu(client);
		}
		else if(StrEqual(select, "vol"))
		{
			DisplayVolMenu(client);
		}
		else if(StrEqual(select, "dance"))
		{
			g_bDance[client] = !g_bDance[client];
			
			if(g_bDance[client])
				SetClientCookie(client, mvp_cookie3, "true"); // save choice
			else
				SetClientCookie(client, mvp_cookie3, "false"); // save choice
			
			PrintToChat(client, " \x04[MVP] \x03%s \x01taniec MVP!", g_bDance[client] ? "Włączyłeś" : "Wyłączyłeś");
		}
	}
}

void DisplayMVPMenu(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu mvp_menu = new Menu(MVPMenuHandler);
		
		char name[1024];
		if(StrEqual(NameMVP[client], ""))	Format(name, sizeof(name), "Brak");
		else Format(name, sizeof(name), NameMVP[client]);
		
		char mvpmenutitle[1024];
		Format(mvpmenutitle, sizeof(mvpmenutitle), "MVP :: Wybierz swoje MVP", name);
		mvp_menu.SetTitle(mvpmenutitle);
		
		mvp_menu.AddItem("", "Brak");
		
		for(int i = 1; i < MVPCount; i++)
			mvp_menu.AddItem(g_sMVPName[i], g_sMVPName[i]);
		
		mvp_menu.Display(client, 0);
	}
}

public int MVPMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char mvp_name[1024];
		GetMenuItem(menu, param, mvp_name, sizeof(mvp_name));
		
		if(StrEqual(mvp_name, ""))
		{
			PrintToChat(client, " \x04[MVP] \x01Zmieniłeś swoje MVP na \x03Domyślne");
			Selected[client] = 0;
		}
		else
		{
			PrintToChat(client, " \x04[MVP] \x01Zmieniłeś swoje MVP na \x03%s", mvp_name);
			Selected[client] = FindMVPIDByName(mvp_name);
		}
		
		strcopy(NameMVP[client], sizeof(NameMVP[]), mvp_name);
		SetClientCookie(client, mvp_cookie, mvp_name);
	}
}

void DisplayVolMenu(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu vol_menu = new Menu(VolMenuHandler);
		
		char vol[1024];
		if(VolMVP[client] > 0.00)	Format(vol, sizeof(vol), "%.2f", VolMVP[client]);
		else Format(vol, sizeof(vol), "[!] Wyciszono");
		
		char menutitle[1024];
		Format(menutitle, sizeof(menutitle), "MVP :: Ustawienia głośnośći\n ~ Aktualna głośność: [%.2f]", vol);
		vol_menu.SetTitle(menutitle);
		
		
		vol_menu.AddItem("0", "Wycisz");
		vol_menu.AddItem("0.2", "20%");
		vol_menu.AddItem("0.4", "40%");
		vol_menu.AddItem("0.6", "60%");
		vol_menu.AddItem("0.8", "80%");
		vol_menu.AddItem("1.0", "100%");
		vol_menu.Display(client, 0);
	}
}

public int VolMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char vol[1024];
		GetMenuItem(menu, param, vol, sizeof(vol));
		
		VolMVP[client] = StringToFloat(vol);
		PrintToChat(client, " \x04[MVP] \x01Głośność ustawiona na \x04%.2f", VolMVP[client]);
		
		SetClientCookie(client, mvp_cookie2, vol);
	}
}

public Action Command_MVPVol(int client,int args)
{
	if (IsValidClient(client))
	{
		char arg[20];
		float volume;
		
		if (args < 1)
		{
			PrintToChat(client, " \x04[MVP] \x01Głośność musi być podana w przedziale \x020.1 - 1.0");
			return Plugin_Handled;
		}
			
		GetCmdArg(1, arg, sizeof(arg));
		volume = StringToFloat(arg);
		
		if (volume < 0.0 || volume > 1.0)
		{
			PrintToChat(client, " \x04[MVP] \x01Głośność musi być podana w przedziale \x020.1 - 1.0");
			return Plugin_Handled;
		}
		
		VolMVP[client] = StringToFloat(arg);
		PrintToChat(client, " \x04[MVP] \x01Głośność ustawiona na \x04%.2f", VolMVP[client]);
		
		SetClientCookie(client, mvp_cookie2, arg);
	}
	return Plugin_Handled;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client))
	{
		ResetCam(client);
		StopEmote(client);
	}
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
	if (iButtons == 0)
		return Plugin_Continue;

	if (g_iEmoteEnt[client] == 0)
		return Plugin_Continue;

	if (iButtons & IN_USE) 
		StopEmote(client);

	return Plugin_Continue;
}

public Action CreateEmote(int client, const char[] anim1, const char[] anim2)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (!IsPlayerAlive(client) || !(GetEntityFlags(client) & FL_ONGROUND) || GetEntityMoveType(client) == MOVETYPE_NONE || !(GetEntityFlags(client) & FL_ONGROUND))
		return Plugin_Handled;

	int EmoteEnt = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(EmoteEnt))
	{
		SetEntityMoveType(client, MOVETYPE_NONE);
		DisarmPlayer(client);

		float vec[3], ang[3];
		GetClientAbsOrigin(client, vec);
		GetClientAbsAngles(client, ang);

		Array_Copy(vec, g_fLastPosition[client], 3);
		Array_Copy(ang, g_fLastAngles[client], 3);

		char emoteEntName[16];
		FormatEx(emoteEntName, sizeof(emoteEntName), "emoteEnt%i", GetRandomInt(1000000, 9999999));
		
		DispatchKeyValue(EmoteEnt, "targetname", emoteEntName);
		DispatchKeyValue(EmoteEnt, "model", "models/player/custom_player/kodua/fortnite_emotes_v2.mdl");
		DispatchKeyValue(EmoteEnt, "solid", "0");
		DispatchKeyValue(EmoteEnt, "rendermode", "10");

		ActivateEntity(EmoteEnt);
		DispatchSpawn(EmoteEnt);

		TeleportEntity(EmoteEnt, g_fLastPosition[client], g_fLastAngles[client], NULL_VECTOR);
		
		SetVariantString(emoteEntName);
		AcceptEntityInput(client, "SetParent", client, client, 0);

		g_iEmoteEnt[client] = EntIndexToEntRef(EmoteEnt);

		int enteffects = GetEntProp(client, Prop_Send, "m_fEffects");
		enteffects |= 1; /* This is EF_BONEMERGE */
		enteffects |= 16; /* This is EF_NOSHADOW */
		enteffects |= 64; /* This is EF_NORECEIVESHADOW */
		enteffects |= 128; /* This is EF_BONEMERGE_FASTCULL */
		enteffects |= 512; /* This is EF_PARENT_ANIMATES */
		SetEntProp(client, Prop_Send, "m_fEffects", enteffects);


		if (StrEqual(anim2, "none", false))
		{
			HookSingleEntityOutput(EmoteEnt, "OnAnimationDone", EndAnimation, true);
		} else
		{
			SetVariantString(anim2);
			AcceptEntityInput(EmoteEnt, "SetDefaultAnimation", -1, -1, 0);
		}

		SetVariantString(anim1);
		AcceptEntityInput(EmoteEnt, "SetAnimation", -1, -1, 0);

		SetCam(client);
	}
	return Plugin_Handled;
}

void StopEmote(int client)
{
	if (!g_iEmoteEnt[client])
		return;

	int iEmoteEnt = EntRefToEntIndex(g_iEmoteEnt[client]);
	if (iEmoteEnt && iEmoteEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteEnt))
	{
		AcceptEntityInput(client, "ClearParent", client, client, 0);
		AcceptEntityInput(iEmoteEnt, "Kill");

		TeleportEntity(client, g_fLastPosition[client], g_fLastAngles[client], NULL_VECTOR);
		ResetCam(client);
		RearmPlayerWithAmmo(client);
		SetEntityMoveType(client, MOVETYPE_WALK);

		g_iEmoteEnt[client] = 0;
	}
	else
		g_iEmoteEnt[client] = 0;
}

public void EndAnimation(const char[] output, int caller, int activator, float delay) 
{
	if (caller > 0)
	{
		activator = GetEmoteActivator(EntIndexToEntRef(caller));
		StopEmote(activator);
	}
}

int GetEmoteActivator(int iEntRefDancer)
{
	if (iEntRefDancer == INVALID_ENT_REFERENCE)
		return 0;
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (g_iEmoteEnt[i] == iEntRefDancer) 
		{
			return i;
		}
	}
	return 0;
}

void SetCam(int client)
{
	ClientCommand(client, "cam_collision 0");
	ClientCommand(client, "cam_idealdist 100");
	ClientCommand(client, "cam_idealpitch 0");
	ClientCommand(client, "cam_idealyaw 0");
	ClientCommand(client, "thirdperson");
	ClientCommand(client, "thirdperson");
}

void ResetCam(int client)
{
	ClientCommand(client, "firstperson");
	ClientCommand(client, "cam_collision 1");
	ClientCommand(client, "cam_idealdist 150");
}

void DisarmPlayer(int client)
{
	//Primary weapon
	int iPrimary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if (IsValidEntity(iPrimary) && iPrimary != INVALID_ENT_REFERENCE && iPrimary != -1)
	{
		switch(GetEntProp(iPrimary, Prop_Send, "m_iItemDefinitionIndex"))
		{
			case 23: Format(g_sPrimaryWeapon[client], sizeof(g_sPrimaryWeapon[]), "weapon_mp5sd");
			case 60: Format(g_sPrimaryWeapon[client], sizeof(g_sPrimaryWeapon[]), "weapon_m4a1_silencer");
			default: GetEntityClassname(iPrimary, g_sPrimaryWeapon[client], sizeof(g_sPrimaryWeapon[]));
		}

		g_iPrimaryWeaponClip[client] = Weapon_GetPrimaryClip(iPrimary);
		g_iPrimaryWeaponAmmo[client] = GetEntProp(iPrimary, Prop_Send, "m_iPrimaryReserveAmmoCount");

		RemovePlayerItem(client, iPrimary);
		AcceptEntityInput(iPrimary, "Kill");
	} else
	{
		Format(g_sPrimaryWeapon[client], sizeof(g_sPrimaryWeapon[]), "empty");
	}

	//Secondary weapon
	int iSecondary = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if (IsValidEntity(iSecondary) && iSecondary != INVALID_ENT_REFERENCE && iSecondary != -1)
	{
		switch(GetEntProp(iSecondary, Prop_Send, "m_iItemDefinitionIndex")) 
		{
			case 61: Format(g_sSecondaryWeapon[client], sizeof(g_sSecondaryWeapon[]), "weapon_usp_silencer");
			case 63: Format(g_sSecondaryWeapon[client], sizeof(g_sSecondaryWeapon[]), "weapon_cz75a");
			case 64: Format(g_sSecondaryWeapon[client], sizeof(g_sSecondaryWeapon[]), "weapon_revolver");
			default: GetEntityClassname(iSecondary, g_sSecondaryWeapon[client], sizeof(g_sSecondaryWeapon[]));
		}

		g_iSecondaryWeaponClip[client] = Weapon_GetPrimaryClip(iSecondary);
		g_iSecondaryWeaponAmmo[client] = GetEntProp(iSecondary, Prop_Send, "m_iPrimaryReserveAmmoCount");

		RemovePlayerItem(client, iSecondary);
		AcceptEntityInput(iSecondary, "Kill");
	} else
	{
		Format(g_sSecondaryWeapon[client], sizeof(g_sSecondaryWeapon[]), "empty");
	}

	//Knife & Taser & Nades
	g_iFlashbangAmmo[client] = GetEntProp(client, Prop_Send, "m_iAmmo", _, FlashbangOffset);

	g_bTaser[client] = false;
	Format(g_sKnife[client], sizeof(g_sKnife[]), "empty");

	for (int i = 0; i <= 3; i++) Format(g_sGrenades[client][i], sizeof(g_sGrenades[][]), "empty");
 
	int iWeapon, iGrenade, iWeaponArraySize = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	for (int iIndex = 0; iIndex < iWeaponArraySize; iIndex++)
	{
		iWeapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", iIndex);
		if (IsValidEntity(iWeapon))
		{
			char sWeapon[32];
			GetEntityClassname(iWeapon, sWeapon, sizeof(sWeapon));
			if (StrEqual(sWeapon, "weapon_taser"))
			{
				g_bTaser[client] = true;

				g_iTaserClip[client] = Weapon_GetPrimaryClip(iWeapon);
				g_iTaserAmmo[client] = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryReserveAmmoCount");

				RemovePlayerItem(client, iWeapon);
				AcceptEntityInput(iWeapon, "Kill");
			}
			else if (GetPlayerWeaponSlot(client, 2) == iWeapon)
			{
				GetEntityClassname(iWeapon, g_sKnife[client], sizeof(g_sKnife[]));
				RemovePlayerItem(client, iWeapon);
				AcceptEntityInput(iWeapon, "Kill");
			}
			else if (GetPlayerWeaponSlot(client, 3) == iWeapon)
			{
				if (SafeRemoveWeapon(client, iWeapon, 3))
				{
					GetEntityClassname(iWeapon, g_sGrenades[client][iGrenade], 32);
					iGrenade++;
				}
			}
		}
	}
}

void RearmPlayerWithAmmo(int client)
{
	//Knife
	if (!StrEqual(g_sKnife[client], "empty"))
		GivePlayerItem(client, g_sKnife[client]);

	//Taser
	if (g_bTaser[client])
	{
		GivePlayerItem(client, "weapon_taser");

		int iTaser, iWeaponArraySize = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
		for (int iIndex = 0; iIndex < iWeaponArraySize; iIndex++)
		{
			iTaser = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", iIndex);
			if (IsValidEntity(iTaser))
			{
				char sWeapon[32];
				GetEntityClassname(iTaser, sWeapon, sizeof(sWeapon));
				if (StrEqual(sWeapon, "weapon_taser"))
				{
					SetEntProp(iTaser, Prop_Data, "m_iClip1", g_iTaserClip[client]);
					SetEntProp(iTaser, Prop_Send, "m_iPrimaryReserveAmmoCount", g_iTaserAmmo[client]);
				}
			}
		}
	}

	//Primary weapon
	if (!StrEqual(g_sPrimaryWeapon[client], "empty"))
	{
		GivePlayerItem(client, g_sPrimaryWeapon[client]);

		int iPrimary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		if (IsValidEntity(iPrimary) && iPrimary != INVALID_ENT_REFERENCE && iPrimary != -1)
		{
			char sWeapon[32];
			switch(GetEntProp(iPrimary, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 23: Format(sWeapon, sizeof(sWeapon), "weapon_mp5sd");
				case 60: Format(sWeapon, sizeof(sWeapon), "weapon_m4a1_silencer");
				default: GetEntityClassname(iPrimary, sWeapon, sizeof(sWeapon));
			}
			if (StrEqual(sWeapon, g_sPrimaryWeapon[client]))
			{
				SetEntProp(iPrimary, Prop_Data, "m_iClip1", g_iPrimaryWeaponClip[client]);
				SetEntProp(iPrimary, Prop_Send, "m_iPrimaryReserveAmmoCount", g_iPrimaryWeaponAmmo[client]);
			}
		}
	}

	//Secondary weapon
	if (!StrEqual(g_sSecondaryWeapon[client], "empty"))
	{
		GivePlayerItem(client, g_sSecondaryWeapon[client]);

		int iSecondary = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		if (IsValidEntity(iSecondary) && iSecondary != INVALID_ENT_REFERENCE && iSecondary != -1)
		{
			char sWeapon[32];
			switch(GetEntProp(iSecondary, Prop_Send, "m_iItemDefinitionIndex")) 
			{
				case 61: Format(sWeapon, sizeof(sWeapon), "weapon_usp_silencer");
				case 63: Format(sWeapon, sizeof(sWeapon), "weapon_cz75a");
				case 64: Format(sWeapon, sizeof(sWeapon), "weapon_revolver");
				default: GetEntityClassname(iSecondary, sWeapon, sizeof(sWeapon));
			}
			if (StrEqual(sWeapon, g_sSecondaryWeapon[client]))
			{
				SetEntProp(iSecondary, Prop_Data, "m_iClip1", g_iSecondaryWeaponClip[client]);
				SetEntProp(iSecondary, Prop_Send, "m_iPrimaryReserveAmmoCount", g_iSecondaryWeaponAmmo[client]);
			}
		}
	}

	//Grenades
	for (int i = 0; i <= 3; i++)
	{
		if (StrEqual(g_sGrenades[client][i], "empty")) break;
		GivePlayerItem(client, g_sGrenades[client][i]);
	}
	SetEntProp(client, Prop_Send, "m_iAmmo", g_iFlashbangAmmo[client], _, FlashbangOffset);
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

stock bool SafeRemoveWeapon(int client, int weapon, int slot)
{
    if (HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
    {
        int iDefIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
       
        if (iDefIndex < 0 || iDefIndex > 700)
        {
            return false;
        }
    }
   
    if (HasEntProp(weapon, Prop_Send, "m_bInitialized"))
    {
        if (GetEntProp(weapon, Prop_Send, "m_bInitialized") == 0)
        {
            return false;
        }
    }
   
    if (HasEntProp(weapon, Prop_Send, "m_bStartedArming"))
    {
        if (GetEntSendPropOffs(weapon, "m_bStartedArming") > -1)
        {
            return false;
        }
    }
   
    if (GetPlayerWeaponSlot(client, slot) != weapon)
    {
        return false;
    }
   
    if (!RemovePlayerItem(client, weapon))
    {
        return false;
    }
   
    int iWorldModel = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
   
    if (IsValidEdict(iWorldModel) && IsValidEntity(iWorldModel))
    {
        if (!AcceptEntityInput(iWorldModel, "Kill"))
        {
            return false;
        }
    }
   
    if (weapon == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
    {
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
    }
   
    AcceptEntityInput(weapon, "Kill");
   
    return true;
}

stock void FakePrecacheSound(const char[] szPath)
{
	AddToStringTable(FindStringTable("soundprecache"), szPath);
}
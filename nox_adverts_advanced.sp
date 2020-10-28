#include <sourcemod>
	
#define 	PLUGIN_NAME					"[n.o.x] ADV Advertisements!"
#define 	PLUGIN_AUTHOR				"n.o.x"
#define 	PLUGIN_DESC					"| Advanced adverts system |"
#define 	PLUGIN_VERSION				"1.1b"
#define		PLUGIN_URL					"http://nwxstudio.pl"

Handle g_hSql;
int g_iServerID = -1;
char g_sSettings[32][2][64];
ArrayList g_ArAdverts;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart() 
{
	// admin commands
	RegServerCmd("sm_adverts_reload", CMD_ReloadAds, "Reload the advertisements");
	
	// adverts storage
	g_ArAdverts = CreateArray(128);
	
	// mysql shit 
	DB_Connect();
	DB_LoadSettings();
	DB_GetServerInfo();
	DB_LoadAdverts();
}

public void DB_Connect()
{
	if(SQL_CheckConfig("nox_adv_adverts"))
	{
		char DBBuffer[512];
		g_hSql = SQL_Connect("nox_adv_adverts", true, DBBuffer, sizeof(DBBuffer));
		if (g_hSql == INVALID_HANDLE)
			PrintToServer("[NOX-ADVERTS] Could not connect: %s", DBBuffer);
		else
		{
			SQL_LockDatabase(g_hSql);
			SQL_FastQuery(g_hSql, "CREATE TABLE IF NOT EXISTS nox_adv_adverts (id INT NOT NULL AUTO_INCREMENT, server_id INT NOT NULL, advert_text VARCHAR(256), PRIMARY KEY(id));");
			SQL_FastQuery(g_hSql, "CREATE TABLE IF NOT EXISTS nox_adv_adverts_settings (name VARCHAR(32) NOT NULL, value VARCHAR(64) NOT NULL, PRIMARY KEY(name));");
			SQL_FastQuery(g_hSql, "CREATE TABLE IF NOT EXISTS nox_adv_adverts_servers (id INT NOT NULL AUTO_INCREMENT, ip_address VARCHAR(64), port VARCHAR(12), PRIMARY KEY(id));");
			SQL_UnlockDatabase(g_hSql);
		}
	}
	else
		SetFailState("Nie mozna odnalezc konfiguracji 'nox_adv_adverts' w databases.cfg.");
}

public void DB_GetServerInfo()
{
	char NetIP[64], Port[10], sQuery[256];
	int pieces[4];
	int longip = GetConVarInt(FindConVar("hostip"));
	
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	
	Format(NetIP, sizeof(NetIP), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
	GetConVarString(FindConVar("hostport"), Port, sizeof(Port));
	
	Format(sQuery,sizeof(sQuery),"SELECT id FROM nox_adv_adverts_servers WHERE ip_address = '%s' AND port = '%s'", NetIP, Port);
	
	SQL_LockDatabase(g_hSql);
	Handle hQuery = SQL_Query(g_hSql, sQuery);
	
	if(hQuery == INVALID_HANDLE)
	{
		char sError[255];
		SQL_GetError(g_hSql, sError, sizeof(sError));
		LogError("[NOX-ADVERTS] Query failed: %s", sError);
		CloseHandle(g_hSql);
	}
	else if(SQL_FetchRow(hQuery)) {
		g_iServerID = SQL_FetchInt(hQuery, 0);
	}
	else
	{
		g_iServerID = -1;
		LogError("[NOX-ADVERTS] ServerID is equal -1, add this server in your Admin Panel.");
		SetFailState("[NOX-ADVERTS] ServerID is equal -1, add this server in your Adverts Admin Panel.");
	}
	
	CloseHandle(hQuery);
	SQL_UnlockDatabase(g_hSql);
}

public void DB_LoadSettings()
{
	SQL_TQuery(g_hSql, DB_SettingsHandler, "SELECT name, value FROM nox_adv_adverts_settings WHERE 1");
}

public void DB_SettingsHandler(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
		return;
	}
	
	int size = 0;
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, g_sSettings[size][0], 32);
		SQL_FetchString(hndl, 1, g_sSettings[size][1], 64);
		size++;
	}
	
	
	// call timer now, best moment for it
	if(!StrEqual(GetSettingValue("time_interval"), ""))
		CreateTimer(StringToFloat(GetSettingValue("time_interval")), Timer_DisplayAdvert, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	
	if(size == 0) {
		Transaction txn = new Transaction();
		txn.AddQuery("INSERT INTO nox_adv_adverts_settings (name, value) VALUES ('time_interval', '30.0')");
		txn.AddQuery("INSERT INTO nox_adv_adverts_settings (name, value) VALUES ('hostname', '[mysite.com]')");
		
		// execute transaction
		SQL_ExecuteTransaction(g_hSql, txn)
		
		// load settings again to get default values
		CreateTimer(0.1, Timer_LoadSettings);
	}
}

public void DB_LoadAdverts()
{
	if(g_iServerID == -1)
		return;
	
	char sQuery[128];
	FormatEx(sQuery, sizeof(sQuery), "SELECT advert_text FROM nox_adv_adverts WHERE server_id = %d", g_iServerID);
	SQL_TQuery(g_hSql, DB_AdvertsHandler, sQuery);
}

public void DB_AdvertsHandler(Handle owner, Handle hndl, const char[] error, any data)
{
	g_ArAdverts.Clear();
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("[GET-ADVERTS] Query failed! %s", error);
		return;
	}
	
	char sAdvert[256], sBuffer[256];
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, sAdvert, sizeof(sAdvert));
		bool duplicate = false;
		
		for(int i=0; i< g_ArAdverts.Length; i++)
		{
			g_ArAdverts.GetString(i, sBuffer, sizeof(sBuffer));
			if(StrEqual(sBuffer, sAdvert)) duplicate = true;
		}
		
		if(!duplicate)
			g_ArAdverts.PushString(sAdvert);
	}
}

public Action CMD_ReloadAds(int args)
{
    DB_LoadAdverts();
    return Plugin_Handled;
}

public Action Timer_DisplayAdvert(Handle timer)
{
	if(g_ArAdverts.Length == 0|| g_iServerID == -1)
		return Plugin_Stop;
	
	char sAdvert[256]; 
	g_ArAdverts.GetString(GetRandomInt(0, g_ArAdverts.Length-1), sAdvert, sizeof(sAdvert));
	PrintToChatAll(" %s %s", ProcessColorString(GetSettingValue("hostname")), ProcessColorString(sAdvert));
	
	return Plugin_Continue;
}

public Action Timer_LoadSettings(Handle timer)
{
	DB_LoadSettings();
}

char GetSettingValue(const char[] sSetting)
{
	char sValue[32];
	
	for(int i = 0; i < sizeof(g_sSettings); i++)
		if(StrEqual(g_sSettings[i][0], sSetting))
			Format(sValue, sizeof(sValue), g_sSettings[i][1]);
		
	return sValue;
}

char ProcessColorString(const char[] sString)
{
	char sOutput[256];
	strcopy(sOutput, sizeof(sOutput), sString)
	ReplaceString(sOutput, sizeof(sOutput), "{WHITE}", "\x01");
	ReplaceString(sOutput, sizeof(sOutput), "{RED}", "\x02");
	ReplaceString(sOutput, sizeof(sOutput), "{LIGHTPURPLE}", "\x03");
	ReplaceString(sOutput, sizeof(sOutput), "{GREEN}", "\x04");
	ReplaceString(sOutput, sizeof(sOutput), "{LIMON}", "\x05");
	ReplaceString(sOutput, sizeof(sOutput), "{LIGHTGREEN}", "\x06");
	ReplaceString(sOutput, sizeof(sOutput), "{LIGHTRED}", "\x07");
	ReplaceString(sOutput, sizeof(sOutput), "{GRAY}", "\x08");
	ReplaceString(sOutput, sizeof(sOutput), "{LIGHTGOLD}", "\x09");
	ReplaceString(sOutput, sizeof(sOutput), "{LIGHTBLUE}", "\x0B");
	ReplaceString(sOutput, sizeof(sOutput), "{BLUE}", "\x0C");
	ReplaceString(sOutput, sizeof(sOutput), "{PURPLE}", "\x0E");
	ReplaceString(sOutput, sizeof(sOutput), "{PINK}", "\x0F");
	ReplaceString(sOutput, sizeof(sOutput), "{GOLD}", "\x10");

	return sOutput;
}
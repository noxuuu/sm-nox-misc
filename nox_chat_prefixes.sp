#include <sourcemod>
#include <scp> // requires simple chat processor core.

public Plugin myinfo =
{
	name = "[NOX] ~~ Chat Prefix", 
	author = "n.o.x", 
	description = "Chat prefixes..", 
	version = "0.1"
};

public Action OnChatMessage(int &author, Handle recipients, char[] name, char[] message)
{
	if(IsValidClient(author))
	{
		int MaxMessageLength = MAXLENGTH_MESSAGE - strlen(name) - 5;
		if(CheckCommandAccess(author, "Admin_Root", ADMFLAG_ROOT, false))
		{
			Format(name, MaxMessageLength, " \x06Właściciel \x0C%s", name);
			Format(message, MaxMessageLength, "\x02%s", message);
		}
		else if(CheckCommandAccess(author, "Admin_Custom1", ADMFLAG_CUSTOM1, false))
		{
			Format(name, MaxMessageLength, " \x04 ✔ \x10VIP \x04✔ \x0C%s", name);
			Format(message, MaxMessageLength, "\x02%s", message);
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}
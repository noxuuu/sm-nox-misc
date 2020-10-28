#pragma semicolon 1

#include <sourcemod>
#include <regex>

#define LoopImpermisibleText(%1) for(int %1 = 1; %1 < sizeof ImpermisibleText; %1++)

char ImpermisibleText[][] =
{
	"huj",
	"hój",
	"kurwa",
	"kórwa",
	"pedał",
	"pierdole",
	"chuj",
	"dziwka",
	"jebac",
	"chuj wie",
	"debil",
	"idtiota",
	"jebany",
	"jak chuj",
	"chuje",
	"chujowo",
	"chujowa",
	"wkurwic",
	"kurwica",
	"pierdolisz",
	"spierdalaj",
	"pierdolony",
	"wypierdalaj",
	"pierdol sie",
	"wypierdolic",
	"wyjebac",
	"zajebac",
	"pizda",
	"twoja stara",
	"twoj stary",
	"rucham",
	"ruchalem",
	"cipka"
};

public Plugin myinfo = {
	name = "Chat Restrict",
	author = "n.o.x",
	description = "Blokuje wulgarne słowa na chat",
	version = "0.1",
	url = "http://cs-4frags.pl"
}

public OnPluginStart()
{
	AddCommandListener(Listeners_ChatListener, "say");
	AddCommandListener(Listeners_ChatListener, "say_team");
}

public Action Listeners_ChatListener(int client, char[] command, int argc)
{
	char text[256];
	GetCmdArg(1, text, sizeof(text));
	
	if(IsBadText(text))
	{
		PrintToChat(client, " \x02✖ \x07Na tym serwerze nie możesz używać wulgarnych słów !");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock bool IsBadText(const char[] text)
{
	LoopImpermisibleText(i)
	{
		Handle hRegex = CompileRegex(ImpermisibleText[i]);
		if(MatchRegex(hRegex, text))
		{
			return true;
		}
	}
	return false;
}
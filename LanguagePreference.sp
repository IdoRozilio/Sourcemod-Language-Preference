#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "xFlane"
#define PLUGIN_VERSION "1.00"

#define PREFIX "[SM]"
#define MENU_PREFIX "[SM]"

#define DEFAULT_LANGUAGE "en"
#define DEFAULT_LANGUAGE_FULLNAME "English"
#define DEFAULT_LANGUAGE_ID 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

enum languages_Enum {
	String:language_Name[MAX_NAME_LENGTH],
	String:language_Code[MAX_NAME_LENGTH]
};

new languages_Array[][languages_Enum] = {
	{ "English", "en" },
	{ "Polish", "pl" },
	{ "Russian", "ru" },
	{ "French", "fr" },
	{ "German", "de" }
};

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[SM] Language Preference",
	author = PLUGIN_AUTHOR,
	description = "Language Preference",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/xflane/"
};

Handle g_LanguageCookie;

char clientLanguage[MAXPLAYERS + 1][MAX_NAME_LENGTH];
char clientLanguageCode[MAXPLAYERS + 1][MAX_NAME_LENGTH];
int clientLanguageIndex[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("player_connect_full", Event_OnFullConnect);

	g_LanguageCookie = RegClientCookie("language_cookie", "Language cookie", CookieAccess_Private);
	
	RegConsoleCmd("sm_language", command_Language, "Commmand to change your language on this server");
	RegConsoleCmd("sm_lang", command_Language, "Commmand to change your language on this server");
}

/* Commands */

public Action command_Language(int client,int args)
{
	if(args > 0)
	{
		char language[MAX_NAME_LENGTH];
		GetCmdArg(1, language, MAX_NAME_LENGTH);
		
		int languageId = GetLanguageByCode(language);
		
		if(languageId == -1)
		{
			PrintToChat(client, "%s Langauge was not found, are you sure this is language code?", PREFIX);
			return Plugin_Handled;
		}
		
		GetLanguageInfo(languageId, .name = clientLanguage[client], .nameLen=MAX_NAME_LENGTH);
		clientLanguage[client][0] = CharToUpper(clientLanguage[client][0]);
		PrintToChat(client, "%s Your language has been changed to \x04%s.", PREFIX, clientLanguage[client]);
		
		SetClientCookie(client, g_LanguageCookie, language);
		SetClientLanguage(client, languageId);
		clientLanguageCode[client] = language;
		
		for (int i = 0; i < sizeof(languages_Array);i++) // Finding client language index in the array for later.
			if(StrEqual(clientLanguageCode[client], languages_Array[i][language_Code]))
				clientLanguageIndex[client] = i;
				
		return Plugin_Handled;
	}
	
	Menu languages = new Menu(language_Callback);
	languages.SetTitle("%s Languages Menu\nCurrent Language: %s\n ", MENU_PREFIX, clientLanguage[client]);
	
	for (int i = 0; i < sizeof(languages_Array);i++)
	{
		languages.AddItem(languages_Array[i][language_Code], languages_Array[i][language_Name], clientLanguageIndex[client] == i ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	}
	
	languages.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

/* */

/* Callbacks */

public int language_Callback(Menu menu, MenuAction action, int client, int key)
{
	if(action == MenuAction_Select)
	{
		char language[MAX_NAME_LENGTH];
		strcopy(language, MAX_NAME_LENGTH, languages_Array[key][language_Code]);
		
		int languageId = GetLanguageByCode(language);
		
		if(languageId == -1)
		{
			PrintToChat(client, "%s Langauge was not found, are you sure this is language code?", PREFIX);
			return;
		}
		
		GetLanguageInfo(languageId, .name = clientLanguage[client], .nameLen=MAX_NAME_LENGTH);
		clientLanguage[client][0] = CharToUpper(clientLanguage[client][0]);
		
		PrintToChat(client, "%s Your language has been changed to \x04%s.", PREFIX, clientLanguage[client]);
		
		SetClientCookie(client, g_LanguageCookie, language);
		SetClientLanguage(client, languageId);
		clientLanguageCode[client] = language;
		
		for (int i = 0; i < sizeof(languages_Array);i++) // Finding client language index in the array for later.
			if(StrEqual(clientLanguageCode[client], languages_Array[i][language_Code]))
				clientLanguageIndex[client] = i;
	}
	else if(action == MenuAction_End)
		delete menu;
		
	return;
}

/* */


public void OnClientCookiesCached(int client)
{
	clientLanguageIndex[client] = 0;
	
	GetClientCookie(client, g_LanguageCookie, clientLanguageCode[client], MAX_NAME_LENGTH);
	int languageId = GetLanguageByCode(clientLanguageCode[client]);
	
	if(languageId == -1)
	{
		SetClientCookie(client, g_LanguageCookie, DEFAULT_LANGUAGE);
		clientLanguageIndex[client] = DEFAULT_LANGUAGE_ID;
		clientLanguageCode[client] = DEFAULT_LANGUAGE;
		clientLanguage[client] = DEFAULT_LANGUAGE_FULLNAME;
		return;
	}
	
	GetLanguageInfo(languageId, .name = clientLanguage[client], .nameLen=MAX_NAME_LENGTH);
	clientLanguage[client][0] = CharToUpper(clientLanguage[client][0]);
	
	for (int i = 0; i < sizeof(languages_Array);i++) // Finding client language index in the array for later.
		if(StrEqual(clientLanguageCode[client], languages_Array[i][language_Code]))
			clientLanguageIndex[client] = i;
}

public Action Event_OnFullConnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int languageId = GetLanguageByCode(clientLanguageCode[client]);
	
	if(languageId == -1)
	{
		return;
	}
	
	SetClientLanguage(client, languageId);
}

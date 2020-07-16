#if defined _hlze_stocks_included
    #endinput
#endif
#define _hlze_stocks_included

#include <amxmisc>
#include <hlstocks>
#include <engine>
#include <fakemeta>
#include <fun>

#define IsPlayer(%0) (%0 > 0 && %0 <= MaxClients)

// --------------- Freeze stuff --------------------

stock FreezeAllPlayers(freeze = true) {
    new players[MAX_PLAYERS], numPlayers;
    get_players_ex(players, numPlayers, GetPlayers_ExcludeHLTV);

    new plr;
    for (new i; i < numPlayers; i++) {
        plr = players[i];
        FreezePlayer(plr, freeze);
    }

}

stock FreezePlayer(id, freeze = true, Float:time = 30.0) {
    if (freeze) {
        set_pev(id, pev_fuser4, get_user_maxspeed(id));
        set_user_maxspeed(id, 1.0);
        BlockPlayerWeapons(id, time);
        set_user_godmode(id, true);
    } else {
        set_user_maxspeed(id, entity_get_float(id, EV_FL_fuser4));
        BlockPlayerWeapons(id, 0.0);
        set_user_godmode(id, false);
    }
}

stock BlockPlayerWeapons(id, Float:time) {
    new weapon;
    for (new i = 1; i < HL_MAX_WEAPON_SLOTS; i++) {
        weapon = get_ent_data_entity(id, "CBasePlayer", "m_rgpPlayerItems", i);
        while (weapon != FM_NULLENT) {
            set_ent_data_float(weapon, "CBasePlayerWeapon", "m_flNextPrimaryAttack", time);
            set_ent_data_float(weapon, "CBasePlayerWeapon", "m_flNextSecondaryAttack", time);
            weapon = get_ent_data_entity(weapon, "CBasePlayerItem", "m_pNext");
        }
    }
}

// ---------------------- Count players -------------------------------

stock hl_get_teamnum(teamid) {
    new players[MAX_PLAYERS], numPlayers;
    get_players_ex(players, numPlayers, GetPlayers_ExcludeHLTV);

    new numTeam;

    new plr;
    for (new i; i < numPlayers; i++) {
        plr = players[i];
        if (hl_get_user_team(plr) == teamid)
            numTeam++;
    }

    return numTeam;
}

// get real players count ignoring HLTV
stock hl_get_playersnum() {
    new players[32], numPlayers;
    get_players_ex(players, numPlayers, GetPlayers_ExcludeHLTV);
    return numPlayers;
}

stock hl_get_team_numalive(teamid) {
    new players[MAX_PLAYERS], numPlayers;

    hl_get_team_alive(teamid, players, numPlayers);

    return numPlayers;
}

stock hl_get_team_alive(teamid, players[MAX_PLAYERS], &num) {
    new local_players[MAX_PLAYERS], numPlayers;
    get_players_ex(local_players, numPlayers, GetPlayers_ExcludeHLTV | GetPlayers_ExcludeDead);

    new plr;
    for (new i; i < numPlayers; i++) {
        plr = local_players[i];
        if (hl_get_user_team(plr) == teamid)
            players[num++] = plr;
    }
}

/* Set player team by passing teamid instead of teamname.
*/
stock hl_set_user_team_ex(id, teamid) {
    static entTeamMaster, entPlayerTeam;

    if (!entTeamMaster) {
        entTeamMaster = create_entity("game_team_master");
        set_pev(entTeamMaster, pev_targetname, "changeteam");
    }

    if (!entPlayerTeam) {
        entPlayerTeam = create_entity("game_player_team");
        DispatchKeyValue(entPlayerTeam, "target", "changeteam");
    }

    DispatchKeyValue(entTeamMaster, "teamindex", fmt("%i", teamid - 1));

    ExecuteHamB(Ham_Use, entPlayerTeam, id, 0, USE_ON, 0.0);

    static TeamInfo;
    if (hl_get_user_spectator(id)) {
        if (TeamInfo || (TeamInfo = get_user_msgid("TeamInfo")))
        {
            message_begin(MSG_ALL, TeamInfo);
            write_byte(id);
            write_string("");
            message_end();
        }
    }
}

// ---------------------------- Useful stocks ---------------------------------

stock PrecacheTeamList() {
    new teamlist[192], teamnames[HL_MAX_TEAMS][HL_TEAMNAME_LENGTH];
    get_cvar_string("mp_teamlist", teamlist, charsmax(teamlist));

    new nIdx, nLen = (1 + copyc(teamnames[nIdx], charsmax(teamnames[]), teamlist, ';'));

    while (nLen < strlen(teamlist) && ++nIdx < HL_MAX_TEAMS)
        nLen += (1 + copyc(teamnames[nIdx], charsmax(teamnames[]), teamlist[nLen], ';'));

    new file[128];
    for (new i; i < HL_MAX_TEAMS; i++) {
        formatex(file, charsmax(file), "models/player/%s/%s.mdl", teamnames[i], teamnames[i]);
        if (file_exists(file))
            engfunc(EngFunc_PrecacheModel, file);
    }
}

stock RemoveExtension(const input[], output[], length, const ext[]) {
    copy(output, length, input);

    new idx = strlen(input) - strlen(ext);
    if (idx < 0) return 0;

    return replace(output[idx], length, ext, "");
}

stock PlaySound(id, const sound[]) {
    new snd[128];
    RemoveExtension(sound, snd, charsmax(snd), ".wav"); // remove wav extension to avoid "missing sound file _period.wav"
    client_cmd(id, "spk ^"%s^"", snd);
}

stock SpeakSnd(id, const speak[]) {
    new spk[128];
    RemoveExtension(speak, spk, charsmax(spk), ".wav"); // remove wav extension to avoid "missing sound file _period.wav"
    client_cmd(id, "speak ^"%s^"", spk);
}

stock PlayMp3(id, const file[]) {
    if (!strlen(file)) {
        client_cmd(id, "mp3 stop");
        return;
    }
    client_cmd(id, "mp3 loop %s", file);
}

stock PrecacheSoundList(const input[][], size) {
    for (new i; i < size; i++)
        precache_sound(input[i]);
}

stock RegisterHamList(Ham:function, const EntityClassList[][], size, const Callback[], Post = 0, bool:specialBot = false) {
    for (new i; i < size; i++)
        RegisterHam(function, EntityClassList[i], Callback, Post, specialBot);
}

// the parsed string is in this format "x y z" e.g "128 0 256"
stock StrToVec(const string[], Float:vector[3]) {
    new arg[3][12]; // hold parsed vector
    parse(string, arg[0], charsmax(arg[]), arg[1], charsmax(arg[]), arg[2], charsmax(arg[]));

    for (new i; i < sizeof arg; i++)
        vector[i] = str_to_float(arg[i]);
}

// ---------------------------- Reset Map Stuff ---------------------------------

stock ResetMap() {
    ClearField();
    ClearCorpses();
    RespawnItems();
    hl_restore_all();
}

// clear entities created by the player like tripmines, satchels, etc...
stock ClearField() {
    static const fieldEnts[][] = { "bolt", "monster_snark", "monster_satchel", "monster_tripmine", "beam" };

    for (new i; i < sizeof fieldEnts; i++)
        remove_entity_name(fieldEnts[i]);

    static ent;

    ent = 0;
    while ((ent = find_ent_by_class(ent, "rpg_rocket")))
        set_pev(ent, pev_dmg, 0);

    ent = 0;
    while ((ent = find_ent_by_class(ent, "grenade")))
        set_pev(ent, pev_dmg, 0);
    
    ent = 0;
    while ((ent = find_ent_by_class(ent, "weaponbox")))
        hl_remove_wbox(ent);
}

stock ClearCorpses() {
    new ent;
    while ((ent = find_ent_by_class(ent, "bodyque")))
        set_pev(ent, pev_effects, EF_NODRAW);
}

// This will respawn all weapons, ammo and items of the map to prepare for a new round
stock RespawnItems() {
    new classname[32];
    for (new i; i < global_get(glb_maxEntities); i++) {
        if (pev_valid(i)) {
            pev(i, pev_classname, classname, charsmax(classname));
            if (!contain(classname, "weapon_") || !contain(classname, "ammo_") || !contain(classname, "item_")) {
                set_pev(i, pev_nextthink, get_gametime());
            }
        }
    }
}

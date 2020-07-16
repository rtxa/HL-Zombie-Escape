#include <amxmisc>
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <hlstocks>
#include <msgstocks>
#include <restore_map>
#include <hlze_const>
#include <hlze_stocks>

#define PLUGIN "HL:ZE - BSP Compat"
#define VERSION "0.1"
#define AUTHOR "rtxA"

#pragma semicolon 1

// Armoury Entity List
enum _:ArmouryIDs{
    ARM_MP5,
    ARM_TMP,
    ARM_P90,
    ARM_MAC10,
    ARM_AK47,
    ARM_SG552,
    ARM_M4A1,
    ARM_AUG,
    ARM_SCOUT,
    ARM_G3SG1,
    ARM_AWP,
    ARM_M3,
    ARM_XM1014,
    ARM_M249,
    ARM_FLASHBANG,
    ARM_HEGRENADE,
    ARM_KEVLAR,
    ARM_ASSAULTSUIT,
    ARM_SMOKEGRENADE
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    CreateGameTeamMaster("team1", TEAM_HUMAN);
    CreateGameTeamMaster("team2", TEAM_ZOMBIE);
    RemoveNoTeamSpawns();
}

/* Get item and origin of armoury_entity to sustitute it with his counterpart on Half-Life.
 */
public pfn_keyvalue(entid) {
    new classname[32], key[32], value[64];
    copy_keyvalue(classname, sizeof classname, key, sizeof key, value, sizeof value);

    static Float:vector[3];
    StrToVec(value, vector);

    static spawn;
    if (equal(classname, "info_player_start")) { // Human team
        if (equal(key, "origin")) {
            spawn = create_entity("info_player_deathmatch");
            entity_set_origin(spawn, vector);
            set_pev(spawn, pev_netname, "team1");
        } else if (equal(key, "angles")) {
            set_pev(spawn, pev_angles, vector);
        }
    } else if (equal(classname, "info_player_deathmatch")) { // Zombie Team
        if (equal(key, "origin")) {
            remove_entity(entid);
            spawn = create_entity("info_player_deathmatch");
            entity_set_origin(spawn, vector);
            set_pev(spawn, pev_netname, "team2");
        } else if (equal(key, "angles")) {
            set_pev(spawn, pev_angles, vector);
        }
    }

    if (equal(classname, "armoury_entity")) {
        static Float:origin[3];
        if (equal(key, "origin")) {
            StrToVec(value, origin);
        } else if (equal(key, "item"))
            SustiteArmouryEnt(origin, str_to_num(value));
    }
}

// ------------------- useful stocks -------------------------------------


stock CreateGameTeamMaster(name[], teamid) {
    new ent = create_entity("game_team_master");
    set_pev(ent, pev_targetname, name);
    DispatchKeyValue(ent, "teamindex", fmt("%i", teamid - 1));
    return ent;
}

// remove deathmatch spawns so the team spawns can work correctly
stock RemoveNoTeamSpawns() {
    new ent, master[32];
    while ((ent = find_ent_by_class(ent, "info_player_deathmatch"))) {
        pev(ent, pev_netname, master, charsmax(master));
        if (!equal(master, "team1") && !equal(master, "team2")) {
            remove_entity(ent);
        } 
    }
}

stock SustiteArmouryEnt(Float:origin[3], item){
    new classname[32];

    switch(item) {
        case ARM_TMP, ARM_P90, ARM_MAC10, ARM_MP5: classname = "weapon_357";
        case ARM_M3, ARM_XM1014: classname = "weapon_shotgun";
        case ARM_M4A1, ARM_AK47, ARM_AUG: classname = "weapon_9mmAR";
        case ARM_AWP, ARM_SCOUT, ARM_SG552, ARM_G3SG1: classname = "weapon_crossbow";
        case ARM_M249: classname = "weapon_rpg";
        case ARM_SMOKEGRENADE: classname = "weapon_hornetgun";
        case ARM_FLASHBANG: classname = "weapon_hornetgun";
        case ARM_HEGRENADE: classname = "weapon_satchel";
        case ARM_KEVLAR, ARM_ASSAULTSUIT: classname = "item_battery";
        default: {
            server_print("WARNING: Item %i doesn't exist!", item);
            return;
        }
    }

    new ent = create_entity(classname);
    entity_set_origin(ent, origin);
    DispatchSpawn(ent);
}

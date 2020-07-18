#include <amxmisc>
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <hlstocks>
#include <msgstocks>
#include <restore_map>
#include <hlze_stocks>
#include <hlze_const>

#define PLUGIN "HL Zombie Escape"
#define VERSION "0.1"
#define AUTHOR "rtxA"

#pragma semicolon 1

// TaskIDs
enum (+= 100) {
    TASK_FIRSTZOMBIE = 1999,
    TASK_ROUNDSTART,
    TASK_ROUNDEND,
    TASK_RELEASEZOMBIE,
    TASK_PLAYERSTATUS,
    TASK_SENDTOSPEC,
    TASK_DISPLAYTIMER,
    TASK_PUTINSERVER
};

new const WEAPONS_CLASSES[][] = {
    "weapon_357",
    "weapon_9mmAR",
    "weapon_9mmhandgun",
    "weapon_crossbow",
    "weapon_egon",
    "weapon_gauss",
    "weapon_handgrenade",
    "weapon_hornetgun",
    "weapon_rpg",
    "weapon_satchel",
    "weapon_shotgun",
    "weapon_snark",
    "weapon_tripmine",
};

new const ITEM_CLASSES[][] = {
    "item_longjump",
    "item_suit",
    "item_battery",
    "item_healthkit",
    "weaponbox"
};

new const FUNC_CLASSES[][] = {
    "func_recharge",
    "func_healthcharger",
    "func_tank",
    "func_tankcontrols",
    "func_tanklaser",
    "func_tankmortar",
    "func_tankrocket",
};

// ---------------------------- Sounds ---------------------------------

// round ambience music
new const MP3_AMBIENCE[] = "sound/hlze/ze_ambience.mp3";
new const MP3_READY[] = "sound/hlze/ze_ready.mp3";

// round sounds
new const SND_ESCAPE_SUCCESS[] = "hlze/zombi_escape_success.wav";
new const SND_ESCAPE_FAIL[] = "hlze/zombi_escape_fail.wav";

new const SND_BELL[] = "hlze/bell.wav";

new const SND_COUNT[][] = {
    "common/null.wav",
    "hlze/vox/one.wav",
    "hlze/vox/two.wav",
    "hlze/vox/three.wav",
    "hlze/vox/four.wav",
    "hlze/vox/five.wav",
    "hlze/vox/six.wav",
    "hlze/vox/seven.wav",
    "hlze/vox/eight.wav",
    "hlze/vox/nine.wav",
    "hlze/vox/ten.wav"
};

// human sounds
new const SND_HUMAN_DEATH[][] = { "hlze/human_death_01.wav", "hlze/human_death_02.wav" };

// zombie sounds
new const SND_ZMB_COMING[][] = { "hlze/zombi_coming_1.wav", "hlze/zombi_coming_2.wav" };
new const SND_ZMB_DEATH[][] = { "hlze/zombi_death_01.wav", "hlze/zombi_death_02.wav" };
new const SND_ZMB_HURT[][] = { "hlze/zombi_hurt_01.wav", "hlze/zombi_hurt_02.wav" };

// ------------------------- Class atributtes --------------------------------

#define HUMAN_MAXSPEED 230.0
#define HUMAN_HEALTH 100
#define HUMAN_ARMOUR 0
#define HUMAN_KILL_FRAGS 1

#define ZOMBIE_MAXSPEED 300.0
#define ZOMBIE_HEALTH 5000
#define ZOMBIE_ARMOUR 0
#define ZOMBIE_GRAVITY 0.8
#define ZOMBIE_INFECTION_FRAGS 1

// ------------------------ Vars ---------------------------------------------

new g_TeamScore[HL_MAX_TEAMS];

new g_RoundStarted;
new g_RoundWinner;
new g_RoundTime;
new g_DisableDeathPenalty;

new g_FirstZombieTime;
new g_ReleaseZombieTime;

// effects
new g_SprLgtning;
new g_SprLaserDot;

// hud handlers
new g_ScoreHudSync;

// cvars
new g_pCvarReleaseTime;
new g_pCvarFreezeTime;
new g_pCvarRoundTime;
new g_pCvarRoundEndDelay;
new g_pCvarMinPlayers;

new g_pCvarZombieHealth;
new g_pCvarZombieGravity;
new g_pCvarZombieMaxSpeed;
new g_pCvarZombieInfectFrags;

new g_pCvarHumanHealth;
new g_pCvarHumanArmour;
new g_pCvarHumanMaxSpeed;
new g_pCvarHumanKillFrags;

public plugin_precache() {
    // precache models from mp_teamlist
    PrecacheTeamList();

    // round ambience music
    precache_generic(MP3_AMBIENCE);
    precache_generic(MP3_READY);

    // round sounds
    precache_sound(SND_ESCAPE_SUCCESS);
    precache_sound(SND_ESCAPE_FAIL);
    PrecacheSoundList(SND_COUNT, sizeof SND_COUNT);

    // human sounds
    PrecacheSoundList(SND_HUMAN_DEATH, sizeof SND_HUMAN_DEATH);

    // zombie sounds
    PrecacheSoundList(SND_ZMB_COMING, sizeof SND_ZMB_COMING);
    PrecacheSoundList(SND_ZMB_HURT, sizeof SND_ZMB_HURT);
    PrecacheSoundList(SND_ZMB_DEATH, sizeof SND_ZMB_DEATH);

    precache_sound(SND_BELL);

    g_SprLaserDot = precache_model("sprites/laserdot.spr");
    g_SprLgtning = precache_model("sprites/lgtning.spr");

    // zombie escape version
    create_cvar("ze_version", VERSION, FCVAR_SERVER);

    // general cvars
    g_pCvarReleaseTime = create_cvar("ze_release_time", "10");
    g_pCvarFreezeTime = create_cvar("ze_freeze_time", "5");
    g_pCvarRoundTime = create_cvar("ze_round_time", "300");
    g_pCvarRoundEndDelay = create_cvar("ze_round_end_delay", "5.0");
    g_pCvarMinPlayers = create_cvar("ze_minplayers", "2");

    // zombie cvars
    g_pCvarZombieGravity = create_cvar("ze_zombie_gravity", "0.8");
    g_pCvarZombieMaxSpeed = create_cvar("ze_zombie_maxspeed", "300.0");
    g_pCvarZombieHealth = create_cvar("ze_zombie_health", "5000");
    g_pCvarZombieInfectFrags = create_cvar("ze_zombie_infect_frags", "1");

    // human cvars
    g_pCvarHumanHealth = create_cvar("ze_human_health", "100");
    g_pCvarHumanArmour = create_cvar("ze_human_armour", "0");
    g_pCvarHumanMaxSpeed = create_cvar("ze_human_maxspeed", "300.0");
    g_pCvarHumanKillFrags = create_cvar("ze_human_kill_frags", "3");
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_forward(FM_GetGameDescription, "OnGetGameDescription");

    register_dictionary("hlze.txt");

    // block spectate and kill cmds
    register_clcmd("spectate", "OnCmdSpectate");
    register_forward(FM_ClientKill, "OnClientKill");

    register_concmd("sv_restart", "OnCmdRestartGame", ADMIN_KICK);
    register_concmd("sv_restartround", "OnCmdRestartRound", ADMIN_KICK);

    // block zombies picking or using these objects
    RegisterHamList(Ham_Touch, WEAPONS_CLASSES, sizeof WEAPONS_CLASSES, "OnItemTouch");
    RegisterHamList(Ham_Touch, ITEM_CLASSES, sizeof ITEM_CLASSES, "OnItemTouch");
    RegisterHamList(Ham_Use, FUNC_CLASSES, sizeof FUNC_CLASSES, "OnFuncTouch");

    RegisterHamPlayer(Ham_TakeDamage, "OnPlayerTakeDamage");
    RegisterHamPlayer(Ham_Killed, "OnPlayerKilled_Post", true);
    RegisterHamPlayer(Ham_Spawn, "OnPlayerSpawn");

    g_ScoreHudSync = CreateHudSyncObj();

    RoundStart();
}

// game mode name displayed in server browser
public OnGetGameDescription() {
    forward_return(FMV_STRING, PLUGIN + " " + VERSION);
    return FMRES_SUPERCEDE;
}

// ---------------------- Client connect ---------------------------

public TaskPutInServer(taskid) {
    new id = taskid - TASK_PUTINSERVER;

    if (!is_user_connected(id))
        return;

    UpdateTeamNames(id);

    UpdateTeamScore(id);

    hl_set_user_spectator(id);

    // increase display time for center messages (default is too low, player can barely see them)
    client_cmd(id, "scr_centertime 3");
}

public client_putinserver(id) {
    set_task(0.1, "TaskPutInServer", TASK_PUTINSERVER + id);
}

public client_remove(id) {
    CheckGameStatus();
}

// ----------------------- Player stuff ----------------------------

public OnPlayerSpawn(id) {
    // if player has to spec, don't let him spawn...
    if (task_exists(TASK_SENDTOSPEC + id))
        return HAM_SUPERCEDE;
    return HAM_IGNORED;
}

public OnPlayerTakeDamage(victim, inflictor, attacker, Float:damage, damagetype) {
    new victimTeam = hl_get_user_team(victim);
    new attackerTeam = IsPlayer(attacker) ? hl_get_user_team(attacker) : 0;

    // human attacks zombie
    if (victimTeam == TEAM_ZOMBIE && attackerTeam == TEAM_HUMAN) {
        if (is_user_alive(victim))
            emit_sound(victim, CHAN_BODY, SND_ZMB_HURT[random(sizeof SND_ZMB_HURT)], VOL_NORM, ATTN_NORM, 0, random_num(95, 105));
    // zombie attacks human
    } else if (attackerTeam == TEAM_ZOMBIE && victimTeam == TEAM_HUMAN) {
        // if damage isn't from his claws, block it
        if (!IsPlayer(inflictor))
            return HAM_SUPERCEDE;

        make_deathmsg(attacker, victim, 0, "virus");

        // give points for infection and add death to victim
        hl_set_user_frags(attacker, get_user_frags(attacker) + get_pcvar_num(g_pCvarZombieInfectFrags));
        hl_set_user_deaths(victim, hl_get_user_deaths(victim) + 1);
        
        SetZombie(victim);

        CheckGameStatus();

        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}

public OnPlayerKilled_Post(victim, attacker) {
    new victimTeam = hl_get_user_team(victim);
    new attackerTeam = IsPlayer(attacker) ? hl_get_user_team(attacker) : 0;

    if (g_DisableDeathPenalty) {
        hl_set_user_deaths(victim, hl_get_user_deaths(victim) - 1);
        if (IsPlayer(attacker)) {
            if (victimTeam != attackerTeam && victim != attacker)
                hl_set_user_frags(attacker, hl_get_user_frags(attacker) - 1);
            else
                hl_set_user_frags(attacker, hl_get_user_frags(attacker) + 1);
        }
    }

    // give points to attacker by team
    if (victim != attacker && IsPlayer(attacker)) {
        if (hl_get_user_team(victim) == TEAM_ZOMBIE && hl_get_user_team(attacker) == TEAM_HUMAN) {
            PlaySound(0, SND_ZMB_DEATH[random(sizeof SND_ZMB_DEATH)]);
            hl_set_user_frags(attacker,  get_user_frags(attacker) + (get_pcvar_num(g_pCvarHumanKillFrags) - 1));
        }
    }

    // send victim to spec
    set_task(3.0, "SendToSpec", victim + TASK_SENDTOSPEC);

    CheckGameStatus();

    return HAM_IGNORED;
}

// ------------------------ Zombie Touch Stuff ----------------------

public OnItemTouch(touched, toucher) {
    if (IsPlayer(toucher)) {
        if (hl_get_user_team(toucher) == TEAM_ZOMBIE)
            return HAM_SUPERCEDE;
    }
    return HAM_IGNORED;
}

public OnFuncTouch(touched, toucher) {
    if (IsPlayer(toucher)) {
        if (hl_get_user_team(toucher) == TEAM_ZOMBIE)
            return HAM_SUPERCEDE;
    }
    return HAM_IGNORED;
}

// ------------------------ Round Stuff -----------------------------

public RoundStart() {
    if (g_RoundStarted)
        return;

    remove_task(TASK_FIRSTZOMBIE);
    remove_task(TASK_RELEASEZOMBIE);

    g_DisableDeathPenalty = false;

    new players[MAX_PLAYERS], numPlayers;
    get_players_ex(players, numPlayers, GetPlayers_ExcludeHLTV);

    if (numPlayers < 1) {
        set_task(1.0, "RoundStart", TASK_ROUNDSTART);
        return;
    }

    new plr;

    // not enough players to start a round, let them play around
    if (numPlayers < get_pcvar_num(g_pCvarMinPlayers)) {
        for (new i; i < numPlayers; i++) {
            plr = players[i];

            if (hl_get_user_spectator(plr))
                hl_set_user_spectator(plr, false);

            if (hl_get_user_team(plr) != TEAM_HUMAN)
                SetHuman(plr);

        }
        client_print(0, print_center, "%l", "ROUND_MINPLAYERS", get_pcvar_num(g_pCvarMinPlayers));
        set_task(5.0, "RoundStart", TASK_ROUNDSTART);
        return;
    }

    // we have enough players, start a new round
    for (new i; i < numPlayers; i++) {
        plr = players[i];

        if (hl_get_user_team(plr) != TEAM_HUMAN)
            hl_set_user_team_ex(plr, TEAM_HUMAN);

        if (hl_get_user_spectator(plr))
            hl_set_user_spectator(plr, false);
        else
            hl_user_spawn(plr);

        SetHuman(plr);

        FreezePlayer(plr, true);
    }

    g_RoundStarted = true;

    g_RoundTime = get_pcvar_num(g_pCvarRoundTime); // 5 minutes
    StartRoundTimer();

    // restore all map stuff
    ResetMap();
    
    PlayMp3(0, MP3_READY);
    g_FirstZombieTime = get_pcvar_num(g_pCvarFreezeTime);
    FirstZombieCountDown();
}

public FirstZombieCountDown() {
    static ran;
    if (g_FirstZombieTime <= 0) {
        FreezeAllPlayers(false);

        new min = GetMinZombies();
        for (new i; i < min; i++) {
            ran = RandomZombie();
            SetZombie(ran);
            make_deathmsg(0, ran, 0, "teammate"); // show a green skull
            FreezePlayer(ran, true);
        }

        client_print(0, print_center, "");

        g_ReleaseZombieTime = get_pcvar_num(g_pCvarReleaseTime);
        set_task(1.0, "ReleaseZombieCountDown", TASK_RELEASEZOMBIE);
        return;
    }

    PlaySound(0, "buttons/blip1.wav");
    client_print(0, print_center, "%l", "FIRST_ZMB_COUNTDOWN", g_FirstZombieTime);

    g_FirstZombieTime--;
    set_task(1.0, "FirstZombieCountDown", TASK_FIRSTZOMBIE);
}

public ReleaseZombieCountDown() {
    if (g_ReleaseZombieTime <= 0) {
        FreezeAllPlayers(false);
        client_print(0, print_center, "");
        PlayMp3(0, MP3_AMBIENCE);
        PlaySound(0, SND_BELL);
        return;
    }

    if (g_ReleaseZombieTime > 0 && g_ReleaseZombieTime <= 10) {
        PlaySound(0, SND_COUNT[g_ReleaseZombieTime]);
        client_print(0, print_center, "%l", "RELEASE_COUNTDOWN", g_ReleaseZombieTime);
    }

    g_ReleaseZombieTime--;
    set_task(1.0, "ReleaseZombieCountDown", TASK_RELEASEZOMBIE);
}

public RoundEnd() {
    if (!g_RoundStarted)
        return;

    remove_task(TASK_FIRSTZOMBIE);
    remove_task(TASK_RELEASEZOMBIE);

    g_RoundStarted = false;

    PlayMp3(0, "");

    // show team winner
    switch (g_RoundWinner) {
        case TEAM_HUMAN: {
            PlaySound(0, SND_ESCAPE_SUCCESS);
            AddPointsToScore(g_RoundWinner, 1);
            client_print(0, print_center, "%l", "ESCAPE_SUCCESS");
        }
        case TEAM_ZOMBIE: {
            PlaySound(0, SND_ESCAPE_FAIL);
            AddPointsToScore(g_RoundWinner, 1);
            client_print(0, print_center, "%l", "ESCAPE_FAIL");
        }
        case TEAM_NONE: {
            client_print(0, print_center, "%l", "ROUND_DRAW");
            PlaySound(0, SND_ESCAPE_FAIL);
        } 
    }

    UpdateTeamScore();

    set_task(get_pcvar_float(g_pCvarRoundEndDelay), "RoundStart", TASK_ROUNDSTART);
}

public RoundRestart() {
    remove_task(TASK_FIRSTZOMBIE);
    remove_task(TASK_RELEASEZOMBIE);

    g_RoundStarted = false;

    RoundStart();
}

bool:RoundNeedsToContinue() {
    new humans = hl_get_team_numalive(TEAM_HUMAN);
    new zombies = hl_get_team_numalive(TEAM_ZOMBIE);

    if (humans > 0 && zombies > 0)
        return true;

    // the score of this round is ignored
    if (g_DisableDeathPenalty) {
        g_RoundWinner = TEAM_NONE;
        return false;
    }

    // humans win
    if (humans > zombies) {
        g_RoundWinner = TEAM_HUMAN;
    // zombies win
    } else if (zombies > humans) {
        g_RoundWinner = TEAM_ZOMBIE;
    // draw
    } else {
        g_RoundWinner = TEAM_NONE;
    }

    return false;
}

public CheckGameStatus() {
    if (!g_RoundStarted || task_exists(TASK_ROUNDEND))
        return;

    if (!RoundNeedsToContinue())
        RoundEnd();
}

// --------------------- Selection of zombies ---------------------

RandomZombie() {
    new players[MAX_PLAYERS], numPlayers;
    hl_get_team_alive(TEAM_HUMAN, players, numPlayers);

    return RandomPlayer(players, numPlayers);
}

// select random player from a list of players
RandomPlayer(players[], numplayers) {
    static oldRandom;

    new rnd = oldRandom;
    
    if (numplayers > 1)
        oldRandom = players[random(numplayers)];
        
    // avoid same player of last round
    while (rnd == oldRandom)
        oldRandom = players[random(numplayers)];

    return oldRandom;
}

GetMinZombies() {
    switch (hl_get_team_numalive(TEAM_HUMAN)) {
        case 2..5: return 1;
        case 6..15: return 2;
        case 16..25: return 3;
        case 26..32: return 4;
    }
    return 0;
}

// -------------------------- Class stuff ----------------------------

SetHuman(id) {
    if (hl_get_user_team(id) != TEAM_HUMAN)
        hl_set_user_team_ex(id, TEAM_HUMAN);

    hl_strip_user_weapons(id);
    give_item(id, "weapon_crowbar");
    give_item(id, "weapon_357");
    give_item(id, "weapon_9mmAR");
    give_item(id, "weapon_shotgun");
    give_item(id, "weapon_crossbow");
    give_item(id, "ammo_ARgrenades");

    // avoid WeapPickUp messages
    set_ent_data(id, "CBasePlayer", "m_fInitHUD", 1);

    set_user_health(id, get_pcvar_num(g_pCvarHumanHealth));
    set_user_armor(id, get_pcvar_num(g_pCvarHumanArmour));
    set_user_maxspeed(id, get_pcvar_float(g_pCvarHumanMaxSpeed));
}

SetZombie(id) {
    if (hl_get_user_team(id) != TEAM_ZOMBIE)
        hl_set_user_team_ex(id, TEAM_ZOMBIE);

    hl_strip_user_weapons(id);
    give_item(id, "weapon_crowbar");
    
    set_user_health(id, get_pcvar_num(g_pCvarZombieHealth));
    set_user_gravity(id, get_pcvar_float(g_pCvarZombieGravity));
    set_user_maxspeed(id, get_pcvar_float(g_pCvarZombieMaxSpeed));

    // avoid WeapPickUp messages
    set_ent_data(id, "CBasePlayer", "m_fInitHUD", 1);

    if (!is_user_bot(id)) // bots need this info for select weapons
        set_pev(id, pev_weapons, 1 << HLW_SUIT); // hack: hide weapon from weapon slots making think player has no weapons

    // effects
    fade_user_screen(id, 0.5, 2.0, ScreenFade_FadeIn, 255, 90, 90, 120);
    shake_user_screen(id, 16.0, 4.0, 16.0);
    LightningEffect(id);

    // alert everyone of new zombie
    PlaySound(0, SND_ZMB_COMING[random(sizeof SND_ZMB_COMING)]);

    // become zombie sound
    emit_sound(id, CHAN_AUTO, SND_HUMAN_DEATH[random(sizeof SND_HUMAN_DEATH)], VOL_NORM, 0.5, 0, random_num(95, 105));
}

// ----------------------------- team score stuff -------------------------
stock GetTeamScore(team) {
    return g_TeamScore[team - 1];
}

public AddPointsToScore(team, value) {
    g_TeamScore[team - 1] += value;
}

// not functional until i find how to fix team score switching on change team
stock UpdateTeamScore(id = 0) {
    return id;
    //hl_set_user_teamscore(id, GetTeamName(TEAM_HUMAN), GetTeamScore(TEAM_HUMAN));
    //hl_set_user_teamscore(id, GetTeamName(TEAM_ZOMBIE), GetTeamScore(TEAM_ZOMBIE));
}

stock UpdateTeamNames(id = 0) {
    new blue[HL_MAX_TEAMNAME_LENGTH];
    new red[HL_MAX_TEAMNAME_LENGTH];

    // Get translated team name
    SetGlobalTransTarget(id);
    formatex(blue, charsmax(blue), "%l", "TEAMNAME_HUMAN");
    formatex(red, charsmax(red), "%l", "TEAMNAME_ZOMBIE");

    // Stylize it to uppercase
    strtoupper(blue);
    strtoupper(red);

    hl_set_user_teamnames(id, blue, red);
}

// ----------------------- effects ------------------------------

stock GetLightningStart(origin[3]) {
    new Float:originThunder[3];
    originThunder[0] = float(origin[0]);
    originThunder[1] = float(origin[1]);
    originThunder[2] = float(origin[2]);

    while (engfunc(EngFunc_PointContents, originThunder) == CONTENTS_EMPTY)
        originThunder[2] += 5.0;

    return floatround(originThunder[2]);
}

stock LightningEffect(id) {
    new footPos[3];
    GetUserFootOrigin(id, footPos);

    // thunder falls on the zombie
    new lgntningPos[3]; lgntningPos = footPos;
    lgntningPos[2] = GetLightningStart(footPos);
    te_create_beam_between_points(footPos, lgntningPos, g_SprLgtning, _, _, 10, 125, 30, 255, 0, 0, 230, 100);

    // beam disc on floor
    new axis[3]; axis = footPos;
    axis[2] += 200; // beam radius
    te_create_beam_disk(footPos, g_SprLgtning, axis, 0, 0, 10, _, _, 255, 0, 0, 200);

    // drop red spheres
    new eyesPos[3];
    get_user_origin(id, eyesPos, 1);
    te_create_model_trail(footPos, eyesPos, g_SprLaserDot, 10, 10, 3, 25, 10); // note: 40 balls will overflow

    new origin[3];
    get_user_origin(id, origin);

    // red light for 3 seconds
    te_create_dynamic_light(origin, 20, 255, 0, 0, 30, 30);
}

stock GetUserFootOrigin(id, origin[3]) {
    new Float:footZ, Float:ground[3];
    pev(id, pev_absmin, ground);
    footZ = ground[2];
    
    pev(id, pev_origin, ground);

    // increment 2 units so sprite can show
    ground[2] = footZ + 2.0;

    for (new i; i < 3; i++)
        origin[i] = floatround(ground[i]);
}

// ----------------------------- round timer --------------------------------

public TaskDisplayTimer(taskid) {
    DisplayTimer();
}

public DisplayTimer() {
    set_hudmessage(230, 230, 230, -1.0, 0.01, 2, 0.01, 600.0, 0.05, 0.01);
    ShowSyncHudMsg(0, g_ScoreHudSync, "%l^n%d:%02d", "HUD_SCORE", GetTeamScore(TEAM_ZOMBIE), GetTeamScore(TEAM_HUMAN), g_RoundTime / 60, g_RoundTime % 60);
}


StartRoundTimer() {
    remove_task(TASK_DISPLAYTIMER);
    if (RoundTimerCheck()) {
        DisplayTimer();
        set_task_ex(1.0, "RoundTimerThink", TASK_DISPLAYTIMER, .flags = SetTask_Repeat);
    }
}

public RoundTimerThink() {
    if (g_RoundTime == 0) {
        g_RoundWinner = TEAM_NONE;
        RoundEnd();
    }

    if (RoundTimerCheck())
        g_RoundTime--;
    DisplayTimer();
}

public RoundTimerCheck() {
    return g_RoundStarted && g_RoundTime > 0 ? true : false;
}

// ----------------------- Send to spec victim -----------------------------------
public SendToSpec(taskid) {
    new id = taskid - TASK_SENDTOSPEC;
    if (!is_user_alive(id) || is_user_bot(id))
        hl_set_user_spectator(id, true);
}


// ------------------------- Block kill and spectate commands ------------------------

public OnCmdSpectate() {
    return PLUGIN_HANDLED;
}

public OnClientKill() {
    return FMRES_SUPERCEDE;
}

// -------------------------- Restart Round -----------------------------------

public OnCmdRestartGame(id, level, cid) {
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

    // reset players score
    for (new i = 1; i <= MaxClients; i++) {
        if (is_user_connected(i))
            hl_set_user_score(i, 0, 0);
    }

    // reset team score
    for (new i; i < sizeof(g_TeamScore); i++) {
        g_TeamScore[i] = 0;
    }

    RoundRestart();

    client_print(0, print_center, "%l", "ROUND_RESTART");

    return PLUGIN_HANDLED;
}

public OnCmdRestartRound(id, level, cid) {
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

    RoundRestart();

    client_print(0, print_center, "%l", "ROUND_RESTART");

    return PLUGIN_HANDLED;
}

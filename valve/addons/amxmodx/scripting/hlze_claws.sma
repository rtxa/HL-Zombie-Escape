#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <hlstocks>
#include <hlze_stocks>
#include <hlze_const>

#define PLUGIN "HL:ZE - Claws"
#define VERSION "0.2"
#define AUTHOR "rtxA"

#pragma semicolon 1

#define CROWBAR_IDLE1 0
#define CROWBAR_IDLE2 9
#define CROWBAR_IDLE3 10

// ---------------------------- Sounds ---------------------------------
new const SND_ZMB_HITBOD[][] = { "hlze/zombi_attack_1.wav", "hlze/zombi_attack_2.wav", "hlze/zombi_attack_3.wav" };
new const SND_ZMB_HITWALL[][] = { "hlze/zombi_wall_1.wav", "hlze/zombi_wall_2.wav", "hlze/zombi_wall_3.wav" };

// ---------------------------- Models ---------------------------------
new const MDL_ZMB_CLAWS[] = "models/hlze/v_claws_host.mdl";

public plugin_precache() {
    PrecacheSoundList(SND_ZMB_HITWALL, sizeof SND_ZMB_HITWALL);
    PrecacheSoundList(SND_ZMB_HITBOD, sizeof SND_ZMB_HITBOD);

    precache_model(MDL_ZMB_CLAWS);
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_forward(FM_EmitSound, "OnEmitSound");

    RegisterHam(Ham_Item_Deploy, "weapon_crowbar", "Crowbar_Deploy", true);
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_crowbar", "Crowbar_PrimaryAttack_Post", true);
    RegisterHam(Ham_Weapon_WeaponIdle, "weapon_crowbar", "Crowbar_WeaponIdle"); // thanks milashkasiya for code for weapon idle
}

public Crowbar_Deploy(entity) {
    new player = get_ent_data_entity(entity, "CBasePlayerItem", "m_pPlayer");
    
    set_ent_data_float(entity, "CBasePlayerWeapon", "m_flTimeWeaponIdle", get_gametime() + 3.0);

    if (hl_get_user_team(player) == TEAM_ZOMBIE) {
        set_pev(player, pev_viewmodel2, MDL_ZMB_CLAWS);
        set_pev(player, pev_weaponmodel2, "");
    }
}

public Crowbar_PrimaryAttack_Post(entity) {
    new player = get_ent_data_entity(entity, "CBasePlayerItem", "m_pPlayer");

    if (hl_get_user_team(player) == TEAM_ZOMBIE) {
        set_ent_data_float(entity, "CBasePlayerWeapon", "m_flTimeWeaponIdle", get_gametime() + random_float(10.0, 15.0));
    }
}

public Crowbar_WeaponIdle(entity) {
    new player = get_ent_data_entity(entity, "CBasePlayerItem", "m_pPlayer");

    if (hl_get_user_team(player) != TEAM_ZOMBIE)
        return HAM_IGNORED;   

    new Float:time = get_gametime();
    
    if (get_ent_data_float(entity, "CBasePlayerWeapon", "m_flTimeWeaponIdle") > time)
        return HAM_IGNORED;
    
    new anim;
    new Float:nextIdle;
    new Float:rand = random_float(0.0, 1.0);
    
    if (rand <= 0.5) {
        anim = CROWBAR_IDLE1;
        nextIdle = 35.0 / 13.0;
    } else if (rand <= 0.75) {
        anim = CROWBAR_IDLE2;
        nextIdle = 80.0 / 15.0;
    } else {
        anim = CROWBAR_IDLE3;
        nextIdle = 80.0 / 15.0;
    }

    ExecuteHam(Ham_Weapon_SendWeaponAnim, entity, anim, 1, 0);
    set_ent_data_float(entity, "CBasePlayerWeapon", "m_flTimeWeaponIdle", time + nextIdle * 2.0);

    return HAM_IGNORED;
}

public OnEmitSound(ent, channel, sample[], Float:volume, Float:attn, flag, pitch) {
    if (!IsPlayer(ent) || hl_get_user_team(ent) != TEAM_ZOMBIE)
        return FMRES_IGNORED;

    // half-life default sounds to replace with zombie ones
    static const CBAR_HIT1[] = "weapons/cbar_hit1.wav";
    static const CBAR_HIT2[] = "weapons/cbar_hit2.wav";
    static const CBAR_HITBOD1[] = "weapons/cbar_hitbod1.wav";
    static const CBAR_HITBOD2[] = "weapons/cbar_hitbod2.wav";
    static const CBAR_HITBOD3[] = "weapons/cbar_hitbod3.wav";

    // replace default sounds with zombie sounds.
    // note: this doesn't have a recursive effect because hooks are not triggered if they are from amxx, only from gamedll
    if (equal(sample, CBAR_HIT1) || equal(sample, CBAR_HIT2)) {
        emit_sound(ent, channel, SND_ZMB_HITWALL[random(sizeof SND_ZMB_HITWALL)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        return FMRES_SUPERCEDE;
    } else if (equal(sample, CBAR_HITBOD1) || equal(sample, CBAR_HITBOD2) || equal(sample, CBAR_HITBOD3)) {
        emit_sound(ent, channel, SND_ZMB_HITBOD[random(sizeof SND_ZMB_HITBOD)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        return FMRES_SUPERCEDE;
    }

    return FMRES_IGNORED;
}

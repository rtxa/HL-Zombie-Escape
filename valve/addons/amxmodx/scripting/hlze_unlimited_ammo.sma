#include <amxmodx>
#include <fakemeta>
#include <hlstocks>

#define PLUGIN "HL:ZE - Unlimited Ammo"
#define VERSION "0.2"
#define AUTHOR "rtxA | Dr.Freeman"

enum {
	ammo_none,
	ammo_shotgun,
	ammo_9mm,
	ammo_argrenade,
	ammo_357,
	ammo_uranium,
	ammo_rpg,
	ammo_crossbow,
	ammo_tripmine,
	ammo_satchel,
	ammo_grenade,
	ammo_snark,
	ammo_hornet
};

new const g_maxammo[] = {
	-1,
	125,
	250,
	10,
	36,
	100,
	5,
	50,
	10,
	5,
	10,
	15,
	8
};

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event("CurWeapon", "OnEventCurWeapon", "be", "1=1")
	register_message(get_user_msgid("AmmoX"), "OnMsgAmmoX");
}

// ------------------------ Unlimited Ammo ---------------------------

public OnEventCurWeapon(id){
	new weapon = read_data(2)
	new ammoid = get_wpn_ammotype(weapon)
	
	set_ent_data(id, "CBasePlayer", "m_rgAmmo", get_max_ammo(ammoid), ammoid);
}

public OnMsgAmmoX(mid,dest,id){
	new ammoid = get_msg_arg_int(1);
	new amount = get_msg_arg_int(2);

	if (is_user_alive(id)) {
		switch (ammoid) {
			// for now, only some weapons will have unlimited ammo
			case ammo_9mm, ammo_357, ammo_shotgun, ammo_rpg, ammo_crossbow: {
				if (amount < get_max_ammo(ammoid)) {
                    set_ent_data(id, "CBasePlayer", "m_rgAmmo", get_max_ammo(ammoid), ammoid);
                    set_msg_arg_int(2, ARG_BYTE, get_max_ammo(ammoid));
                }
			}
		}
	}
}
//--------------------------------------------------------------------------------------------------

get_max_ammo(ammoid) {
	if (ammoid < sizeof g_maxammo)
		return g_maxammo[ammoid];
	else
		return 1;
}

get_wpn_ammotype(wid) {
	switch (wid){
		case HLW_CROWBAR: return ammo_none;
		case HLW_GLOCK: return ammo_9mm;
		case HLW_PYTHON: return ammo_357;
		case HLW_MP5: return ammo_9mm;
		case HLW_SHOTGUN: return ammo_shotgun;
		case HLW_CROSSBOW: return ammo_crossbow;
		case HLW_RPG: return ammo_rpg;
		case HLW_GAUSS: return ammo_uranium;
		case HLW_EGON: return ammo_uranium;
		case HLW_HORNETGUN: return ammo_hornet;
		case HLW_HANDGRENADE: return ammo_grenade;
		case HLW_TRIPMINE: return ammo_tripmine;
		case HLW_SATCHEL: return ammo_satchel;
		case HLW_SNARK: return ammo_snark;
	}
	
	return ammo_none;
}
/*
	AUTHOR: pedeathtrian
	NAME: pdth/mr/init_repack_for_player.sqf
	VERSION: 0.0.2

	DESCRIPTION:
	This file is a part of pedeathtrian's magazine-repack "pdth/mr" bunch of scripts.
	This file initializes action for player allowing to repack their magazines.

	See also comments in pdth/mr/has_repack.sqf, pdth/mr/do_repack.sqf and pdth/mr/repack_misc.sqf
*/

// CONFIGURABLE VARIABLES
// repack type: 0 - non-roundwise; 1 - roundwise
pdth_mr_repack_type = 1;
pdth_mr_time_repack_base = 2; // common delay on repack start
// non-roundwise repack delays
pdth_mr_time_repack_class = 6; // time to repack all mags of some class
// roundwise repack delays
pdth_mr_time_repack_rw_round = 1; // delay per ammo round loaded, applied when round inserted to mag
pdth_mr_time_repack_rw_round_unload = 0.4; // delay per ammo round unloaded, applied when round removed from other mag for repacking
pdth_mr_time_repack_rw_mag = 1; // delay per magazine used for repack, applied when mag filled or emptied
pdth_mr_allow_cancel_repack_rw = true; // if true there will be action to stop roundwise repack procedure, saving what is already done (for emergency situations)
// animations for start and end of repack (used with playMove)
pdth_mr_anim_repack_start = "AinvPknlMstpSnonWrflDnon_medic0";
pdth_mr_anim_repack_end = "AinvPknlMstpSnonWrflDnon_medicEnd";
// play this sound every repacked round (unloading and loading)
// played with volume 1.2 and pitch 1.8, so sounds differently from next even if the same name
pdth_mr_sound_round_click_unload = "A3\Sounds_F\arsenal\weapons\Pistols\Acpc2\dry_Acpc2.wss";
pdth_mr_sound_round_click = "A3\Sounds_F\arsenal\weapons\Pistols\Acpc2\dry_Acpc2.wss";
pdth_mr_sound_chainwork = "A3\Sounds_F\arsenal\weapons\LongRangeRifles\Mk18\Mk18_reload.wss";
// Chains
// Chained MGs
// Taking magazines[] from this classes we can make a list of all used chains
// Assuming these weapon classes use only chains
pdth_mr_chained_mgs = [
	"LMG_Mk200_F",
	"LMG_Mk200_MRCO_F",
	"LMG_Mk200_pointer_F",
	"LMG_Mk200_LP_BI_F",
	"LMG_Mk200_BI_F",
	"LMG_Zafir_F",
	"LMG_Zafir_pointer_F",
	"LMG_Zafir_ARCO_F",
	"MMG_01_hex_F",
	"MMG_01_tan_F",
	"MMG_01_hex_ARCO_LP_F",
	"MMG_02_camo_F",
	"MMG_02_black_F",
	"MMG_02_sand_F",
	"MMG_02_sand_RCO_LP_F",
	"MMG_02_black_RCO_BI_F",
	// RHS
	"rhs_pkp_base",
	"rhs_weap_m240veh",
	"rhs_weap_m240_base"
];
pdth_mr_chained_mags_add = [
	// what not added for some reason from previous list
	// if any
	"rhs_200rnd_556x45_M_SAW", "rhs_200rnd_556x45_B_SAW", "rhs_200rnd_556x45_T_SAW",
	"rhsusf_100Rnd_556x45_soft_pouch", "rhsusf_200Rnd_556x45_soft_pouch", "rhsusf_100Rnd_556x45_M200_soft_pouch" // ?
];
pdth_mr_chained_mags_excl = [
	// Exclusions from previous lists, not chains really
	// if any
];
pdth_mr_chained_mags = pdth_mr_chained_mags_add;
// 3rd-party variables that shoukd stop repacking, see description of _stopVars in pdth\mr\do_repack.sqf
pdth_mr_stop_vars = ["AT_Revive_isUnconscious", true, ["_caller"]];
// END CONFIGURABLE VARIABLES

[] spawn {
	{
		private ["_mags"];
		_mags = (getArray(configFile >> "CfgVehicles" >> _x >> "magazines") - pdth_mr_chained_mags_excl) - pdth_mr_chained_mags;
		pdth_mr_chained_mags = pdth_mr_chained_mags + _mags;
	} forEach pdth_mr_chained_mgs;
};

pdth_mr_has_repack = compile preprocessFileLineNumbers "pdth\mr\has_repack.sqf";
pdth_mr_do_repack = compile preprocessFileLineNumbers "pdth\mr\do_repack.sqf";
call compile preprocessFileLineNumbers "pdth\mr\repack_misc.sqf";

waitUntil {!(isNull player)};
player addEventHandler ["Respawn", pdth_mr_respawn_handler];

// uncommented if mission does not respawn player on start
[player, objNull] call pdth_mr_respawn_handler;

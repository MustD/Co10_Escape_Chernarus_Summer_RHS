/*
	AUTHOR: pedeathtrian
	NAME: pdth/mr/init_repack_for_player.sqf
	VERSION: 0.0.1

	DESCRIPTION:
	This file is a part of pedeathtrian's magazine-repack "pdth/mr" bunch of scripts.
	This file initializes action for player allowing to repack their magazines.

	See also comments in pdth/mr/has_repack.sqf and pdth/mr/do_repack.sqf files
*/

pdth_mr_time_repack_base = 2;
pdth_mr_time_repack_class = 6;
pdth_mr_anim_repack_start = "AinvPknlMstpSnonWrflDnon_medic0";
pdth_mr_anim_repack_end = "AinvPknlMstpSnonWrflDnon_medicEnd";
pdth_mr_repack_runs = false;

pdth_mr_has_repack = compile preprocessFileLineNumbers "pdth\mr\has_repack.sqf";
pdth_mr_do_repack = compile preprocessFileLineNumbers "pdth\mr\do_repack.sqf";

waitUntil {!isNull player};

pdth_mr_action = player addAction [
	"<t color='#FFCC99'>Repack magazines</t>",
	{call pdth_mr_do_repack},
	[
		pdth_mr_time_repack_base,
		pdth_mr_time_repack_class,
		pdth_mr_anim_repack_start,
		pdth_mr_anim_repack_end
	],
	1.5,
	false,
	true,
	"",
	"_target call pdth_mr_has_repack"
];

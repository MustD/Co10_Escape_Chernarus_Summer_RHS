/*
	AUTHOR: pedeathtrian
	NAME: pdth/mr/has_repack.sqf
	VERSION: 0.0.2

	DESCRIPTION:
	This file is a part of pedeathtrian's magazine-repack "pdth/mr" bunch of scripts.
	This function-as-file checks whether its arguments has magazines to repack, i.e. at least two non-full magazines of exact same type.
	Only inventory mags are taken into account, so currently loaded mags are not repacked.
	If you want to repack loaded mag,	unload it to inventory first.
	Takes exactly one argument: script target, the unit to check its inventory (actually only use is considered to be on player).
	Usage:
	1. put `pdth/mr' directory in your mission directory
	2. write somewhere in init scripts of your mission:
	pdth_mr_has_repack = compile preprocessFileLineNumbers "pdth/mr/has_repack.sqf";
	3. somewhere later:
	_UnitHasMagsToRepack = unit call pdth_mr_has_repack;

	RETURNS: bool
	- true: if target is not null and has magazines to repack.
	- false: otherwise.

	PARAMETER(S):
	target unit

	INTENDED USE:
	Used in `condition' argument for addAction to check the availability of mags to repack, so determines visibility of action.
	Beware that when used in addAction's `condition', special variables passed to the script code are _target (unit to which action is attached to) and _this (caller/executing unit),
	but this script uses `_this' as target unit, so if you want to apply script to object other than caller, tehn actual `condition' most likely would be "_target call pdth_mr_has_repack"
	See also: https://community.bistudio.com/wiki/addAction
*/
private ["_result", "_runs"];
_result = false;
if (!(isNull _this)) then {
	_runs = _this getVariable ["pdth_mr_repack_runs", false];
	if (!_runs) then {
		private ["_isMan", "_mags", "_nfMags", "_clName", "_magCount", "_fullMagCount"];
		//_isMan = (typeOf _this) isKindOf ["Man", (configFile >> "CfgVehicles")]; // requires v1.47
		_isMan = (typeOf _this) isKindOf "Man"; // we anyway scan in "CfgVehicles"
		_mags = if (_isMan) then {
			magazinesAmmo _this;
		} else {
			magazinesAmmoCargo _this;
		};
		if (count _mags > 0) then {
			// _nfMags is simply an array containing class names of non-full magazines found
			_nfMags = [];
			scopeName "_magsSN";
			{
				_clName = _x select 0;
				_magCount = _x select 1;
				_fullMagCount = getNumber(configFile >> "CfgMagazines" >> _clName >> "count");
				if (_magCount < _fullMagCount) then {
					if (_clName in _nfMags) then {
						// if we found second non-empty mag of this class, that means we can repack
						_result = true;
						breakTo "_magsSN";
					};
					_nfMags pushBack _clName;
				};
			} forEach _mags;
		};
	};
};
_result

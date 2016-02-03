/*
	AUTHOR: pedeathtrian
	NAME: pdth/mr/do_repack.sqf
	VERSION: 0.0.1

	DESCRIPTION:
	This file is a part of pedeathtrian's magazine-repack "pdth/mr" bunch of scripts.
	This function-as-file combines ammmo from non-full magazines in unit's inventory to full mags, leaving at most one non-full magazine.
	Only magazines of exact same type are repacked.
	Only inventory mags are taken into account, so currently loaded mags are not repacked.
	If you want to repack loaded mag,	unload it to inventory first.
	Takes exactly one argument: script target, the unit to check its inventory (actually only use is considered to be on player).
	This script does not pre-check the availability of any mags to repack, for this use the "pdth/mr/has_repack.sqf" script.
	Usage:
	1. put `pdth/mr' directory in your mission directory
	2. write somewhere in init scripts of your mission:
	pdth_mr_do_repack = compile preprocessFileLineNumbers "pdth/mr/do_repack.sqf";
	3. somewhere later:
	unit call pdth_mr_do_repack;

	RETURNS: nothing.

	PARAMETER(S): array
	_this select 0 is considered as target unit
	_this select 3 is considered as array of this sript's arguments, consisting of:
		0. number: pre-sleep for all repack procedure, Z
		1. number: sleep on each repacked mag class, Y. So assuming you have X classes to repack, it will take time Z + X*Y.
		2. String: animation move name on start, e.g. to animate repacking, e.g. "AinvPknlMstpSnonWrflDr_medic2"
		3. String: animation move name on end, e.g. "AinvPknlMstpSnonWrflDnon_medicEnd" or "": don't forget unit can stuck after starting move
		You can pass empty array ot nil to immediatelly repack magazines without  animation (e.g. for crates).

	INTENDED USE:
	Used in `script' argument for addAction to repack magazines (actual use in `script' argument is {call pdth_mr_do_repack} then).
	See also: https://community.bistudio.com/wiki/addAction
*/
private ["_target", "_mags", "_nfMags", "_nrMags", "_amMags", "_clName", "_magCount", "_fullMagCount", "_amFound", "_newFull", "_newCount", "_remain", "_mag", "_oldMags", "_dispNm"];

_target = _this select 0;
if (!isNull _target) then {
	_mags = magazinesAmmo _target;
	if (count _mags > 0) then {
		// _nfMags is simply an array containing class names of non-full magazines found
		_nfMags = [];
		// _nrMags is simply an array containing class names that need repack
		_nrMags = [];
		/*
			_amMags is an array containing full amount of ammo of specific class
			_amMags structure:
			[
				[
					className,	// String, mag's className
					totalAmmo,	// number, total ammo in all (incl. full) mags of that class
					magsCount	// number, of mags of that class
				],
				...
			]
		*/
		_amMags = [];

		{
			scopeName "_magsSN";
			_clName = _x select 0;
			_magCount = _x select 1;
			_fullMagCount = getNumber(configFile >> "CfgMagazines" >> _clName >> "count");
			if (_magCount < _fullMagCount) then {
				if (_clName in _nfMags) then {
					// if we found second non-empty mag of this class, that means we can repack
					_nrMags pushBack _clName;
				};
				_nfMags pushBack _clName;
			};
			_amFound = false;
			private ["_i"];
			_i = 0;
			{
				if (_clName == _x select 0) then {
					_amFound = true;
					breakTo "_magsSN";
				};
				_i = _i + 1;
			} forEach _amMags;
			if (_amFound) then {
				_newFull = ((_amMags select _i) select 1) + _magCount;
				_newCount = ((_amMags select _i) select 2) + 1;
				_amMags set [_i, [_clName, _newFull, _newCount]];
			} else {
				_amMags pushBack [_clName, _magCount, 1];
			};
		} forEach _mags;

		if (count _nrMags > 0) then {
			private ["_args", "_pmtrb", "_pmtrc", "_pmars", "_pmare"];
			_args = _this select 3;
			if (isNil "_args") then {
				_pmtrb = nil;
				_pmtrc = nil;
				_pmars = nil;
				_pmare = nil;
			} else {
				_pmtrb = _args select 0;
				if (_pmtrb <= 0) then {
					_pmtrb = nil;
				};
				_pmtrc = _args select 1;
				if (_pmtrc <= 0) then {
					_pmtrc = nil;
				};
				_pmars = _args select 2;
				_pmare = _args select 3;
			};
			if (!isNil "_pmars") then {
				_target playMove _pmars;
			};
			if (!isNil "_pmtrb") then {
				sleep _pmtrb;
			};
			{
				scopeName "_nrMagsSN";
				_clName = _x;
				_target removeMagazines _clName;
				_remain = 0;
				{
					if (_clName == (_x select 0)) then {
						_remain = _x select 1;
						_oldMags = _x select 2;
						breakTo "_nrMagsSN";
					};
				} forEach _amMags;
				if (_remain > 0) then {
					_fullMagCount = getNumber(configFile >> "CfgMagazines" >> _clName >> "count");
					_dispNm = getText(configFile >> "CfgMagazines" >> _clName >> "displayName");
					_mag = floor (_remain / _fullMagCount);
					_target addMagazines [_clName, _mag];
					if (_remain % _fullMagCount > 0) then {
						_target addMagazine [_clName, _remain % _fullMagCount];
						_mag = _mag + 1;
					};
					if (!isNil "_pmtrc") then {
						sleep _pmtrc;
					};
					player groupChat format ["Repacked '%1': %2 to %3 mags (%4 rounds)", _dispNm, _oldMags, _mag, _remain];
				};
			} forEach _nrMags;
			if (!isNil "_pmare") then {
				_target playMove _pmare;
			};
		};
	};
};

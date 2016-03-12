/**
	@file pdth/mr/do_repack.sqf
	@author pedeathtrian
	@version 0.0.3

	This file is a part of pedeathtrian's magazine-repack "pdth/mr" bunch of scripts.
	This function-as-file combines ammmo from non-full magazines in unit's inventory to full mags, leaving at most one non-full magazine.
	Only magazines of exact same class are repacked.
	Only inventory mags are taken into account, so currently loaded mags are not repacked.
	Should work on containers (need test).
	For infantry units, magazines disposition is not saved, but since amount of mags of certain type cannot grow after repack, this should not be a problem.
	If you want to repack loaded mag,	unload it to inventory first.
	This script does not pre-check the availability of any mags to repack, for this use the "pdth/mr/has_repack.sqf" script.
	Setting variable "pdth_mr_repack_cancelled" for either target or caller will abort operation, possibly with some ammo lost (dropped on ground near target).

	@return nothing.

	@param _this: Array: [_target, (_caller, _id, _args)]
		_target (_this select 0): unit on which to perform repack of magazines
		_caller (_this select 1): unit performing action (specified explicitly or trough action mechanism)
			If called with infantry as this parameter and also delays are set (see below),
			caller unit kneels and starts to empty magazines with less ammo and fill with them magazines with more ammo,
			until interrupted or there's no more mags to fill. If delays are specified,
			repacking is done with sound (sorry, no animation for actual ammo repacking, ask BIS for it).
		_id (_this select 1): ignored
		_args: arguments for script, as follows: [_type, _stopVars, _delays]
			_type: String: one of: "NONROUNDWISE", "ROUNDWISE"
			_stopVars: Array: [ [_name, _value, [_object1, ...]], ... ]
				When repacking with delays, algorithm checks presence of variable _name on list of correspondent entities.
				If variable present and isEqualTo passed _value, repack cancels (may still need some time).
				You can specify multiple variable names in separate items in _stopVars.
				_name: String: name of variable to check
				_values: Array: values (Strings or Arrays) to stop repack at (compared with isEqualTo)
				_object1, ...: list of anything you can call getVariable on, see https://community.bistudio.com/wiki/getVariable
					Special value string "_caller" can be specified in array, so that method caller could be used:
					there's no way for example to pass caller to script's arguments (i.e. _args) when adding action.
				[ "pdth_mr_repack_cancelled", true, [_target, _caller] ] is implied by default -- used during running repack
				[ "pdth_mr_repack_runs", true, [_target, _caller] ] is checked before start
			_delays: Array: numbers: either of:
				[ baseDelay, perClassDelay ] - for non-roundwise repack
				[ baseDelay, delayPerRound, delayPerRoundUnload, delayPerMag ] - for roundwise repack (more realistic)
					baseDelay: delay performed on start of repack
					perClassDelay: time needed to repack all magazines of some class
					delayPerRound: delay required to insert ammo into magazine
					delayPerRoundUnload: delay required to remove ammo from magazine (performed on some mag before inserting to another)
					delayPerMag: delay performed on emptying or filling magazine
			You can pass empty array or nil to immediatelly repack magazines without  animation (e.g. for crates).

	@example
	pdth_mr_has_repack = compile preprocessFileLineNumbers "pdth\mr\has_repack.sqf";
	pdth_mr_do_repack = compile preprocessFileLineNumbers "pdth\mr\do_repack.sqf";
	call compile preprocessFileLineNumbers "pdth\mr\repack_misc.sqf";
	_actId = player addAction [
		"Repack magazines",
		{_this call pdth_mr_do_repack},
		[
			"ROUNDWISE",
			[2, 1, 0.4, 2]
		],
		1.5, false, true, "",
		"[_target, _this] call pdth_mr_check_repack_player"
	];
	@example
	pdth_mr_do_repack = compile preprocessFileLineNumbers "pdth\mr\do_repack.sqf";
	// immediately repacks all ammo in container
	[ammoBox] call pdth_mr_do_repack;

	@example
	pdth_mr_do_repack = compile preprocessFileLineNumbers "pdth\mr\do_repack.sqf";
	// will automatically repack all ammo placed in someCar's cargo space
	_ehId = someCar addEventHandler ["ContainerClosed", {_this call pdth_mr_do_repack}];

	@see pdth/mr/init_repack_for_player.sqf
	@see pdth/mr/repack_misc.sqf
	@see https://community.bistudio.com/wiki/addAction
	@see https://community.bistudio.com/wiki/setVariable

	@todo pass parameters for playSound3D: name, volume, pitch, max hearable distance;
		test on containers.
**/
private ["_fnc_setUp_WH"];
_fnc_setUp_WH = {
	params [["_ref", objNull, [objNull]]];
	private ["_ret"];
	_ret = objNull;
	if (!(isNull _ref)) then {
		private ["_refBox", "_whPos"];
		_refBox = boundingBoxReal _ref;
		_whPos = _ref modelToWorld [0, ((_refBox select 1) select 1)-0.2, 0];
		_z = (getPosATL _ref) select 2;
		if (abs(_z) < 0.5) then {
			_whPos set [2, 0];
		};
		_ret = createVehicle ["GroundWeaponHolder", _whPos, [], 0, "CAN_COLLIDE"];
		_ret setDir (45 + direction _ref);
		if (abs(_z) < 0.5) then {
			_ret setVectorUp (surfaceNormal _whPos);
		};
	};
	_ret
};

params [["_target", objNull, [objNull]], ["_caller", objNull, [objNull]], ["_args", [], [[]]]];
private ["_nnT", "_nnC", "_isManT", "_isManC", "_onFootC", "_plC", "_stopVars", "_haveSV", "_localT", "_localC"];
// ensure we work with local copy and don't expose local _caller
_stopVars = [_args param [1, [], [[]]], [["_caller", _caller]]] call pdth_mr_deep_copy_w_replace;
_haveSV = ([[ "pdth_mr_repack_runs", [true], [_target, _caller]]] call pdth_mr_check_stop_vars) || (_stopVars call pdth_mr_check_stop_vars);
_nnT = (!(isNull _target));
_nnC = (!(isNull _caller));
_isManT = false;
_isManC = false;
_onFootC = false;
_plC = false;
_localT = false;
_localC = true;
if (_nnT) then {
	//_isManT = (typeOf _target) isKindOf ["Man", (configFile >> "CfgVehicles")]; // requires v1.47
	_isManT = (typeOf _target) isKindOf "Man"; // we anyway scan in "CfgVehicles"
	_localT = local _target;
};
if (_nnC) then {
	_onFootC = (_caller == (vehicle _caller));
	if (_caller == _target) then {
		_isManC = _isManT;
		_localC = _localT;
	} else {
		//_isManC = (typeOf _caller) isKindOf ["Man", (configFile >> "CfgVehicles")]; // requires v1.47
		_isManC = (typeOf _caller) isKindOf "Man"; // we anyway scan in "CfgVehicles"
		_localC = local _caller;
	};
	_plC = isPlayer _caller;
};
if ((!_haveSV) || (_plC && (!alive _caller))) then {
	if (_nnT && ((!_nnC) || (_onFootC && _isManC))) then { // if caller is specified, it must be infantry on foot
		private ["_cancel", "_mags", "_nfMags", "_nrMags", "_amMags", "_clName", "_magCount", "_fullMagCount", "_amFound", "_newFull", "_newCount", "_remain", "_mag", "_oldMags", "_dispNm", "_var"];
		_cancel = false;
		_var = false;

		_target setVariable ["pdth_mr_repack_runs", true, !_localT];
		if (_target != _caller) then {
			if (_nnC) then {
				_caller setVariable ["pdth_mr_repack_runs", true, !_localC];
			};
		};

		_mags = if (_isManT) then {magazinesAmmo _target} else {magazinesAmmoCargo _target};
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

			/* This loop goes for all _target magazines and counting all magazines of each class
			and rounds number in them */
			{ // forEach _mags;
				scopeName "_magsSN";
				/// @var string _clName Mag name i.e. "30Rnd_65x39_caseless_mag"
				_clName = _x select 0;
				/// @var int _magCount Rounds number in magazine i.e. 23
				_magCount = _x select 1;
				/// @var int _fullMagCount Full capacity of magazine
				_fullMagCount = getNumber(configFile >> "CfgMagazines" >> _clName >> "count");

				if (_magCount < _fullMagCount) then {
					// Mag not full
					if ((_clName in _nfMags) && (!(_clName in _nrMags))) then {
						// We found second non-empty mag of this class, that means we can repack
						_nrMags pushBack _clName;
					};
					if (!(_clName in _nfMags)) then {
						// We found first not full mag of this class
						_nfMags pushBack _clName;
					};
				};
				_amFound = false;
				private ["_i"];
				_i = 0;
				{ // forEach _amMags;
					if (_clName == _x select 0) then {
						_amFound = true;
						breakTo "_magsSN";
					};
					_i = _i + 1;
				} forEach _amMags;
				if (_amFound) then {
					// Adding rounds to all rounds of this class count
					_newFull = ((_amMags select _i) select 1) + _magCount;
					// Adding mag to all mags of this class count
					_newCount = ((_amMags select _i) select 2) + 1;
					_amMags set [_i, [_clName, _newFull, _newCount]];
				} else {
					// Adding first mag of this class
					_amMags pushBack [_clName, _magCount, 1];
				};
			} forEach _mags;

			if (count _nrMags > 0) then {
				// Found not full >1 mags of same class
				private ["_rptype", "_delays", "_pmtrb", "_pmtrc", "_pmtrr", "_pmtrru", "_pmtrm", "_curMuz", "_haveDelays", "_gwhDisp"];
				_haveDelays =false;
				_gwhDisp = objNull;
				//_args = _this select 3;
				if (!(isNil "_args")) then {
					_rptype = _args select 0;
					if (!(isNil "_rptype")) then {
						_delays = _args select 2;
						if (!(isNil "_delays")) then {
							// common
							_pmtrb = _delays select 0;
							if (!(isNil "_pmtrb")) then {
								if (_pmtrb <= 0) then {
									_pmtrb = nil;
								} else {
									_haveDelays = true;
								};
							};
							switch (_rptype) do {
								case "NONROUNDWISE": {
									_pmtrc = _delays select 1;
									if (!(isNil "_pmtrc")) then {
										if (_pmtrc <= 0) then {
											_pmtrc = nil;
										} else {
											_haveDelays = true;
										};
									};
								};
								case "ROUNDWISE": {
									_pmtrr = _delays select 1;
									if (!(isNil "_pmtrr")) then {
										if (_pmtrr <= 0) then {
											_pmtrr = nil;
										} else {
											_haveDelays = true;
										};
									};
									_pmtrru = _delays select 2;
									if (!(isNil "_pmtrru")) then {
										if (_pmtrru <= 0) then {
											_pmtrru = nil;
										} else {
											_haveDelays = true;
										};
									};
									_pmtrm = _delays select 3;
									if (!(isNil "_pmtrm")) then {
										if (_pmtrm <= 0) then {
											_pmtrm = nil;
										} else {
											_haveDelays = true;
										};
									};
								};
							};
						};
					};
				};
				if (_plC && _localC) then {
					// arma seems to have a bug and prematurely interrupts animation if you have a pistol as active weapon
					private "_type";
					_type = primaryWeapon _caller;
					if (_type != "") then {
						private "_muzzles";
						// check for multiple muzzles (eg: GL)
						_muzzles = getArray(configFile >> "cfgWeapons" >> _type >> "muzzles");
						_curMuz = currentMuzzle _caller;
						if (count _muzzles > 1) then {
							_type = (_muzzles select 0);
						};
						_caller selectWeapon _type;
						if (_curMuz != _type) then {
							sleep 0.2;
						};
						_caller playMove "AinvPknlMstpSnonWrflDnon_medic0";
					} else {
						_caller playMove "AinvPknlMstpSnonWnonDnon_medic";
					};
					_caller groupChat "Repack started...";
				};
				if (!isNil "_pmtrb") then {
					if (_pmtrb > 0) then {
						sleep _pmtrb*(0.85+random(0.3));
					};
				};
				scopeName "repack";
				{ //forEach _nrMags;
					scopeName "_nrMagsSN";
					_clName = _x;
					_fullMagCount = getNumber(configFile >> "CfgMagazines" >> _clName >> "count");
					_dispNm = getText(configFile >> "CfgMagazines" >> _clName >> "displayName");
					_remain = 0;
					{
						if (_clName == (_x select 0)) then {
							_remain = _x select 1;
							_oldMags = _x select 2;
							breakTo "_nrMagsSN";
						};
					} forEach _amMags;
					if (_plC && _localC) then {
						_caller groupChat format ["Repacking '%1'", _dispNm];
					};
					switch (_rptype) do {
						case "NONROUNDWISE": {
							scopeName "nonroundwise";
							if (_remain > 0) then {
								private ["_mag", "_rem"];
								_haveSV = ([[ "pdth_mr_repack_cancelled", [true], [_target, _caller]]] call pdth_mr_check_stop_vars) || (_stopVars call pdth_mr_check_stop_vars) || (_plC && (!alive _caller));
								if (_haveSV) then {
									_cancel = true;
									if (_plC && _localC) then {
										_caller groupChat "Repack cancelled.";
									};
									breakTo "repack";
								};
								_mag = floor (_remain / _fullMagCount);
								_rem = _remain % _fullMagCount;
								// there's no easy way to remove special type of magazines from unit or cargo space
								// (for units removeMagazines can create invalid combinations, see https://community.bistudio.com/wiki/removeMagazines)
								// but global variant is damn long to wait.
								if (_isManT) then {
									if (_localT) then {
										_target removeMagazines _clName;
										waitUntil {!(_clName in (magazines _target))};
									} else {
										// this is incredibly laggy and slow =(
										while {_clName in (magazines _target)} do {
											_target removeMagazineGlobal _clName; // does not remove loaded: ok
										};
									};
									_target addMagazines [_clName, _mag];
									if (_rem > 0) then {
										_target addMagazine [_clName, _rem];
									};
								} else {
									clearMagazineCargoGlobal _target;
									{
										if (_clName != (_x select 0)) then {
											_target addMagazineAmmoCargo [_x select 0, 1, _x select 1];
										};
									} forEach _mags;
									_target addMagazineCargoGlobal [_clName, _mag];
									if (_rem > 0) then {
										_target addMagazineAmmoCargo [_clName, 1, _rem]
									};
								};
								if (_rem > 0) then {
									_mag = _mag + 1;
								};
								if (!isNil "_pmtrc") then {
									if (_pmtrc > 0) then {
										sleep _pmtrc*(0.85+random(0.3));
									};
								};
								if (_plC && _localC) then {
									_caller groupChat format ["Repacked '%1': %2 to %3 mags (%4 rounds)", _dispNm, _oldMags, _mag, _remain];
								};
							};
						};
						case "ROUNDWISE": {
							private ["_mCounts", "_i", "_iPut", "_iTake", "_leftToPut", "_haveToTake", "_canTake", "_oldHave", "_gwh"];
							// ArmA 3 v1.42, BIS_fnc_sortBy spoils passed array with strings "BIS_fnc_sortByRemoveMe" strings if some items were removed,
							// so we get a copy of array first // deep copy is done by unary + operator
							_mCounts = [+_mags, [_clName, _fullMagCount], {_x select 1}, "DESCEND", {(((_x select 0) == _input0) && ((_x select 1) < _input1))}] call BIS_fnc_sortBy;
							_iTake = count _mCounts - 1;
							while {((_mCounts select _iTake) select 1) == 0} do {
								_iTake = _iTake - 1;
							};
							_iPut = 0;
							if (_isManT) then {
								if (_localT) then {
									_target removeMagazines _clName;
									waitUntil {!(_clName in (magazines _target))};
								} else {
									// this is incredibly laggy and slow =(
									while {_clName in (magazines _target)} do {
										_target removeMagazineGlobal _clName; // does not remove loaded: ok
									};
								};
								if ((_oldMags - (_iTake+1)) > 0) then {
									_target addMagazines [_clName, _oldMags - (_iTake+1)];
								};
							} else {
								clearMagazineCargoGlobal _target;
								{
									if (_clName != (_x select 0)) then {
										_target addMagazineAmmoCargo [_x select 0, 1, _x select 1];
									};
								} forEach _mags;
								if ((_oldMags - (_iTake+1)) > 0) then {
									_target addMagazineCargoGlobal [_clName, _oldMags - (_iTake+1)];
								};
							};

							scopeName "roundwise";
							while {_iPut < _iTake} do {
								if (_plC && _haveDelays) then {
									if (!(isNull _gwhDisp)) then {
										deleteVehicle _gwhDisp;
									};
									_gwhDisp = [_target] call _fnc_setUp_WH;
									[_gwhDisp, false] remoteExec ["enableSimulationGlobal", 2];
									if (!(isNull _gwhDisp)) then {
										for [{_i=_iPut}, {_i <= _iTake}, {_i = _i + 1}] do {
											_gwhDisp addMagazineAmmoCargo [_clName, 1, (_mCounts select _i) select 1];
										};
									};
									_gwhDisp setDamage 1;
								};
								_oldHave = (_mCounts select _iPut) select 1;
								_leftToPut = _fullMagCount - _oldHave;
								_haveToTake = (_mCounts select _iTake) select 1;
								if (_haveToTake <= _leftToPut) then {
									_canTake = _haveToTake;
								} else {
									_canTake = _leftToPut;
								};
								if (_clName in pdth_mr_chained_mags) then {
									/// chains are treated specially: you don't need to remove all ammo from one chain to put them to another
									if (!isNil "pdth_mr_sound_chainwork") then {
										playSound3D [pdth_mr_sound_chainwork, _target, false, getPosASL _target, 1.76+random(1.25), 0.8+random(0.4), 10];
									};
									if (!isNil "_pmtrm") then {
										if (_pmtrm > 0) then {
											sleep _pmtrm*(0.85+random(0.3));
										};
									};
									if (_haveToTake > _leftToPut) then {
										// if we have longer second chain, than we can connect to first chain, then addition chain cut required
										if (!isNil "pdth_mr_sound_chainwork") then {
											playSound3D [pdth_mr_sound_chainwork, _target, false, getPosASL _target, 1.76+random(1.25), 0.8+random(0.4), 10];
										};
										if (!isNil "_pmtrm") then {
											if (_pmtrm > 0) then {
												sleep _pmtrm*(0.85+random(0.3));
											};
										};
									};
								} else {
									if (!isNil "_pmtrru") then {
										for [{_i=0}, {_i < _canTake}, {_i = _i + 1}] do {
											if (_pmtrru > 0) then {
												sleep _pmtrru*(0.85+random(0.3));
											};
											if (!isNil "pdth_mr_sound_round_click_unload") then {
												playSound3D [pdth_mr_sound_round_click_unload, _target, false, getPosASL _target, 1.76+random(1.25), 1.4+random(0.4), 10];
											};

											_haveSV = ([[ "pdth_mr_repack_cancelled", [true], [_target, _caller]]] call pdth_mr_check_stop_vars) || (_stopVars call pdth_mr_check_stop_vars)  || (_plC && (!alive _caller))
												|| (_plC && (((animationState _caller) find "medic") == -1))
												;
											if (_haveSV) then {
												_mCounts set [_iTake, [_clName, _haveToTake-_i-1]];
												_cancel = true;
												_gwh = [_target] call _fnc_setUp_WH;
												_gwh addMagazineAmmoCargo [_clName, 1, _i+1];
												if (_plC && _localC) then {
													_caller groupChat format ["Repack cancelled, %1 rounds lost", _i+1];
												};
												breakTo "roundwise";
											};
										};
									};
									if (!isNil "_pmtrr") then {
										for [{_i=0}, {_i < _canTake}, {_i = _i + 1}] do {
											if (_pmtrr > 0) then {
												sleep _pmtrr*(0.85+random(0.3));
											};
											if (!isNil "pdth_mr_sound_round_click") then {
												playSound3D [pdth_mr_sound_round_click, _target, false, getPosASL _target, 3.1, 1, 10];
											};

											_haveSV = ([[ "pdth_mr_repack_cancelled", [true], [_target, _caller]]] call pdth_mr_check_stop_vars) || (_stopVars call pdth_mr_check_stop_vars)  || (_plC && (!alive _caller))
												|| (_plC && (((animationState _caller) find "medic") == -1))
												;
											if (_haveSV) then {
												_mCounts set [_iPut, [_clName, _oldHave+_i+1]];
												_mCounts set [_iTake, [_clName, _haveToTake-_canTake]];
												_cancel = true;
												_gwh = [_target] call _fnc_setUp_WH;
												_gwh addMagazineAmmoCargo [_clName, 1, _canTake-(_i+1)];
												if (_plC && _localC) then {
													_caller groupChat format ["Repack cancelled, %1 rounds lost", _canTake-(_i+1)];
												};
												breakTo "roundwise";
											};
										};
									};
								};
								_mCounts set [_iPut, [_clName, _oldHave+_canTake]];
								_mCounts set [_iTake, [_clName, _haveToTake-_canTake]];
								if ((_oldHave+_canTake) == _fullMagCount) then {
									if (_isManT) then {
										_target addMagazine _clName;
									} else {
										_target addMagazineCargoGlobal [_clName, 1];
									};
								};
								if (_haveToTake <= _leftToPut) then {
									if (_plC && _localC) then {
										_caller groupChat format ["Repacked '%1': %2 + %3 -> %4 (1 empty mag discarded)", _dispNm, _oldHave, _haveToTake, _oldHave + _canTake];
									};
								} else {
									if (_plC && _localC) then {
										_caller groupChat format ["Repacked '%1': %2 + %3 -> %4 + %5 (1 full mag repacked)", _dispNm, _oldHave, _haveToTake, _oldHave + _canTake, _haveToTake - _canTake];
									};
								};
								if ((_oldHave+_canTake) == _fullMagCount) then {
									_iPut = _iPut + 1;
								};
								if ((_haveToTake-_canTake) == 0) then {
									_iTake = _iTake - 1;
								};
								if (_plC && _localC) then {
									if (((animationState _caller) find "medic") == -1) then {
										if ((primaryWeapon _caller) != "") then {
											_caller switchMove "AinvPknlMstpSnonWrflDnon_medic0";
										} else {
											_caller switchMove "AinvPknlMstpSnonWnonDnon_medic";
										};
									};
								};
								if (!isNil "_pmtrm") then {
									if (_pmtrm > 0) then {
										sleep _pmtrm*(0.85+random(0.3));
									};
								};
								_haveSV = ([[ "pdth_mr_repack_cancelled", [true], [_target, _caller]]] call pdth_mr_check_stop_vars) || (_stopVars call pdth_mr_check_stop_vars)  || (_plC && (!alive _caller))
									|| (_plC && (((animationState _caller) find "medic") == -1))
									;
								if (_haveSV) then {
									_cancel = true;
									if (_plC && _localC) then {
										_caller groupChat "Repack cancelled.";
									};
									breakTo "roundwise";
								};
							};
							_var = _cancel && (_iPut < _iTake) && (((_mCounts select _iPut) select 1) < _fullMagCount);
							if (!_plC || (alive _caller)) then {
								if (!(isNull _gwhDisp)) then {
									deleteVehicle _gwhDisp;
									_gwhDisp = objNull;
								};
								for [{_i=_iPut}, {_i <= _iTake}, {_i = _i + 1}] do {
									if (((_mCounts select _i) select 1) > 0) then {
										if (_isManT) then {
											_target addMagazine [_clName, (_mCounts select _i) select 1];
										} else {
											_target addMagazineAmmoCargo [_clName, 1, (_mCounts select _i) select 1];
										};
									};
								};
							};
							if (_cancel) then {
								breakTo "repack";
							};
						}; // case "ROUNDWISE"
					};
				} forEach _nrMags;
				if (_plC && _localC && (alive _caller)) then {
					if (((animationState _caller) find "medic") != -1) then {
						_caller playMove "AinvPknlMstpSnonWrflDnon_medicEnd";
					};
				};
				if (!(isNil "_curMuz")) then {
					if (_plC && _localC && (alive _caller)) then {
						_caller selectWeapon _curMuz;
					};
				};
				if (!(isNull _gwhDisp)) then {
					if (_plC && (!alive _caller)) then {
						[_gwhDisp, true] remoteExec ["enableSimulationGlobal", 2];
						_gwhDisp setDamage 0;
					} else {
						deleteVehicle _gwhDisp;
						_gwhDisp = objNull; // not really neccessary
					};
				};
			}; // if (count _nrMags > 0)
		}; // if (count _mags > 0)
		if (_cancel) then {
			_var = _target call pdth_mr_has_repack;
			_target setVariable ["pdth_mr_repack_show_action", _var, !_localT];
		} else {
			if (_plC && _localC) then {
				_caller groupChat "Repack finished.";
			};
			_target setVariable ["pdth_mr_repack_show_action", false, !_localT];
		};
		_target setVariable ["pdth_mr_repack_runs", false, !_localT];
		if (_target != _caller) then {
			if (_nnC) then {
				_caller setVariable ["pdth_mr_repack_runs", false, !_localC];
			};
		};
		_target setVariable ["pdth_mr_repack_cancelled", false, !_localT];
		if (_target != _caller) then {
			if (_nnC) then {
				_caller setVariable ["pdth_mr_repack_cancelled", false, !_localC];
			};
		};
	};
};

/*
	AUTHOR: pedeathtrian
	NAME: pdth/mr/repack_misc.sqf
	VERSION: 0.0.2

	DESCRIPTION:
	This file is a part of pedeathtrian's magazine-repack "pdth/mr" bunch of scripts.
	This file contains functions performing different checks for showing/hiding repack and cancel repack actions.
	It also contains default (provided by author) initialization handler for "Respawn" event
	allowing to add "Repack magazines" and "Cancel repack" action for player itself.
*/

pdth_mr_deep_copy_w_replace = {
	/*
		Deep copy of input argument with optional replacements
		_this:
			Anything but Array: then we just return _this
			Array: [ _whatToCopy (,_repls) ]: return deep copy of _whatToCopy
				_whatToCopy:
					Anything but Array: if it isEqualTo any of _repls, then it is replaced
					Array:
						if it isEqualTo any of _replacements, then it is replaced
						if it is NOT isEqualTo any of _replacements, then array of deep copies w/ replacemets of its elements returned
				_repls: Array:
					[
						[replaceWhat, withWhat],
						...
					]
		Algorithm compares (using isEqualTo) current iterated item with replaceWhat and puts withWhat to copy, otherwise unchanged item placed into copy
		Usage:
			_replacements = [["foo", "bar"], ["baz", "qux"]]; // replace "foo" with "bar" and "baz" with "qux"
			_someCopy = [_someArray, _replacements] call pdth_mr_deep_copy_w_replace;
	*/
	private "_retValue";
	_retValue = nil;
	if (!(isNil "_this")) then {
		if ((typeName _this) == "ARRAY") then {
			if ((count _this) < 2) then {
				private "_sel0";
				_sel0 = _this select 0;
				if (!(isNil "_sel0")) then {
					if ((typeName _sel0) == "ARRAY") then {
						_retValue = +sel0;
					} else {
						_retValue = _sel0;
					};
				};
			} else {
				private ["_repls", "_replaceWhat"];
				_repls = [_this, 1, [], [[]]] call BIS_fnc_param;
				_replaceWhat = _this select 0;
				if (isNil "_replaceWhat") then {
					scopeName "nilSN";
					{
						if ((typeName _x) == "ARRAY") then {
							if ((count _x) > 1) then {
								private "_sel0";
								_sel0 = _x select 0;
								if (isNil "_sel0") then {
									private "_sel1";
									_sel1 = _x select 1;
									if (!(isNil "_sel1")) then {
										if ((typeName _sel1) == "ARRAY") then {
											_retValue = +_sel1;
										} else {
											_retValue = _sel1;
										};
									};
									breakTo "nilSN";
								};
							};
						};
					} forEach _repls;
				} else {
					private "_replaced";
					_replaced = false;
					if ((typeName _replaceWhat) == "ARRAY") then {
						scopeName "arraySN";
						{
							if ((typeName _x) == "ARRAY") then {
								if ((count _x) > 1) then {
									if (_replaceWhat isEqualTo (_x select 0)) then {
										if ((typeName (_x select 1)) == "ARRAY") then {
											_retValue = +(_x select 1);
										} else {
											_retValue = _x select 1;
										};
										_replaced = true;
										breakTo "arraySN";
									};
								};
							};
						} forEach _repls;
						if (!_replaced) then {
							_retValue = [];
							{
								_retValue pushBack ([_x, _repls] call pdth_mr_deep_copy_w_replace);
							} forEach _replaceWhat;
						};
					} else {
						scopeName "notArraySN";
						{
							if ((typeName _x) == "ARRAY") then {
								if ((count _x) > 1) then {
									if (_replaceWhat isEqualTo (_x select 0)) then {
										if ((typeName (_x select 1)) == "ARRAY") then {
											_retValue = +(_x select 1);
										} else {
											_retValue = _x select 1;
										};
										_replaced = true;
										breakTo "notArraySN";
									};
								};
							};
						} forEach _repls;
						if (!_replaced) then {
							_retValue = _replaceWhat;
						};
					};
				};
			};
		} else {
			_retValue = _this;
		};
	};
	_retValue
};

pdth_mr_check_stop_vars = {
	// return true if some stop vars are valid on passed dobjects
	// return false if repack can continue
	// _this: _stopVars array, see description for do_repack.sqf
	private "_result";
	_result = false;
	scopeName "csvSN";
	if (!(isNil "_this")) then {
		if ((typeName _this) == "ARRAY") then {
			{
				if ((typeName _x) == "ARRAY") then {
					private ["_varArr", "_name"];
					_varArr = _x;
					_name = _varArr select 0;
					if (!(isNil "_name")) then {
						if ((typeName _name) == "STRING") then {
							private "_objs";
							_objs = [_varArr, 2, [], [[]]] call BIS_fnc_param;
							if ((count _objs) > 0) then {
								private "_value";
								_value = _varArr select 1; // can be nil, so checking for variable not being set
								{
									private "_objVar";
									_objVar = _x getVariable [_name, nil];
									if (isNil "_value") then {
										if (isNil "_objVar") then {
											_result = true;
											breakTo "csvSN";
										};
									} else {
										if (!(isNil "_objVar")) then {
											if (_value isEqualTo _objVar) then {
												_result = true;
												breakTo "csvSN";
											};
										};
									};
								} forEach _objs;
							};
						};
					};
				};
			} forEach _this;
		};
	};
	_result
};

pdth_mr_check_repack_player = {
	/*
		Function checks if target object (player usually) is good to show repack action on.
		Object's inventory is not checked, and the function design is quite simple,
		so it's good to call it oneach frame, e.g. to give it as condition variable to addAction.

		If applied to object other than player, there could be less need to

		Arguments: _this is array:
			[_target, _caller]:
				_taget: object on which action is applied
				_caller: unit performing action

		Return: Boolean
	*/
	private ["_isUnconscious", "_runs", "_result", "_target", "_caller"];
	_result = false;
	_target = [_this, 0, objNull, [objNull]] call BIS_fnc_param;
	_caller = [_this, 1, objNull, [objNull]] call BIS_fnc_param;
	// fastest conditions to check go first, other will be short-circuited
	if ((!(isNull _target)) && (!(isNull _caller)) && (_caller == _target) && (vehicle _target == _target) && (!(captive _target))) then {
		_runs = _target getVariable ["pdth_mr_repack_runs", false];
		if (!_runs) then {
			// deal with revive system
			_isUnconscious = _caller getVariable ["AT_Revive_isUnconscious", false];
			if (!_isUnconscious) then {
				_result = _target getVariable ["pdth_mr_repack_show_action", false];
			};
		};
	};
	_result
};

pdth_mr_check_cancel_repack = {
	/*
		Function checks if target object (player usually) is good to show cancel repack action on.
		so it's good to call it oneach frame, e.g. to give it as condition variable to addAction.

		If applied to object other than player, there could be less need to

		Arguments: _this is array:
			[_target, _caller]:
				_taget: object on which action is applied
				_caller: unit performing action

		Return: Boolean
	*/
	private ["_result", "_target", "_caller"];
	_result = false;
	_target = [_this, 0, objNull, [objNull]] call BIS_fnc_param;
	_caller = [_this, 1, objNull, [objNull]] call BIS_fnc_param;
	// fastest conditions to check go first, other will be short-circuited
	if ((!(isNull _target)) && (!(isNull _caller)) && (_caller == _target) && (vehicle _target == _target) && (!(captive _target))) then {
		_result = _target getVariable ["pdth_mr_repack_runs", false] && (!(_caller getVariable ["AT_Revive_isUnconscious", false]));
	};
	_result
};

pdth_mr_var_updater = {
	private ["_target", "_var"];
	_target = [_this, 0, objNull, [objNull]] call BIS_fnc_param;
	if (!(isNull _target)) then {
		_var = _target call pdth_mr_has_repack;
		_target setVariable ["pdth_mr_repack_show_action", _var, true];
	};
};

pdth_mr_respawn_handler ={
	private ["_new", "_old", "_idAction"];
	_old = [_this, 1, objNull, [objNull]] call BIS_fnc_param;
	if (!(isNull _old)) then {
		_idAction = _old getVariable ["pdth_mr_action", -1];
		if (_idAction > 0) then {
			_old removeAction _idAction;
		};
	};

	_new = [_this, 0, objNull, [objNull]] call BIS_fnc_param;
	if (!(isNull _new)) then {
		//waitUntil {alive _new};
		_idAction = _new addAction [
			"<t color='#FFCC99'>Repack magazines</t>",
			{_this spawn pdth_mr_do_repack},
			[ // See pdth_mr_do_repack parameters description
				"ROUNDWISE",
				pdth_mr_stop_vars,
				[pdth_mr_time_repack_base, pdth_mr_time_repack_rw_round, pdth_mr_time_repack_rw_round_unload, pdth_mr_time_repack_rw_mag],
				[pdth_mr_anim_repack_start, pdth_mr_anim_repack_end]
			],
			1.5, false, true, "",
			"[_target, _this] call pdth_mr_check_repack_player"
		];
		_new setVariable ["pdth_mr_action", _idAction];

		_idAction = _new addAction [
			"<t color='#FF6644'>Cancel repack</t>",
			{_target setVariable ["pdth_mr_repack_cancelled", true]},
			[], 1.5, false, true, "",
			"[_target, _this] call pdth_mr_check_cancel_repack"
		];

		_new addEventHandler ["Put", pdth_mr_var_updater];
		_new addEventHandler ["Take", pdth_mr_var_updater];
		_new addEventHandler ["InventoryClosed", pdth_mr_var_updater];
		_new addEventHandler ["InventoryOpened", pdth_mr_var_updater];

		[_new] spawn {
			waitUntil {alive (_this select 0)};
			sleep 1;
			[_this select 0] call pdth_mr_var_updater;
		};
	};
};

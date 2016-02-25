AT_FNC_Revive_InitPlayer = {
	private["_init","_anotherPlayer", "_corpse"];
	_init = _this select 0;
	_corpse = _this select 1;
	player removeAllEventHandlers "HandleDamage";
	player removeAllEventHandlers "Killed";

	if(isNil("AT_Revive_WeaponsOnRespawn")) then {
		AT_Revive_WeaponsOnRespawn = true;
	};

	player addEventHandler ["HandleDamage", AT_FNC_Revive_HandleDamage];
	player addEventHandler
	[
		"Killed",
		{
			_body = _this select 0;
			[_body] spawn
			{
				waitUntil { alive player };
				_body = _this select 0;
				waitUntil { alive player && (!(_body in AT_Revive_HoldFromDelete)) };
				deleteVehicle _body;
			}
		}
	];

	player setVariable ["AT_Revive_isUnconscious", false, true];
	player setVariable ["AT_Revive_isDragged", objNull, true];
	player setVariable ["AT_Revive_isDragging", objNull, true];
	player setCaptive false;

	[] spawn AT_FNC_Revive_Actions;

	//systemchat "AT Revive started";
	if(!_init) then {
		//Player used respawn.. remove all his stuff and thread him like JIP
		if(AT_Revive_WeaponsOnRespawn) then {
			if (!isNil "_corpse") then {
				if (!isNull _corpse) then {
					if (!(_corpse in AT_Revive_HoldFromDelete)) then {
						AT_Revive_HoldFromDelete pushBack _corpse;
					};
					if (!(player in AT_Revive_HoldFromDelete)) then {
						AT_Revive_HoldFromDelete pushBack player;
					};
					[player, _corpse, true, false] spawn at_fnc_copyGear;
				};
			};
		} else {
			removeAllWeapons player;
			removeAllItems player;
			removeBackpack player;

			player unassignItem "ItemMap";
			player removeItem "ItemMap";
			player unassignItem "ItemCompass";
			player removeItem "ItemCompass";
			player unassignItem "itemGPS";
			player removeItem "itemGPS";
			player unassignItem "NVGoggles";
			player removeItem "NVGoggles";
		};

		if(count(AT_Revive_StaticRespawns)>0) then {
			player setpos getpos (AT_Revive_StaticRespawns select 0);
		};
		if(AT_Revive_Camera==1) then {
			[] spawn ATHSC_fnc_createCam;
		};
		//_anotherPlayer = (call drn_fnc_Escape_GetPlayers) select 0;
		//if (player == _anotherPlayer) then {
		//	_anotherPlayer = (call drn_fnc_Escape_GetPlayers) select 1;
		//};
		//_pos = [((getPos vehicle _anotherPlayer) select 0) + 3, ((getPos vehicle _anotherPlayer) select 1) + 3, 0];
		//player setpos _pos;


	};
};

AT_FNC_Revive_Actions = {
	if (alive player) then
	{
		player addAction ["<t size=""1.1"" color=""#C90000"">" + "Revive (with FAK)" + "</t>", "Revive\reviveAction.sqf", ["revivefak"], 19, true, true, "", "call AT_FNC_Revive_Check_Revive_FAK"];
		player addAction ["<t size=""1.1"" color=""#C90000"">" + "Revive" + "</t>", "Revive\reviveAction.sqf", ["revive"], 18, true, true, "", "call AT_FNC_Revive_Check_Revive"];
		player addAction ["<t size=""1.1"" color=""#FFA500"">" + "Drag" + "</t>", "Revive\reviveAction.sqf", ["drag"], 17, false, true, "", "call AT_FNC_Revive_Check_Dragging"];
		player addAction ["<t size=""1.1"" color=""#FFA500"">" + "Put in injured" + "</t>", "Revive\reviveAction.sqf", ["putin"], 17, false, true, "", "call AT_FNC_Revive_Check_Putin"];
		player addAction ["<t size=""1.1"" color=""#FFA500"">" + "Pull out injured" + "</t>", "Revive\reviveAction.sqf", ["pullout"], 17, false, true, "", "call AT_FNC_Revive_Check_Pullout"];
	};

};

AT_FNC_Revive_HandleDamage = {
	private ["_unit", "_killer", "_amountOfDamage", "_isUnconscious","_bodyPart","_projectile"];
	_unit = _this select 0;
	_bodyPart = _this select 1;
	_amountOfDamage = _this select 2;
	_killer = _this select 3;
	_projectile = _this select 4;
	_isUnconscious = _unit getVariable "AT_Revive_isUnconscious";

	if (alive _unit &&
		_amountOfDamage >= 1
		&& !(_isUnconscious)
		&& _bodyPart in ["","head","face_hub","head_hit","neck","spine1","spine2","spine3","pelvis","body"]) then
	{
		_unit setDammage 0;
		_unit allowDammage false;
		_amountOfDamage = 0;
		[_unit, _killer] spawn AT_FNC_Revive_Unconscious;
	};
	_amountOfDamage
};
AT_FNC_Revive_GlobalMsg =
{
	systemchat (_this select 0);
};

AT_FNC_Revive_Hide = {
	private["_unit","_hide"];
	_unit = _this select 0;
	_hide = _this select 1;
	//_unit enableSimulation !_hide;
	_unit hideObject _hide;
};
AT_FNC_Revive_Playmove = {
	private["_unit","_anim"];

	_unit = _this select 0;
	_anim = _this select 1;

	_unit playmovenow _anim;

};
AT_FNC_Revive_FixRotation= {
	private["_unit"];

	_unit = _this select 0;
	_unit setdir 180;

};
AT_FNC_Revive_Switchmove = {
	private["_unit","_anim"];

	_unit = _this select 0;
	_anim = _this select 1;

	_unit switchmove _anim;

};
AT_FNC_Revive_Unconscious =
{
	private["_unit", "_killer","_msg","_pos","_inVehicle"];
	_unit = _this select 0;
	_killer = _this select 1;
	_unit setVariable ["AT_Revive_isUnconscious", true, true];

	_msg = format["%1 is unconscious.",name _unit];
	[[_msg],"AT_FNC_Revive_GlobalMsg",true] call bis_fnc_MP;


	// Eject unit if inside vehicle
	/*while {vehicle _unit != _unit} do
	{
		unAssignVehicle _unit;
		_unit action ["eject", vehicle _unit];

		sleep 0.5;
	};*/
	_inVehicle = false;
	if(vehicle _unit == _unit) then {
		_ragdoll = [_unit] spawn at_fnc_revive_ragdoll;
		waituntil{scriptDone _ragdoll};
	} else {
		private["_vehicle","_EH"];
		_vehicle = vehicle _unit;
		if(getdammage _vehicle < 1) then {
			_inVehicle = true;
			[_unit] call AT_FNC_Revive_SwitchVehicleDeadAnimation;
		} else {
			moveOut _unit;
			_ragdoll = [_unit] spawn at_fnc_revive_ragdoll;
		};
	};

	// deal with dropping weapon on respawn
	private ["_prim", "_sec", "_hand", "_weapItems", "_pSet", "_sSet", "_hSet"];
	_prim = primaryWeapon _unit;
	_sec = secondaryWeapon _unit;
	_hand = handgunWeapon _unit;
	_pSet = (_prim == "");
	_sSet = (_sec == "");
	_hSet = (_hand == "");
	_weapItems = weaponsItems _unit;
	scopeName "_AT_FNC_Revive_Unconscious";
	if (!(_pSet && _sSet && _hSet)) then {
		{
			if ((!_pSet) && (_prim == (_x select 0))) then {
				_unit setVariable ["AT_Revive_primaryWeapon", _x];
				_pSet = true;
				if (_sSet && _hSet) then {
					breakTo "_AT_FNC_Revive_Unconscious";
				};
			};
			if ((!_sSet) && (_sec == (_x select 0))) then {
				_unit setVariable ["AT_Revive_secondaryWeapon", _x];
				_sSet = true;
				if (_pSet && _hSet) then {
					breakTo "_AT_FNC_Revive_Unconscious";
				};
			};
			if ((!_hSet) && (_hand == (_x select 0))) then {
				_unit setVariable ["AT_Revive_handgunWeapon", _x];
				_hSet = true;
				if (_pSet && _sSet) then {
					breakTo "_AT_FNC_Revive_Unconscious";
				};
			};
		} forEach _weapItems;
	};
	_weapItems = nil;

	// revealing after revive
	private "_knowledge";
	_knowledge = 1;
	if (!(isNil "_killer")) then {
		if (!(isNull _killer)) then {
			if (alive _killer) then {
				_knowledge = _killer knowsAbout _unit;
			};
		};
	};

	_unit setDamage 0.9;
	_unit setVelocity [0,0,0];
	_unit allowDammage false;
	_unit setCaptive true;
	if(surfaceIsWater getPos _unit && ((getPosASL _unit) select 2)>2 && (vehicle _unit != _unit)) then {
		[_unit] call AT_FNC_Revive_WashAshore;
	};

	if(AT_Revive_Camera==1) then {
		[] spawn ATHSC_fnc_createCam;
	};
	sleep 0.5;

	if(vehicle _unit == _unit) then {
		[[_unit,"AinjPpneMstpSnonWrflDnon"],"at_fnc_revive_switchMove",true] call BIS_fnc_MP;
	};
	_unit enableSimulation false;

	//_unit setVariable ["AT_Revive_isUnconscious", true, true];

	// Call this code only on players
	if (isPlayer _unit) then
	{

		while { !isNull _unit && alive _unit && (_unit getVariable "AT_Revive_isUnconscious")} do
		{
			if(vehicle _unit == _unit && _inVehicle) then {
				_inVehicle = false;
				_unit enableSimulation true;
				_ragdoll = [_unit] spawn at_fnc_revive_ragdoll;
				waituntil{scriptDone _ragdoll};
				sleep 0.25;
				_unit enableSimulation false;
			};
			if(vehicle _unit != _unit && !_inVehicle) then {
				_inVehicle = true;
				_unit enableSimulation true;
				[_unit] call AT_FNC_Revive_SwitchVehicleDeadAnimation;
				sleep 0.25;
				_unit enableSimulation false;
			};
			sleep 0.5;
		};
		_pos = getposATL _unit;

		// Player got revived
		//sleep 6;

		_unit enableSimulation true;
		_unit allowDamage true;
		_unit setCaptive false;

		// revealing
		if (!(isNil "_killer")) then {
			if (!(isNull _killer)) then {
				if (alive _killer) then {
					_killer reveal [_unit, _knowledge];
				};
			};
		};

		sleep 0.5;
		_unit setPosATL _pos; //Fix the stuck in the ground bug
	};
};

AT_FNC_Revive_SwitchVehicleDeadAnimation = {
	private["_interpolates"];
	_unit = [_this, 0] call BIS_fnc_param;
	if(vehicle _unit != _unit) then {
		_interpolates = [(configfile >> "CfgMovesMaleSdr" >> "States" >> animationState _unit),"interpolateTo",""] call BIS_fnc_returnConfigEntry;
		{
			if(typeName _x == "STRING") then {
				private["_stateAction"];
				if(configName (inheritsFrom (configfile >> "CfgMovesMaleSdr" >> "States" >> _x)) == "DefaultDie") then {
					[[_unit,_x],"at_fnc_revive_switchMove",true] call BIS_fnc_MP;
				};
			};
		} foreach _interpolates;
	};
};

AT_FNC_Revive_WatchVehicle = {
	private["_hnd"];
	_vehicle = [_this, 0] call BIS_fnc_param;
	_unit = [_this, 2] call BIS_fnc_param;
	if(local _unit && (_unit getVariable ["AT_Revive_isUnconscious",false])) then {
		_hnd = [_unit] spawn at_fnc_revive_ragdoll;
		waituntil{scriptDone _hnd};
		sleep 0.5;
		[[_unit,"AinjPpneMstpSnonWrflDnon"],"at_fnc_revive_switchMove",true] call BIS_fnc_MP;
	};
};

AT_FNC_Revive_HandleRevive =
{
	private["_attendant"];
	_target = [_this, 0, objNull] call BIS_fnc_param;
	_fakUsed = [_this, 1, false] call BIS_fnc_param;

	if (alive _target) then
	{
		if(primaryWeapon player != "") then {
			player playMove "AinvPknlMstpSlayWrflDnon_medic";
		} else {
			player playMove "AinvPknlMstpSnonWnonDnon_medic_1";
		};

		_target setVariable ["AT_Revive_isDragged", objNull, true];

		sleep 6;

		if(!(player getVariable ["AT_Revive_isUnconscious",false])) then {
			_target setVariable ["AT_Revive_isUnconscious", false, true];
			[[_target,"amovppnemstpsraswrfldnon"],"at_fnc_revive_playMove",true] call BIS_fnc_MP;

			if(AT_Revive_Camera==1) then {
				[[],"ATHSC_fnc_exit",_target] call BIS_fnc_MP;
			};

		};

		if (!isPlayer _target) then
		{
			_target enableSimulation true;
			_target allowDamage true;
			_target setCaptive false;
			[[_target,"amovppnemstpsraswrfldnon"],"at_fnc_revive_playMove",true] call BIS_fnc_MP;
		};

		_attendant = [(configfile >> "CfgVehicles" >> typeof player),"attendant",0] call BIS_fnc_returnConfigEntry;
		if(_attendant == 1 && ("Medikit" in items player)) then {
			_target setDamage 0;
		} else {
			if(_fakUsed && ("FirstAidKit" in items player)) then {
				_target setDamage 0;
				player removeItem "FirstAidKit";
			} else {
				_target setDamage (random 0.3)+0.1;
			};
		};
	};
};
AT_FNC_Revive_InstantRevive =
{
	private ["_target"];

	_target = _this select 0;
	_target enableSimulation true;
	_target allowDamage true;
	_target setDammage 0;
	_target setFatigue 0;
	_target setCaptive false;
	_target setVariable ["AT_Revive_isUnconscious", false, true];
	_target setVariable ["AT_Revive_isDragged", objNull, true];
	_target setVariable ["AT_Revive_isDragging",objNull,true];
	[[_target,""],"at_fnc_revive_switchMove",true] call BIS_fnc_MP;
};

AT_FNC_Revive_Drag =
{
	private ["_target", "_id"];

	_target = _this select 0;


	player setVariable ["AT_Revive_isDragging",_target,true];
	_target setVariable ["AT_Revive_isDragged",player,true];


	_target attachTo [player, [0, 1.1, 0.092]];
	_target setDir 180;

	[[_target],"AT_FNC_Revive_FixRotation",true] call BIS_fnc_MP;

	[[player,"AcinPknlMstpSrasWrflDnon"],"at_fnc_revive_switchMove",true] call BIS_fnc_MP;

	//player playMoveNow "AcinPknlMstpSrasWrflDnon";



	_id = player addAction ["<t color=""#FFA500"">" + "Release" + "</t>", "Revive\reviveAction.sqf", ["release"], 10, true, true, "", "true"];


	waitUntil
	{
		!alive player || (player getVariable "AT_Revive_isUnconscious") || !alive _target || !(_target getVariable "AT_Revive_isUnconscious") || isNull((player getVariable "AT_Revive_isDragging")) || isNull((_target getVariable "AT_Revive_isDragged"))
	};

	player setVariable ["AT_Revive_isDragging",objNull,true];

	if (!isNull _target && alive _target) then
	{
		[[_target,"AinjPpneMstpSnonWrflDnon"],"at_fnc_revive_switchMove",true] call BIS_fnc_MP;
		_target setVariable ["AT_Revive_isDragged", objNull, true];
		detach _target;
	};

	player removeAction _id;
};

AT_FNC_Revive_Release =
{

	[[player,"amovpknlmstpsraswrfldnon"],"at_fnc_revive_playMove",true] call BIS_fnc_MP;
	player setVariable ["AT_Revive_isDragging",objNull,true];

};
AT_FNC_Revive_AddVehicleWatchdog = {
	_vehicle = [_this, 0] call BIS_fnc_param;
	_EH = _vehicle getvariable ["AT_Revive_VehicleWatchdog",-1];
	if(_EH>=0) then {
		_EH = _vehicle addEventHandler ["GetOut", {_this spawn AT_FNC_Revive_WatchVehicle;}];
		_vehicle setvariable ["AT_Revive_VehicleWatchdog",_EH,false];
	};
};


AT_FNC_Revive_Check_Revive =
{
	private ["_target","_isPlayerUnconscious", "_isTargetUnconscious", "_isDragging", "_isDragged","_return"];

	_return = false;

	_isPlayerUnconscious = player getVariable "AT_Revive_isUnconscious";
	_isDragging = player getVariable "AT_Revive_isDragging";
	_target = cursorTarget;


	if( !alive player || _isPlayerUnconscious || !isNull(_isDragging) || isNil "_target" || !alive _target || (!isPlayer _target && !AT_Revive_Debug) || (_target distance player) > 2 ) exitWith
	{
		_return
	};

	_isTargetUnconscious = _target getVariable "AT_Revive_isUnconscious";
	_isDragged = _target getVariable "AT_Revive_isDragged";

	// Make sure target is unconscious and player is a medic
	if (_isTargetUnconscious && isNull(_isDragged)) then
	{
		_return = true;

	};

	_return
};
AT_FNC_Revive_Check_Revive_FAK =
{
	private["_return"];
	_return = [] call AT_FNC_Revive_Check_Revive;
	if(_return && ("FirstAidKit" in items player)) then {
		_return = true;
	} else {
		_return = false;
	};
	_return
};
AT_FNC_Revive_Check_Dragging =
{
	private ["_target","_isPlayerUnconscious", "_isTargetUnconscious", "_isDragging", "_isDragged","_return"];

	_return = false;
	_target = cursorTarget;
	_isPlayerUnconscious = player getVariable "AT_Revive_isUnconscious";
	_isDragging = player getVariable "AT_Revive_isDragging";

	if( !alive player || _isPlayerUnconscious || !isNull(_isDragging) || isNil "_target" || !alive _target || (!isPlayer _target && !AT_Revive_Debug) || (_target distance player) > 2 ) exitWith
	{
		_return;
	};

	// Target of the action
	_isTargetUnconscious = _target getVariable "AT_Revive_isUnconscious";
	_isDragged = _target getVariable "AT_Revive_isDragged";

	if(_isTargetUnconscious && isNull(_isDragged)) then
	{
		_return = true;
	};

	_return
};
AT_FNC_Revive_Check_Putin = {
	private["_vehicle","_isDragging","_freeCargoPositions","_return"];
	_vehicle = cursortarget;
	_isDragging = player getVariable ["AT_Revive_isDragging",false];
	_freeCargoPositions = _vehicle emptyPositions "cargo";
	_return = false;
	if(_freeCargoPositions >0 && !isNull(_isDragging)) then {
		_return = true;
	};
	_return
};

AT_FNC_Revive_Check_Pullout = {
	private["_vehicle","_isDragging","_freeCargoPositions","_return"];
	_vehicle = cursortarget;
	_return = false;
	{
		if((_x getVariable ["AT_Revive_isUnconscious",false]) && (_x != _vehicle)) exitwith {
			_return = true;
		};
	} foreach (crew _vehicle);
	_return
};

AT_FNC_Revive_PutInVehicle = {
	private["_vehicle","_isDragging","_freeCargoPositions"];
	_vehicle = cursortarget;
	_isDragging = player getVariable ["AT_Revive_isDragging",objNull];
	_freeCargoPositions = _vehicle emptyPositions "cargo";
	if(_freeCargoPositions>0 && !isNull(_isDragging)) then {
		[] call AT_FNC_Revive_Release;
		sleep 0.5;
		// requires A3 v1.50
		//[_isDragging,_vehicle] remoteExec ["AT_FNC_Revive_MoveInjuredInVehicle", _isDragging];
		//[_vehicle] remoteExec ["AT_FNC_Revive_AddVehicleWatchdog", 0];
		[[_isDragging,_vehicle], "AT_FNC_Revive_MoveInjuredInVehicle", _isDragging] call BIS_fnc_MP;
		[[_vehicle], "AT_FNC_Revive_AddVehicleWatchdog", 0] call BIS_fnc_MP;
	};
};
AT_FNC_Revive_MoveInjuredInVehicle = {
	_injured = [_this, 0] call BIS_fnc_param;
	_vehicle = [_this, 1] call BIS_fnc_param;
	_injured moveInCargo _vehicle;
};
AT_FNC_Revive_PullPutVehicle = {
private["_vehicle","_isDragging","_freeCargoPositions"];
	_vehicle = cursortarget;
	{
		if((_x getVariable ["AT_Revive_isUnconscious",false])) exitwith {
			moveout _x;
		};
	} foreach (crew _vehicle);
};

AT_FNC_Revive_Ragdoll = {
	private["_unit","_dummy","_state"];
	_unit = _this select 0;

	if(((eyepos _unit) select 2)>0.4) then {
		_group = createGroup (side _unit);
		[[_unit,true],"at_fnc_revive_hide",true] call BIS_fnc_MP;
		_dummy = _group createUnit [typeof _unit, [0,0,0], [], 0, "FORM"];
		if(!isNull _dummy) then {
			_dummy setPosASL getPosASL _unit;
			_dummy setDir getDir _unit;
			_dummy setVelocity velocity _unit;
			_state = animationState _unit;
			if (!(_unit in AT_Revive_HoldFromDelete)) then {
				AT_Revive_HoldFromDelete pushBack _unit;
			};
			AT_Revive_HoldFromDelete pushBack _dummy;
			[_dummy,_unit, true, true, false] spawn at_fnc_copyGear;
			[[_dummy,_state],"at_fnc_revive_switchMove",true] call BIS_fnc_MP;
			_dummy setDamage 1;
			if(_unit==player) then {
				_dummy switchCamera "Internal";
			};
			for[{_i=0},{_i<50},{_i=_i+1}] do {
				if(((_dummy selectionPosition "Neck") select 2)<0.2) then {
					_i = 50;
					sleep 0.5;
				};
				sleep 0.1;
			};

			[[_unit,false],"at_fnc_revive_hide",true] call BIS_fnc_MP;
			[[_unit,"AinjPpneMstpSnonWrflDnon"],"at_fnc_revive_switchMove",true] call BIS_fnc_MP;
			player switchCamera "Internal";
			_dummy setPos [0,0,0];
			_dummy spawn {
				waitUntil {!(_this in AT_Revive_HoldFromDelete)};
				deleteVehicle _this;
			};
		} else {
			[[_unit,"AinjPpneMstpSnonWrflDnon"],"at_fnc_revive_switchMove",true] call BIS_fnc_MP;
		};
	} else {
		[[_unit,"AinjPpneMstpSnonWrflDnon_rolltoback"],"at_fnc_revive_playMove",true] call BIS_fnc_MP;
	};
};

PDTH_FNC_CopyTypedCargo = {
	/*
		Added by pedeathtrian

		Usage: [dest,src(,types,keepAmmo,clear,global,spawn)] call PDTH_FNC_CopyTypedCargo
		Array of arguments:
			dest:	destination unit/cargospace (can be for example, vestContainer player)
			src:	source unit/cargospace
				Optional params:
			types:	bitwise mask of these flags:, default is 7 (1+2+4)
				0:	do nothing
				1:	copy items
				2:	copy magazines
				4:	copy weapons
			keepAmmo:	keep ammo count in magazines, ony used if 4 is in types, default is false
			clear:	clear dest container cargo of specified type before copy (e.g. call clearMagazineCargo for magazines), default is false
			global:	use global variants of functions where possible, default is true
			spawn:	use `spawn' call instead of `call' for typed subcalls; default is false; if `clear' is set to true, this parameter is false.
				The rationale for this is as follows. This method parses `types' parameter and calls/spawns itself for each separate type
				(if more than one, otherwise neither call nor spawn is used).
				Imagine situation. In source container you have some weapon with attachments and magazine.
				You call this method with clear=true and types=7 (items, magazines, weapons) and this methods spawns
				itself for each type. But now, every spawn is scheduled, so it can happen that weapon-typed spawn is finished before ammo-typed
				and item-typed. Since there's no way in ArmA to put weapon to container with attachments and magazine, it is being put separately.
				Then ammo- and item-typed spawns are executed with clear=true. They will delete your weapon's items and ammo wich put separately in container.
				This is also the reason why weapon-typed call is performed after (4>2>1) others when clear=true and spawn=false.
	*/
	private ["_contDest", "_contSrc", "_types", "_clear", "_global", "_spawn", "_keepAmmoCount", "_arr", "_subArr", "_i"];
	_contDest = [_this, 0, objNull, [objNull]] call BIS_fnc_param;
	_contSrc = [_this, 1, objNull, [objNull]] call BIS_fnc_param;
	_types = [_this, 2, 7, [0]] call BIS_fnc_param;
	_keepAmmoCount = [_this, 3, false, [true]] call BIS_fnc_param;
	_clear = [_this, 4, false, [true]] call BIS_fnc_param;
	_global = [_this, 5, true, [true]] call BIS_fnc_param;
	_spawn = [_this, 6, false, [true]] call BIS_fnc_param;
	if (_clear) then {
		_spawn = false;
	};

	scopeName "func_PDTH_FNC_CopyTypedCargo";
	if (isNull _contDest || isNull _contSrc || _contDest == _contSrc || _types == 0) then {
		breakOut "func_PDTH_FNC_CopyTypedCargo";
	};

	if (_types == 1) then {
		if (_clear) then {
			if (_global) then {
				clearItemCargoGlobal _contDest;
			} else {
				clearItemCargo _contDest;
			};
		};
		_arr = getItemCargo _contSrc;
		if(count _arr > 0) then {
			if (_global) then {
				{
					_contDest addItemCargoGlobal [_x, ((_arr) select 1) select _forEachIndex];
				} foreach ((_arr) select 0);
			} else {
				{
					_contDest addItemCargo [_x, ((_arr) select 1) select _forEachIndex];
				} foreach ((_arr) select 0);
			};
		};
	} else {
		if (_types == 2) then {
			if (_clear) then {
				if (_global) then {
					clearMagazineCargoGlobal _contDest;
				} else {
					clearMagazineCargo _contDest;
				};
			};
			if (_keepAmmoCount) then {
				_arr = magazinesAmmoCargo _contSrc;
				if(count(_arr)>0) then {
					{
						// addMagazineAmmoCargo is aG / eG commnad (and no local variant)
						_contDest addMagazineAmmoCargo [_x select 0, 1, _x select 1];
					} forEach _arr;
				};
			} else {
				_arr = getMagazineCargo _contSrc;
				if(count(_arr)>0) then {
					if (_global) then {
						{
							_contDest addMagazineCargoGlobal [_x, ((_arr) select 1) select _forEachIndex];
						} foreach ((_arr) select 0);
					} else {
						{
							_contDest addMagazineCargo [_x, ((_arr) select 1) select _forEachIndex];
						} foreach ((_arr) select 0);
					};
				};
			};
		} else {
			if (_types == 4) then {
				if (_clear) then {
					if (_global) then {
						clearWeaponCargoGlobal _contDest;
					} else {
						clearWeaponCargo _contDest;
					};
				};
				_arr = weaponsItemsCargo _contSrc;
				if(count _arr > 0) then {
					{
						_subArr = _x;
						if (count _subArr > 0) then {
							if (_global) then {
								{
									if (typeName _x == "STRING") then {
										_contDest addItemCargoGlobal [_x, 1];
									} else {
										if (typeName _x == "ARRAY") then {
											// addMagazineAmmoCargo is aG / eG commnad (and no local variant)
											_contDest addMagazineAmmoCargo _x;
										};
									};
								} forEach  _subArr;
							} else {
								{
									if (typeName _x == "STRING") then {
										_contDest addItemCargo [_x, 1];
									} else {
										if (typeName _x == "ARRAY") then {
											_contDest addMagazineAmmoCargo _x;
										};
									};
								} forEach  _subArr;
							};
						};
					} forEach _arr;
				};
			} else {
				if ((_types % 2) == 1) then {
					if (_spawn) then {
						[_contDest, _contSrc, 1, _keepAmmoCount, _clear, _global] spawn PDTH_FNC_CopyTypedCargo;
					} else {
						[_contDest, _contSrc, 1, _keepAmmoCount, _clear, _global] call PDTH_FNC_CopyTypedCargo;
					};
				};
				_types = floor(_types / 2);
				if ((_types % 2) == 1) then {
					if (_spawn) then {
						[_contDest, _contSrc, 2, _keepAmmoCount, _clear, _global] spawn PDTH_FNC_CopyTypedCargo;
					} else {
						[_contDest, _contSrc, 2, _keepAmmoCount, _clear, _global] call PDTH_FNC_CopyTypedCargo;
					};
				};
				_types = floor(_types / 2);
				if ((_types % 2) == 1) then {
					if (_spawn) then {
						[_contDest, _contSrc, 4, _keepAmmoCount, _clear, _global] spawn PDTH_FNC_CopyTypedCargo;
					} else {
						[_contDest, _contSrc, 4, _keepAmmoCount, _clear, _global] call PDTH_FNC_CopyTypedCargo;
					};
				};
			};
		};
	};
};

AT_FNC_CopyGear = {
	private["_u1","_u2", "_d1", "_d2","_weapons","_assigned_items","_primary", "_secondary", "_handgun", "_addedP", "_addedS", "_addedH","_wName","_i","_keep_ammocount", "_iCount", "_var", "_storedWeaps"];

	_u1 = [_this,0,objNull,[objNull]] call bis_fnc_param;
	_u2 = [_this,1,objNull,[objNull]] call bis_fnc_param;
	_keep_ammocount = [_this,2,false,[true]] call bis_fnc_param;
	_d1 = [_this,3,true,[true]] call bis_fnc_param;
	_d2 = [_this,4,true,[true]] call bis_fnc_param;

	if (isNull _u1) exitwith {
		["Missing first parameter for gear copy!"] call BIS_fnc_error;
	};
	if (isNull _u2) exitwith {
		["Missing second parameter for gear copy!"] call BIS_fnc_error;
	};
	_primary = primaryWeapon _u2;
	_secondary = secondaryWeapon _u2;
	_handgun = handgunWeapon _u2;
	_weapons = weaponsItems _u2;
	_addedP = (_primary == "");
	_addedS = (_secondary == "");
	_addedH = (_handgun == "");
	_storedWeaps = [];
	if (_addedP) then {
		_var = _u2 getVariable "AT_Revive_primaryWeapon";
		if (!(isNil "_var")) then {
			_storedWeaps pushBack _var;
			_primary = _var select 0;
			_addedP = false;
		};
		_var = nil;
	};
	if (_addedS) then {
		_var = _u2 getVariable "AT_Revive_secondaryWeapon";
		if (!(isNil "_var")) then {
			_storedWeaps pushBack _var;
			_secondary = _var select 0;
			_addedS = false;
		};
		_var = nil;
	};
	if (_addedH) then {
		_var = _u2 getVariable "AT_Revive_handgunWeapon";
		if (!(isNil "_var")) then {
			_storedWeaps pushBack _var;
			_handgun = _var select 0;
			_addedH = false;
		};
		_var = nil;
	};
	if ((count _storedWeaps) > 0) then {
		_weapons = _storedWeaps + _weapons;
	};
	_storedWeaps = nil;

	removeAllAssignedItems _u1;
	removeAllContainers _u1;
	removeAllWeapons _u1;
	removeHeadgear _u1;

	if((headgear _u2)!="") then {
		_u1 addHeadgear (headgear _u2);
	};
	removeGoggles _u1;
	if((goggles _u2)!="") then {
		_u1 addGoggles (goggles _u2);
	};
	if((uniform _u2)!="") then {
		_u1 addUniform(uniform _u2);
	};
	if((vest _u2)!="") then {
		_u1 addVest (vest _u2);
	};
	if((backpack _u2)!="") then {
		// some backpacks spawned with some items already contained
		_u1 addBackpack ((backpack _u2) call BIS_fnc_basicBackpack);
	};

	{
		_u1 linkItem _x;
	} foreach (assignedItems _u2);

	// adding weapons stored in uniform, vest and backpack containers
	{
		private ["_dstCont", "_srcCont", "_weapList"];
		_dstCont = [_x, 0, objNull, [objNull]] call BIS_fnc_param;
		_srcCont = [_x, 1, objNull, [objNull]] call BIS_fnc_param;
		if (!(isNull _dstCont || isNull _srcCont)) then {
			_weapList = weaponsItemsCargo _srcCont;
			{
				private ["_weap", "_itms"];
				_itms = _x;
				_weap = [_itms select 0] call BIS_fnc_baseWeapon;
				_u1 addWeapon _weap;
				for [{_i=1}, {_i < (count _itms)}, {_i=_i+1}] do {
					_u1 addWeaponItem [_weap, _itms select _i];
				};
				_u1 action ["DropWeapon", _dstCont, _weap];
				waitUntil {((primaryWeapon _u1) == "") && ((secondaryWeapon _u1) == "") && ((handgunWeapon _u1) == "")};
			} forEach _weapList;
		};
	} forEach [
		[uniformContainer _u1, uniformContainer _u2],
		[vestContainer _u1, vestContainer _u2],
		[backpackContainer _u1, backpackContainer _u2]
	];

	scopeName "_AT_FNC_CopyGear";
	if (!(_addedS && _addedP && _addedH)) then {
		{ // foreach _weapons;
			private ["_itms", "_baseWeap"];
			_itms = _x;
			_wName = (_itms select 0);
			_baseWeap = [_wName] call BIS_fnc_baseWeapon;
			_iCount = count _itms;
			switch _wName do {
				case _primary: {
					if (!_addedP) then {
						_u1 addWeapon _baseWeap;
						for [{_i=1}, {_i < _iCount}, {_i=_i+1}] do {
							_u1 addWeaponItem [_baseWeap, _itms select _i];
						};
						_addedP = true;
						if (_addedH && _addedS) then {
							breakTo "_AT_FNC_CopyGear";
						};
					};
				};
				case _secondary: {
					if (!_addedS) then {
						_u1 addWeapon _baseWeap;
						for [{_i=1}, {_i < _iCount}, {_i=_i+1}] do {
							_u1 addWeaponItem [_baseWeap, _itms select _i];
						};
						_addedS = true;
						if (_addedH && _addedP) then {
							breakTo "_AT_FNC_CopyGear";
						};
					};
				};
				case _handgun: {
					if (!_addedH) then {
						_u1 addWeapon _baseWeap;
						for [{_i=1}, {_i < _iCount}, {_i=_i+1}] do {
							_u1 addWeaponItem [_baseWeap, _itms select _i];
						};
						_addedH = true;
						if (_addedS && _addedP) then {
							breakTo "_AT_FNC_CopyGear";
						};
					};
				};
			};
		} foreach _weapons;
	};

	[uniformContainer _u1, uniformContainer _u2, 3, _keep_ammocount] call PDTH_FNC_CopyTypedCargo;
	[vestContainer _u1, vestContainer _u2, 3, _keep_ammocount] call PDTH_FNC_CopyTypedCargo;
	[backpackContainer _u1, backpackContainer _u2, 3, _keep_ammocount] call PDTH_FNC_CopyTypedCargo;

	private "_curMuz";
	_curMuz = currentMuzzle _u2;
	if ((typeName _curMuz) == "STRING") then {
		_u1 selectWeapon _curMuz;
	};
	//_zeroing = currentZeroing _u2;
	//weaponState player;

	if (_d1) then {
		AT_Revive_HoldFromDelete = AT_Revive_HoldFromDelete - [_u1];
	};
	if (_d2) then {
		AT_Revive_HoldFromDelete = AT_Revive_HoldFromDelete - [_u2];
	};
};

//AT_FNC_Revive_WashAshore = {
//	_player = [_this, 0, objNull] call BIS_fnc_param;
//	_center = SouthWest vectorAdd (NorthEast vectordiff SouthWest);
//	_radius = 10;
//	_wpos = [];
//	while{count(_wpos)<3 && (_player getVariable "AT_Revive_isUnconscious")} do {
//		_wpos = (position _player) findEmptyPosition [0,_radius];
//		if(count(_wpos)==3) then {
//			_wpos = _wpos isFlatEmpty [1, 0, 0.5, 1, 1, true, _player];
//		};
//		systemchat format["Checking %1 m (%2)",_radius,_wpos];
//		_radius = _radius + 10;
//		sleep 0.1;
//	};
//	if((_player getVariable "AT_Revive_isUnconscious")) then {
//		_player setpos _wpos;
//		_msg = format["%1 body washed ashore.",name _player];
//		[[_msg],"AT_FNC_Revive_GlobalMsg",true] call bis_fnc_MP;
//	};

//};
AT_FNC_Revive_WashAshore = {
	private["_unit","_center","_pos","_distance","_vec","_found","_npos"];

	_unit = [_this, 0] call BIS_fnc_param;

	_center = (position SouthWest) vectorAdd ((position NorthEast) vectordiff (position SouthWest));
	_pos = getpos _unit;
	_distance = _unit distance _center;
	_vec = [((_center select 0)-(_pos select 0))/_distance,((_center select 1)-(_pos select 1))/_distance];
	_found = false;

	for[{_i = 0},{_i<=_distance && !_found},{_i=_i+1}] do {
		_npos = [((_pos select 0)+(_vec select 0)*_i),((_pos select 1)+(_vec select 1)*_i) ,0];
		if(!(surfaceIsWater _npos)) then {
			_found = true;
			_pos = _npos;
		}
	};
	if(_found) then {
		sleep 1;
		if(_unit == player) then {
            titleText ["", "BLACK",1];
        };
		sleep 1;
		_unit setpos _pos;
		_msg = format["%1's body washed ashore.",name _unit];
		[[_msg],"AT_FNC_Revive_GlobalMsg",true] call bis_fnc_MP;
		sleep 1;
	    if(_unit == player) then {
			titleFadeOut 1;
	    };
	} else {
		systemchat "Can't find dry land.";
	};
};

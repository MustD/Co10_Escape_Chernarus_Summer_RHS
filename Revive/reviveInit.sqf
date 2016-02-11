call compile preprocessFile "Revive\reviveFunctions.sqf";
call compile preprocessFile "Revive\hscFunctions.sqf";

AT_Revive_StaticRespawns = [];
AT_Revive_enableRespawn = false;
AT_Revive_clearedDistance = 0;
AT_Revive_Camera = 0;

// hold objects in this array from deleting by deleteVehicle: can be useful for spawned copyGear
AT_Revive_HoldFromDelete = [];
// if set to false, then when player selects respawn, he will be spawned without weapons and items
// if set to true or undefined, player respawned with latest gear
//AT_Revive_WeaponsOnRespawn = false;

if(isNil("AT_Revive_StaticRespawns")) then {
	AT_Revive_enableRespawn = true;
};


AT_Revive_Debug = false;
[] spawn
{
    waitUntil {!isNull player};

	[true, objNull] spawn AT_FNC_Revive_InitPlayer;


	player addEventHandler
	[
		"Respawn",
		{
			[false, _this select 1] spawn AT_FNC_Revive_InitPlayer;
		}
	];
};


if (!AT_Revive_Debug || isMultiplayer) exitWith {};

{
	if (!isPlayer _x) then
	{
		_x addEventHandler ["HandleDamage", AT_FNC_Revive_HandleDamage];
		_x setVariable ["AT_Revive_isUnconscious", false, true];
		_x setVariable ["AT_Revive_isDragged", objNull, true];
		_x setVariable ["AT_Revive_isDragging", objNull, true];
	};
} forEach switchableUnits;

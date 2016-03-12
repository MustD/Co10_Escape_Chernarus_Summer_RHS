params [["_group", grpNull,[grpNull]], ["_position", [0,0,0], [[]], [2,3]], ["_type", "MOVE", [""]],
	["_formation", "COLUMN", [""]], ["_speed", "LIMITED", [""]], ["_combatmode", "SAFE", [""]],
	["_onComplete", "", [""]]];
private["_script","_marker","_markername"];

if(a3e_debug_EnemyPosition) then {
	_script = _group getvariable "a3e_debug_positionScript";
	if(isNil("_script")) then {
		_script = [_group] spawn a3e_fnc_TrackGroup;
		_group setvariable ["a3e_debug_positionScript",_script,false];
	};
};
if(a3e_debug_Waypoints) then {
	_marker = _group getvariable ["a3e_debug_moveMarker","noMarker"];
	if(_marker == "noMarker") then {
		_marker = [getpos ((units _group) select 0),_position] call a3e_fnc_drawMapLine;
		_group setvariable ["a3e_debug_moveMarker",_marker,false];
	} else {
		[getpos leader _group,_position,_marker] call a3e_fnc_drawMapLine;
	};
};

if(count (waypoints _group) <= 1) then {
	_group addWaypoint [[0,0,0], 1];
};


[_group, 1] setWaypointPosition [_position, 1];
[_group, 1] setWaypointBehaviour _combatmode;
[_group, 1] setWaypointSpeed _speed;
[_group, 1] setWaypointFormation _formation;
[_group, 1] setWaypointType _type;
[_group, 1] setWaypointCompletionRadius 10;
[_group, 1] setWaypointStatements ["true", _onComplete];
_group setCurrentWaypoint [_group, 1];
//Return Waypoint
[_group, 1];

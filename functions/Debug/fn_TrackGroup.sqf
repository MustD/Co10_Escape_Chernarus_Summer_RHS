params [["_group", grpNull, [grpNull]]];
private["_startpos","_endpos","_marker","_width","_length","_distanceY","_distanceX","_markername","_rotation","_text"];

_marker = _group getVariable "a3e_debug_positionMarker";
if(isNil("_marker")) then {
	_markername = format["a3e_debug_positionMarker_%1",_group];
	_marker = createMarker [_markername,getposASL (leader _group)];
	_marker setMarkerShape "ICON";
	_marker setMarkerType "mil_dot";
	_marker setMarkerColor ([side leader _group] call a3e_fnc_getSideColor);
	_group setVariable ["a3e_debug_positionMarker",_marker,false];
};

while{!(isNull _group)} do {
	_marker setMarkerPos getPosATL (leader _group);
	_text = [_group] call a3e_fnc_GetTaskState;
	_marker setMarkerText _text;
	if(count (units _group) == 0) exitWith {_marker setMarkerText "KIA";sleep 30;};
	sleep 5;
};
_group setVariable ["a3e_debug_positionMarker",nil,false];
deleteMarker _marker;

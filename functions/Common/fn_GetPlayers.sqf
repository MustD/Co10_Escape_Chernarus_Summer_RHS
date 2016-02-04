private["_list"];
//_modifier = [_this, 0, 1] call BIS_fnc_param;
_list = [];
//if (requiredVersion "1.48") then {
//	_list = allPlayers;
//} else {
	_list = [] call BIS_fnc_listPlayers;
//};
_list;

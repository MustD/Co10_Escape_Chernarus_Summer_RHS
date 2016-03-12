/*
	Author: Karel Moricky
	Edited by NeoArmageddon

	Description:
	Set time of the day

	Parameter(s):
	NUMBER - hour

	Returns:
	ARRAY - date
*/
params [["_hour", daytime,[0]], ["_date", date, [[]], [3,4,5]]];
if(_hour==24) then {
	_hour = round(random(24));
};
_date set [3,_hour];
[_date] call bis_fnc_setDate;
_date

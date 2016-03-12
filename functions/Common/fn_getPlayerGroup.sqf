private["_group"];

if(isMultiplayer) then {
	_group = grpNull;
	{
		if((isPlayer _x)) exitwith {
			_group = group _x;
		};
	} foreach playableUnits;
} else {
	_group = group player;
};

_group

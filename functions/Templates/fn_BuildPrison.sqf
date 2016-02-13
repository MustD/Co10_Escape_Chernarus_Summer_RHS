private ["_centerPos", "_rotateDir"];
private ["_object", "_pos", "_dir"];
private ["_i", "_j", "_k", "_cpx", "_cpy"];

_centerPos = _this select 0;
_rotateDir = _this select 1;

_cpx = _centerPos select 0;
_cpy = _centerPos select 1;

//_dir = _rotateDir;
for [{_i = 0}, {_i < 2}, {_i = _i + 1}] do {
	for [{_j = 0}, {_j < 2}, {_j = _j + 1}] do {
		_dir = _rotateDir + _j*180 - _i*90 + 90;
		for [{_k = 0}, {_k < 3}, {_k = _k + 1}] do {
			//_pos = [_cpx + _i*(-6 + _j*12) + _j*(-4 + _k*4), _cpy + _j*(-6 + _i*12) + _i*(-4 + _k*4), 0];
			_pos = [_cpx + (1-_i)*(-6 + _j*12) + _i*(-4 + _k*4), _cpy + (_i)*(-6 + _j*12) + (1-_i)*(-4 + _k*4), 0];
			diag_log format ["[i, j, k] = [%1, %2, %3]; relative pos = [%4, %5]; dir = %6", _i, _j, _k, (1-_i)*(-6 + _j*12) + _i*(-4 + _k*4), (_i)*(-6 + _i*12) + (1-_i)*(-4 + _k*4), _dir];
			if (_i != 1 || _j != 1 || _k != 2) then { // filtering last wall segment for gate
				//_object = "Land_Wall_Tin_4" createVehicle _pos;
				_object = createVehicle ["Land_Wall_Tin_4", _pos, [], 0, "NONE"];
			} else {
				//_object = "Land_City_Gate_F" createVehicle _pos;
				_object = createVehicle ["Land_City_Gate_F", _pos, [], 0, "NONE"];
				A3E_PrisonGateObject = _object;
			};
			_object setPos ([_centerPos, _pos, _rotateDir] call a3e_fnc_RotatePosition);
			_object setDir _dir;
		};
	};
};

// Tunnor

_dir = 90 + _rotateDir;

_pos = [(_centerPos select 0) + 7, (_centerPos select 1) + 5, 0];
//_object = "MetalBarrel_burning_F" createVehicle _pos;
_object = createVehicle ["MetalBarrel_burning_F", _pos, [], 0, "NONE"];
_object setPos ([_centerPos, _pos, _rotateDir] call a3e_fnc_RotatePosition);
_object setDir _dir;

_pos = [(_centerPos select 0) - 5, (_centerPos select 1) + 7, 0];
//_object = "MetalBarrel_burning_F" createVehicle _pos;
_object = createVehicle ["Land_Loudspeakers_F", _pos, [], 0, "NONE"];
_object setPos ([_centerPos, _pos, _rotateDir] call a3e_fnc_RotatePosition);
_object setDir _dir;

A3E_PrisonLoudspeakerObject = _object;
publicvariable "A3E_PrisonLoudspeakerObject";

// Flag
//_dir = 90 + _rotateDir;
_pos = [(_centerPos select 0) - 7, (_centerPos select 1) - 5, 0];
//_object = "Flag_AAD_F" createVehicle _pos;
_object = createVehicle ["Flag_AAF_F", _pos, [], 0, "NONE"];
_object setPos ([_centerPos, _pos, _rotateDir] call a3e_fnc_RotatePosition);
_object setDir _dir;

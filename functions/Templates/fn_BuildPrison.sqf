private ["_centerPos", "_rotateDir"];
private ["_object", "_pos", "_dir"];
private ["_i", "_j", "_k", "_cpx", "_cpy", "_cpz", "_x", "_y", "_z", "_prMaterials", "_prMaterial", "_rotPos"];

_centerPos = _this select 0;
_rotateDir = _this select 1;

_cpx = [_centerPos, 0, 0, [0]] call BIS_fnc_param;
_cpy = [_centerPos, 1, 0, [0]] call BIS_fnc_param;
_cpz = getTerrainHeightASL _centerPos;

/**	(switch to monospace)

	+--+    1       2           +--+  _prMaterials: Array: [ prisonMaterialsSet1 (, prisonMaterialsSet2, ...)]
	| 3||======||------||======|| 3|      prisonMaterialsSet1: Array: [ wallElement, gateElement (, cornerElement) ]
	+--+                        +--+          wallElement: Array: [ className, numPerSide, length (,width(,pillar(,zOffset)))]
	 --                          --               className: String: CfgVehicles classname to construct wall segment,
	 ||    1 - wall element      ||                 e.g. "Land_Wall_Tin_4", "Land_City_4m_F", "Land_City2_4m_F", ...
	 ||    2 - gate              ||               numPerSide: Number: of elements per prison side. Prison side is calculated using this value.
	 --    3 - corner            --               length: Number: effective linear size of element.
	 --                          --               width: Number: wall thickness.
	 ||                          ||               pillar: Number: defines whether wall element has builtin pillar.
	 ||                          ||                 If no cornerElement specified wall side starts on corner and
	 --                          --                 end before side end, leaving space for next side start element's pillar.
	 --                          --                 If wall element has builtin pillar on its end, it can be useful to start
	 ||                          ||                 wall side leaving space for previous side end pillar, and end leaving no
	 ||                          ||                 space for next side start pillar. To do so, define pillar to be:
	 --                          --                    1: wall element has pillar on its start;
	+--+                        +--+                   2: wall element has pillar on its end.
	|  ||======||======||======||  |                   0 is default value meaning no builtin pillar
	+--+                        +--+                Builtin pillar size is considered equal to wall width.
	                                              zOffset: Number: if set, all wall segments will be leveled to _centerPos z coordinate + zOffset.

	        gateElement: Array: [ className, length (,transverseOffset (,lengthwiseOffset)) ]
	            className: String: same meaning as for wallElement.
	            length: Number: same meaning as for wallElement.
	            transverseOffset: Number: some gate elements are not well-aligned against the wall axis.
	              Set this to negative to move gate inside prison, positive for outside.
	              Default is 0.
	            lengthwiseOffset: Number: Move gate for this distance along the wall axis.
	              Set this to negative to move gate towards beginning of the wall side, positive towards the wall side end.

	        cornerElement: Array: [className, length, zOffset]
	            className: String: same meaning as for wallElement.
	            length: Number: defines both width and length of element (i.e. must be squared).
	            zOffset: Number: same as for wall elements.

	Prison walls are built in clockwise direction. Default gate position is in the middle of the prison wall side.
	Corner elements are optional and can be omitted. In this case wall side starts exactly on corner, unless you
	specified wall element with builtin pillar on its end, in which case wall side ends on corner position and starts
	with offset from previous corner position. Offset size depends on wall element width.
**/
_prMaterials = [
	[["Land_Wall_Tin_4", 3, 4], ["Land_City_Gate_F", 4]], // default
	[["Fence_corrugated_plate", 3, 4], ["Land_City_Gate_F", 4]], // almost same as default
	[["Wall1", 4, 2.5, 0.5], ["Land_City_Gate_F", 4], ["", -0.5]], // pseudo pillar allowing wall overlap in corners
	[["Land_Wall_Tin_4", 3, 4], ["Land_City_Gate_F", 4], ["Land_Wall_Tin_Pole"]], // with poles in corners
	[["Land_City_Pillar_F", 26, 0.45, 0.45, 0, 0], ["Land_City_Gate_F", 4], ["Land_City_Pillar_F", 0.45, 0]], // whole prison wall built of pillars
	[["Land_City2_4m_F", 3, 3.5, 0.45, 2, 0.6], ["Land_City_Gate_F", 4]],
	[["Land_City_4m_F", 3, 3.5, 0.45, 1, 0.6], ["Land_City_Gate_F", 4]],
	[["Land_Stone_4m_F", 3, 3.5, 0.5], ["Land_Stone_Gate_F", 4], ["Land_Stone_pillar_F", 0.5]]
];

private ["_wallElem", "_wallElNm", "_elems", "_wallElLn", "_wallElWd", "_wallElPl", "_wallZOff"];
private ["_gateElem", "_gateElNm", "_gateElLn", "_gateElTO", "_gateElLO"];
private ["_crnrElem", "_crnrElNm", "_crnrElLn"];
_prMaterial = _prMaterials call BIS_fnc_selectRandom;

_wallElem = [_prMaterial, 0, [], [[]], [3,4,5,6]] call BIS_fnc_param;
_wallElNm = [_wallElem, 0, "Land_Wall_Tin_4", [""]] call BIS_fnc_param;
_elems    = [_wallElem, 1, 3, [0]] call BIS_fnc_param;
_wallElLn = [_wallElem, 2, 4, [0]] call BIS_fnc_param;
_wallElWd = [_wallElem, 3, 0, [0]] call BIS_fnc_param;
_wallElPl = [_wallElem, 4, 0, [0]] call BIS_fnc_param;
_wallZOff = [_wallElem, 5, -666, [0]] call BIS_fnc_param;
if (_wallZOff == -666) then {
	_wallZOff = nil;
};

_gateElem = [_prMaterial, 1, [], [[]], [2,3,4]] call BIS_fnc_param;
_gateElNm = [_gateElem, 0, "Land_City_Gate_F", [""]] call BIS_fnc_param;
_gateElLn = [_gateElem, 1, 4, [0]] call BIS_fnc_param;
_gateElTO = [_gateElem, 2, 0, [0]] call BIS_fnc_param;
_gateElLO = [_gateElem, 3, 0, [0]] call BIS_fnc_param;

_crnrElem = [_prMaterial, 2, [], [[]], [2]] call BIS_fnc_param;
_crnrElNm = [_crnrElem, 0, "", [""]] call BIS_fnc_param;
_crnrElLn = [_crnrElem, 1, 0, [0]] call BIS_fnc_param;
_crnrZOff = [_crnrElem, 2, 0, [0]] call BIS_fnc_param;

private ["_stepSign", "_BIPillarOffset", "_wallStartOffset"];
_BIPillarOffset = 0;
// explicitly specified corner element overrides builtin pillar
if (_crnrElLn == 0) then {
	if (_wallElPl == 1) then {
		_BIPillarOffset = -_wallElWd / 2;
	} else {
		if (_wallElPl == 2) then {
			_BIPillarOffset = _wallElWd / 2;
		};
	};
};
_wallStartOffset = (_elems*_wallElLn+_crnrElLn)/2;

/* walls are numbered as follows: (_i, _j):
       (1, 1)
(0, 0)        (0, 1)
       (1, 0)
*/
// now da magik kicks in
for [{_i = 0}, {_i < 2}, {_i = _i + 1}] do {
	for [{_j = 0}, {_j < 2}, {_j = _j + 1}] do {
		_dir = _rotateDir + _j*180 - _i*90 + 90;
		_stepSign = if (_i == _j) then {1} else {-1};
		if (_crnrElNm != "") then {
			_x = -_stepSign*_wallStartOffset;
			_y = _wallStartOffset * (_j*2-1);
			_pos = _centerPos vectorAdd ([[0,0,0], [_x, _y, 0], _rotateDir] call a3e_fnc_RotatePosition);
			_object = createVehicle [_crnrElNm, _pos, [], 0, "CAN_COLLIDE"];
			if (isNil "_crnrZOff") then {
				_z = getTerrainHeightASL _pos;
			} else {
				_z = _cpz+_crnrZOff;
			};
			_pos set [2, _z];
			_object setPosASL _pos;
			_object setDir _dir;
		};
		if (_i == 1 && _j == 1) then {
			// wall with gates
			// now filling the gaps before...
			private ["_freeSpace", "_addEls", "_step"];
			_freeSpace = _wallStartOffset-_BIPillarOffset-((abs(_crnrElLn))+_gateElLn)/2 + _gateElLO;
			_addEls = ceil (_freeSpace / _wallElLn);
			_step = _freeSpace / _addEls; // can be less than _wallElLn
			if (_addEls == 1) then {
				_step = _wallElLn;
			};
			for [{_k = 0}, {_k < _addEls}, {_k = _k + 1}] do {
				private ["_placeX", "_critX"];
				_critX = - _wallStartOffset + (_wallElLn - _wallElWd)/2;
				_placeX = - _wallStartOffset + _BIPillarOffset + ((abs(_crnrElLn))+_step)/2 + _k*_step;
				if (_placeX < _critX) then {
					_placeX = _critX;
				};
				_critX = _BIPillarOffset - ((abs(_crnrElLn))+_wallElLn+_gateElLn)/2 + _gateElLO;
				if (_placeX > _critX) then {
					_placeX = _critX;
				};
				_pos = _centerPos vectorAdd ([[0,0,0], [_placeX, _wallStartOffset, 0], _rotateDir] call a3e_fnc_RotatePosition);
				_object = createVehicle [_wallElNm, _pos, [], 0, "CAN_COLLIDE"];
				if (isNil "_wallZOff") then {
					_z = getTerrainHeightASL _pos;
				} else {
					_z = _cpz+_wallZOff;
				};
				_pos set [2, _z];
				_object setPosASL _pos;
				if (_wallElLn == _wallElWd) then {
					_object setDir (_dir + 90*floor(random(4)));
				} else {
					_object setDir _dir;
				};
				_object addEventHandler ["Killed", {private ["_Kpos", "_Kobj"]; _Kobj = _this select 0; _Kpos = getPosASL _Kobj; _Kpos = _Kpos vectorAdd [0,0,-5]; _Kobj setPosASL _Kpos;}];
			};
			// ... and after gate
			_freeSpace = _wallStartOffset+_BIPillarOffset-(_crnrElLn+_gateElLn)/2 - _gateElLO;
			_addEls = ceil (_freeSpace / _wallElLn);
			_step = _freeSpace / _addEls; // can be less than _wallElLn
			if (_addEls == 1) then {
				_step = _wallElLn;
			};
			for [{_k = _addEls-1}, {_k >= 0}, {_k = _k - 1}] do {
				private ["_placeX", "_critX"];
				_critX = _wallStartOffset + (_wallElWd-_wallElLn)/2;
				_placeX = _wallStartOffset + _BIPillarOffset - ((abs(_crnrElLn))+_step)/2 - _k*_step;
				if (_placeX > _critX) then {
					_placeX = _critX;
				};
				_critX = _BIPillarOffset - ((abs(_crnrElLn))-_wallElLn-_gateElLn)/2 + _gateElLO;
				if (_placeX < _critX) then {
					_placeX = _critX;
				};
				_pos = _centerPos vectorAdd ([[0,0,0], [_placeX, _wallStartOffset, 0], _rotateDir] call a3e_fnc_RotatePosition);
				_object = createVehicle [_wallElNm, _pos, [], 0, "CAN_COLLIDE"];
				if (isNil "_wallZOff") then {
					_z = getTerrainHeightASL _pos;
				} else {
					_z = _cpz+_wallZOff;
				};
				_pos set [2, _z];
				_object setPosASL _pos;
				if (_wallElLn == _wallElWd) then {
					_object setDir (_dir + 90*floor(random(4)));
				} else {
					_object setDir _dir;
				};
				_object addEventHandler ["Killed", {private ["_Kpos", "_Kobj"]; _Kobj = _this select 0; _Kpos = getPosASL _Kobj; _Kpos = _Kpos vectorAdd [0,0,-5]; _Kobj setPosASL _Kpos;}];
			};
			// gate itself
			// placing gate in the (offset'ed) middle of the side
			_x = (_BIPillarOffset+(abs(_crnrElLn))/2) + _gateElLO;
			_y = _wallStartOffset + _gateElTO;
			_pos = _centerPos vectorAdd ([[0,0,0], [_x, _y, 0], _rotateDir] call a3e_fnc_RotatePosition);
			_object = createVehicle [_gateElNm, _pos, [], 0, "CAN_COLLIDE"];
			_z = getTerrainHeightASL _pos;
			_pos set [2, _z];
			_object setPosASL _pos;
			_object setDir _dir;
			A3E_PrisonGateObject = _object;
			publicVariable "A3E_PrisonGateObject";
		} else {
			for [{_k = 0}, {_k < _elems}, {_k = _k + 1}] do {
				_x = (1-_i)* _wallStartOffset*(_j*2-1) + _stepSign*(  _i  *(-_wallStartOffset+_BIPillarOffset+(_crnrElLn+_wallElLn)/2 + _k*_wallElLn ));
				_y =   _i  * _wallStartOffset*(_j*2-1) + _stepSign*((1-_i)*(-_wallStartOffset+_BIPillarOffset+(_crnrElLn+_wallElLn)/2 + _k*_wallElLn ));
				_pos = _centerPos vectorAdd ([[0,0,0], [_x, _y, 0], _rotateDir] call a3e_fnc_RotatePosition);
				_object = createVehicle [_wallElNm, _pos, [], 0, "CAN_COLLIDE"];
				if (isNil "_wallZOff") then {
					_z = getTerrainHeightASL _pos;
				} else {
					_z = _cpz+_wallZOff;
				};
				_pos set [2, _z];
				_object setPosASL _pos;
				if (_wallElLn == _wallElWd) then {
					_object setDir (_dir + 90*floor(random(4)));
				} else {
					_object setDir _dir;
				};
				_object addEventHandler ["Killed", {private ["_Kpos", "_Kobj"]; _Kobj = _this select 0; _Kpos = getPosASL _Kobj; _Kpos = _Kpos vectorAdd [0,0,-5]; _Kobj setPosASL _Kpos;}];
			};
		};
	};
};

// Burning barrel
_x = -((_gateElLn)/2 + 1) + _gateElLO; // 1m to the left of gate
_y = (_wallStartOffset+_wallElWd) + 1;// 1 m behind the wall
_pos = _centerPos vectorAdd ([[0,0,0], [_x, _y, 0], _rotateDir] call a3e_fnc_RotatePosition);
_object = createVehicle ["MetalBarrel_burning_F", _pos, [], 0, "NONE"];
_z = getTerrainHeightASL _pos;
_pos set [2, _z];
_object setPosASL _pos;
//_object setDir _rotateDir;

// Loudspeakers
_x = -(_wallStartOffset+_wallElWd) - 1; // 1m behind the wall by x coordinate
_y = -(_wallStartOffset+_wallElWd) + 1; // 1 m before the wall, by y coordinate
_pos = _centerPos vectorAdd ([[0,0,0], [_x, _y, 0], _rotateDir] call a3e_fnc_RotatePosition);
_object = createVehicle ["Land_Loudspeakers_F", _pos, [], 0, "NONE"];
_z = getTerrainHeightASL _pos;
_pos set [2, _z];
_object setPosASL _pos;
//_object setDir _rotateDir;

A3E_PrisonLoudspeakerObject = _object;
publicVariable "A3E_PrisonLoudspeakerObject";

// Flag
_x = _gateElLn/2 + 1 + _gateElLO; // 1m to the right of gate
_y = _wallStartOffset+_wallElWd + 1; // 1 m behind the wall
_pos = _centerPos vectorAdd ([[0,0,0], [_x, _y, 0], _rotateDir] call a3e_fnc_RotatePosition);
_object = createVehicle ["Flag_AAF_F", _pos, [], 0, "NONE"];
_z = getTerrainHeightASL _pos;
_pos set [2, _z];
_object setPosASL _pos;
//_object setDir _rotateDir;

// Graves
_x = -_wallStartOffset+1.9;
_y = -_wallStartOffset+1;
_pos = _centerPos vectorAdd ([[0,0,0], [_x, _y, 0], _rotateDir] call a3e_fnc_RotatePosition);
_object = createVehicle ["Land_Grave_dirt_F", _pos, [], 0, "NONE"];
_z = getTerrainHeightASL _pos;
_pos set [2, _z];
_object setPosASL _pos;
//_object setDir 90;
_object setDir (_rotateDir+180);

_x = -_wallStartOffset+1.9;
_y = -_wallStartOffset+2.5;
_pos = _centerPos vectorAdd ([[0,0,0], [_x, _y, 0], _rotateDir] call a3e_fnc_RotatePosition);
_object = createVehicle ["Land_Grave_dirt_F", _pos, [], 0, "NONE"];
_z = getTerrainHeightASL _pos;
_pos set [2, _z];
_object setPosASL _pos;
//_object setDir 90;
_object setDir (_rotateDir+180);

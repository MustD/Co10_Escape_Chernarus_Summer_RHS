params ["_centerPos", "_rotateDir"];
_centerPos params [["_cpx", 0, [0]], ["_cpy", 0, [0]]];
private ["_object", "_pos", "_dir", "_cpz"];
private ["_i", "_j", "_k", "_prMaterials", "_prMaterial", "_rotPos", "_placePrisonObj"];
_cpz = getTerrainHeightASL _centerPos;

_placePrisonObj = {
	/*
		Parameters:
		0: _clName String: class name of object to place;
		1: _x: Number: x offset from _centerPos; x axis is to right from _rotateDir;
		2: _y: Number: y offset from _centerPos; y axis is codirectional to prison's _rotateDir;
		3: _zOffArray: Array: [_zType, _zOff]: defult is ["REL", 0]
			_zType: String: "CENTER" for offset against _centerPos's absolute z coord (ASL); OR "REL" (or any) for relative to ground;
			_zOff: Number: z offset;
		4: _rotDir: Number: rotation added to prison's _rotateDir.
		5: _simul: Boolean: if set to false, disables simulation globally;
		6: _normalize: Boolean: set object normal vector according to surface; otherwise Z axis used; default is false;
		7: _vecsDirUp: Array: if set, overrides _normalize to false;
			[_vecDir, _vecUp]: _vecDir: Array of Numbers: [_dX, _dY, _dZ];
			_vecUp: Array of Numbers: [_uX, _uY, _uZ];
		8: _varName: String: if set, variable with such name is set to returned value, and then published over network, i.e. next call performed:
			missionNamespace setVariable [_varName, _obj, true];

		Return: Object: created object
	*/
	params [["_clName", "", [""]], ["_x", 0, [0]], ["_y", 0, [0]], ["_zOffArray", ["REL", 0], [[]], [2]], ["_rotDir", 0, [0]],  ["_simul", false, [false]], ["_normalize", false, [false]], ["_vecsDirUp", [[0,1,0], [0,0,1]], [[]], [2]], ["_varName", "", [""]]];
	diag_log format ["_placePrisonObj: %1", _this];
	_zOffArray params [["_zType", "REL", [""]], ["_zOff", 0, [0]]];
	_vecsDirUp params [["_vecDir", [0,1,0], [[]], [3]], ["_vecUp", [0,0,1], [[]], [3]]];
	private ["_pos", "_z", "_obj"];
	_pos = _centerPos vectorAdd ([[0,0,0], [_x, _y, 0], _rotateDir] call a3e_fnc_RotatePosition);
	_obj = createVehicle [_clName, _pos, [], 0, "CAN_COLLIDE"];
	if (_zType == "CENTER") then {
		_z = _cpz+_zOff;
	} else {
		_z = (getTerrainHeightASL _pos) + _zOff;
	};
	_pos set [2, _z];
	_obj setPosASL _pos;
	_obj setDir (_rotateDir+_rotDir);
	if ((count _this) > 7) then {
		//diag_log format ["_vecDir: %1; _vecUp: %2", _vecDir, _vecUp];
		_obj setVectorDirAndUp [_vecDir, [[0,0,0], _vecUp, _rotateDir+_rotDir] call a3e_fnc_RotatePosition];
	} else {
		if (_normalize) then {
			_obj setVectorUp (surfaceNormal _pos);
		} else {
			_obj setVectorUp [0,0,1];
		};
	};
	_obj allowDamage false;
	if (!_simul) then {
		_obj enableSimulationGlobal _simul;
	};
	if (_varName != "") then {
		missionNamespace setVariable [_varName, _obj, true];
	};
	_obj
};

/**	(switch to monospace)

	+--+    1       2       1   +--+  _prMaterials: Array: [ prisonMaterialsSet1 (, prisonMaterialsSet2, ...)]
	| 3||======||------||======|| 3|      prisonMaterialsSet1: Array: [ wallElement, gateElement (, cornerElement) ]
	+--+                        +--+          wallElement: Array: [ className, numPerSide, length (,width(,pillar(,zOffset)))]
	 --    1 - wall element      --               className: String: CfgVehicles classname to construct wall segment,
	 ||    2 - gate              ||                 e.g. "Land_Wall_Tin_4", "Land_City_4m_F", "Land_City2_4m_F", ...
	 || 1  3 - corner            || 1             numPerSide: Number: of elements per prison side. Prison side is calculated using this value.
	 --                          --               length: Number: effective linear size of element.
	 --            ^ y           --               width: Number: wall thickness.
	 ||            |             ||               pillar: Number: defines whether wall element has builtin pillar.
	 || 1          + --> x       || 1               If no cornerElement specified wall side starts on corner and
	 --       _centerPos         --                 end before side end, leaving space for next side start element's pillar.
	 --                          --                 If wall element has builtin pillar on its end, it can be useful to start
	 ||                          ||                 wall side leaving space for previous side end pillar, and end leaving no
	 || 1                        || 1               space for next side start pillar. To do so, define pillar to be:
	 --                          --                    1: wall element has pillar on its start;
	+--+     1      1       1   +--+                   2: wall element has pillar on its end.
	| 3||======||======||======|| 3|                   0 is default value meaning no builtin pillar
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

	        cornerElement: Array: [className, length(, zOffset) ]
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
	[["Land_City_Pillar_F", 26, 0.445, 0.445, 0, 0], ["Land_City_Gate_F", 4], ["Land_City_Pillar_F", 0.445, 0]], // whole prison wall built of pillars
	[["Land_City2_4m_F", 3, 3.5, 0.45, 2, 0.6], ["Land_City_Gate_F", 4]],
	[["Land_City_4m_F", 3, 3.5, 0.45, 1, 0.6], ["Land_City_Gate_F", 4]],
	[["Land_Stone_4m_F", 3, 4, 0.5], ["Land_Stone_Gate_F", 5], ["Land_Stone_pillar_F", 0.5]]
];

_prMaterial = _prMaterials call BIS_fnc_selectRandom;
diag_log format ["_prMaterial: %1", _prMaterial];

_prMaterial params [["_wallElem", [], [[]], [3,4,5,6]], ["_gateElem", [], [[]], [2,3,4]], ["_crnrElem", [], [[]], [2,3]]];
_wallElem params [["_wallElNm", "Land_Wall_Tin_4", [""]], ["_elems", 3, [0]], ["_wallElLn", 4, [0]], ["_wallElWd", 0, [0]], ["_wallElPl", 0, [0]], ["_wallZOff", nil, [0,nil]]];
_gateElem params [["_gateElNm", "Land_City_Gate_F", [""]], ["_gateElLn", 4, [0]], ["_gateElTO", 0, [0]], ["_gateElLO", 0, [0]]];
_crnrElem params [["_crnrElNm", "", [""]], ["_crnrElLn", 0, [0]], ["_crnrZOff", nil, [0,nil]]];

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
		_dir = _j*180 - _i*90 + 90;
		_stepSign = if (_i == _j) then {1} else {-1};
		if (_crnrElNm != "") then {
			[
				_crnrElNm,
				-_stepSign*_wallStartOffset,
				_wallStartOffset * (_j*2-1),
				if (isNil "_crnrZOff") then {["REL", 0]} else {["CENTER", _crnrZOff]},
				_dir
			] call _placePrisonObj;
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
				[
					_wallElNm,
					_placeX,
					_wallStartOffset,
					if (isNil "_wallZOff") then {["REL", 0]} else {["CENTER", _wallZOff]},
					if (_wallElLn == _wallElWd) then {_dir + 90*floor(random(4))} else {_dir}
				] call _placePrisonObj;
			};
			// ... and after gate
			_freeSpace = _wallStartOffset+_BIPillarOffset-((abs(_crnrElLn))+_gateElLn)/2 - _gateElLO;
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
				[
					_wallElNm,
					_placeX,
					_wallStartOffset,
					if (isNil "_wallZOff") then {["REL", 0]} else {["CENTER", _wallZOff]},
					if (_wallElLn == _wallElWd) then {_dir + 90*floor(random(4))} else {_dir}
				] call _placePrisonObj;
			};
			// gate itself
			// placing gate in the (offset'ed) middle of the side
			[
				_gateElNm,
				_BIPillarOffset + _gateElLO,
				_wallStartOffset + _gateElTO,
				["REL", 0], _dir, true, nil, nil, "A3E_PrisonGateObject"
			] call _placePrisonObj;
		} else {
			for [{_k = 0}, {_k < _elems}, {_k = _k + 1}] do {
				[
					_wallElNm,
					(1-_i)* _wallStartOffset*(_j*2-1) + _stepSign*(  _i  *(-_wallStartOffset+_BIPillarOffset+(_crnrElLn+_wallElLn)/2 + _k*_wallElLn )),
					  _i  * _wallStartOffset*(_j*2-1) + _stepSign*((1-_i)*(-_wallStartOffset+_BIPillarOffset+(_crnrElLn+_wallElLn)/2 + _k*_wallElLn )),
					if (isNil "_wallZOff") then {["REL", 0]} else {["CENTER", _wallZOff]},
					if (_wallElLn == _wallElWd) then {_dir + 90*floor(random(4))} else {_dir}
				] call _placePrisonObj;
			};
		};
	};
};

// place various prison objects
{_x call _placePrisonObj; true} count [
	[
		"MetalBarrel_burning_F",
		-((_gateElLn)/2 + 1) + _gateElLO, // 1m to the left of gate
		(_wallStartOffset+_wallElWd) + 1, // 1 m behind the wall
		nil, 0, true, true
	], [
		"Land_Loudspeakers_F",
		-(_wallStartOffset+_wallElWd) - 1, // 1m behind the wall by x coordinate
		-(_wallStartOffset+_wallElWd) + 1, // 1 m before the wall, by y coordinate
		nil, 0, false, nil, nil, "A3E_PrisonLoudspeakerObject"
	], [
		"Flag_AAF_F",
		_gateElLn/2 + 1 + _gateElLO, // 1m to the right of gate
		_wallStartOffset+_wallElWd + 1, // 1 m behind the wall
		nil, 0, true
	], [
		"Land_Grave_dirt_F",
		-_wallStartOffset+1.9,
		-_wallStartOffset+1,
		nil, 180, false, true
	], [
		"Land_Grave_dirt_F",
		-_wallStartOffset+1.9,
		-_wallStartOffset+2.5,
		nil, 180, false, true
	], [
		"Land_Shovel_F",
		-_wallStartOffset+_wallElWd/2+0.15,
		-_wallStartOffset+_wallElWd/2+0.15,
		["REL", 0.42], 40, false, false, [[0,0,-1], [0, 1, 0]]
	], [
		"Land_Garbage_square3_F",
		_wallStartOffset-_wallElWd-1.5,
		_wallStartOffset-_wallElWd-1.5,
		nil, 0, false, true
	]
];

// for placement debug purposes
if (false) then {
	private ["_i", "_k"];
	for [{_i = floor(-_wallStartOffset)-2}, {_i <= ceil(_wallStartOffset)+2}, {_i = _i + 1}] do {
		for [{_k = floor(-_wallStartOffset)-2}, {_k <= ceil(_wallStartOffset)+2}, {_k = _k + 1}] do {
			["Sign_Sphere10cm_F", _i, _k] call _placePrisonObj;
		};
	};
};

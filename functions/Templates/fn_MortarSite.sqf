params ["_position"];

if(isNil("A3E_MortarMarkerNumber")) then {
	A3E_MortarMarkerNumber = 0;
} else {
	A3E_MortarMarkerNumber = A3E_MortarMarkerNumber +1;
};
_number = A3E_MortarMarkerNumber;

private["_obj","_objpos","_dir","_gunner", "_placeObj"];

_placeObj = {
	params [["_clName", "", [""]], ["_relPos", [0,0,0], [[]], [3]], ["_relDir", 0, [0]]];
	private ["_objPos", "_objReturn"];
	if (_clName == "") then {
		_objReturn = objNull;
	} else {
		_objPos = _position vectorAdd _relPos;
		_objReturn = _clName createVehicle _objPos;
		_objReturn setPos _objPos;
	};
	_objReturn
};

{
	_x call _placeObj
} forEach [
	["Land_BagFence_End_F", [3.78394,-0.563721,-0.00930499], 320.859],
	["Land_BagFence_Long_F", [2.31396,-1.72375,-0.00930499], 321.086],
	["Land_BagFence_Long_F", [1.56396,3.35632,-0.00930499], 0.479819],
	["Land_BagFence_Round_F", [-0.0661621,-2.9137,-0.00900411], 0]
];

_objpos = _position vectorAdd [-0.105957,-0.183716,0.0648341];
_obj = createVehicle [a3e_arr_MortarSite call BIS_fnc_selectRandom, _objpos, [], 0, "NONE"];
_gunner = [_obj,A3E_VAR_Side_Opfor] spawn A3E_fnc_AddStaticGunner;
a3e_var_artillery_units pushBack _obj;
_dir = 180.555;
_obj setDir _dir;
_obj setPos _objpos;

{
	_x call _placeObj
} forEach [
	["Land_BagFence_Long_F", [-1.45605,3.44629,-0.00930499], 179.672],
	["Land_BagFence_Long_F", [-2.36597,-1.42371,-0.00930499], 47.601],
	["Land_BagFence_End_F", [-3.66602,0.00622559,-0.00930499], 229.949]
];

["A3E_MortarSiteMapMarker" + str _number,_position,"o_mortar"] call A3E_fnc_createLocationMarker;

_marker = createMarkerLocal ["A3E_MortarSitePatrolMarker" + str _number, _position];
_marker setMarkerShapeLocal "ELLIPSE";
_marker setMarkerAlpha 0;
_marker setMarkerSizeLocal [50, 50];

params [["_static", objNull, [objNull]], ["_side", A3E_VAR_Side_Ind, [sideUnknown]]];
private["_gunner","_group","_possibleInfantryTypes","_infantryType","_unit"];

_group = createGroup _side;
_possibleInfantryTypes = a3e_arr_Escape_InfantryTypes;
switch (_side) do {
    case A3E_VAR_Side_Opfor: { _possibleInfantryTypes = a3e_arr_Escape_InfantryTypes;};
    case A3E_VAR_Side_Ind: {_possibleInfantryTypes = a3e_arr_Escape_InfantryTypes_Ind;};
};
_infantryType = _possibleInfantryTypes call BIS_fnc_selectRandom;
_unit = _group createUnit [_infantryType, getpos _static, [], 0, "FORM"];
_unit assignAsGunner _static;
_unit moveInGunner _static;
_unit;

params ["_side"];
private["_color"];

switch(_side) do {
	case (civilian):{_color = "ColorWhite";};
	case (west):{_color = "ColorBlue";};
	case (east):{_color = "ColorRed";};
	case (resistance):{_color = "ColorGreen";};
	default {_color = "ColorBlack";};
};
_color;

//[10,0.1,1,1,1,1] spawn {
A3E_fnc_changeWeather = {
	// param requires A3 v1.48
	//_time = param[0];
	//_delta = param[1];
	//_overcast = param[2];
	//_rain = param[3];
	//_fog = param[4];
	//_lightning = param[5];
	_time = [_this, 0] call BIS_fnc_param;
	_delta = [_this, 1] call BIS_fnc_param;
	_overcast = [_this, 2] call BIS_fnc_param;
	_rain = [_this, 3] call BIS_fnc_param;
	_fog = [_this, 4] call BIS_fnc_param;
	_lightning = [_this, 5] call BIS_fnc_param;
	systemchat "Weatherchange";
	private["_dOvercast","_dRain","_dLightning","_dFog","_steps"];
	_steps = (_time/_delta);
	_dOvercast = (_overcast - overcast)/_steps;
	_dRain = (_rain - rain)/_steps;
	_dFog = (_fog - fog)/_steps;
	_dLightning = (_lightning - lightnings)/_steps;

	for "_i" from 0 to _steps do {
		0 setovercast (overcast+_dOvercast);
		0 setrain (rain+_dRain);
		0 setfog (fog+_dFog);
		0 setlightnings (lightnings+_dLightning);
		systemchat str _dOvercast;
		forceWeatherChange;
		sleep _delta;
	};
};

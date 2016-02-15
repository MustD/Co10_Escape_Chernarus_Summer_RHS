A3E_fnc_GetPlayers = {
	private["_players"];
	//_players = allPlayers; // requires 1.48
	_players = [] call BIS_fnc_listPlayers;
	_players
};

pdth_fnc_weapon_slot_comp_items = {
	/**
		Return list of compatible attachments suitable for specified weapon and for specifiied slot
		_this: Array: [ className, slotName ]:
			className: String: weapon class name
			slotName: String: slot class name, representing class entry in ()
				Commonly used slot names are:
					"CowsSlot": optics
					"PointerSlot": pointers, flashlights, etc.
					"MuzzleSlot": muzzle flash suppressors, silencers, etc.
					"UnderBarrelSlot": bipods
		@return Array: [(item1, item2, ...)]
			item1, item2, ...: Strings
		@example
			// returns ["acc_flashlight", "acc_pointer_IR"]
			_arrPointers = ["arifle_MX_F", "PointerSlot"] call pdth_fnc_weapon_slot_comp_items;
	**/
	private ["_clName", "_slName", "_ret"];
	_ret = [];
	_clName = [_this, 0, "", [""]] call BIS_fnc_param;
	_slName = [_this, 1, "", [""]] call BIS_fnc_param;
	if ((isClass (configFile >> "CfgWeapons" >> _clName)) && (isClass (configFile >> "CfgWeapons" >> _clName >> "WeaponSlotsInfo" >> _slName))) then {
		private "_compItems";
		_compItems = (configFile >> "CfgWeapons" >> _clName >> "WeaponSlotsInfo" >> _slName >> "compatibleItems");
		if (isClass _compItems) then {
			{
				_ret pushBack (configName _x);
			} forEach (configProperties [_compItems, "(isNumber _x) && ((getNumber _x) > 0)"]);
		} else {
			if (isArray _compItems) then {
				_ret = getArray(_compItems);
			}
		}
	};
	_ret
};

pdth_fnc_weapon_scopes = {
	/*
		Return list of scopes suitable for specified weapon, sorted by their vision modes.
		_this: Array: [ className (, fullLists) ]:
			className: String: weapon class name
			fullLists: Boolean: (optionalm default is false):
				If set to true, will return full list for every vision mode, i.e. Nightstalker will go
				for all categories: none, "Normal", "NVG" and "Ti". So there might be duplications
				of same scope in different categories.
				Otherwise (default behaviour), only scopes with "Ti" (thermal) mode will go to "Ti" category;
				only scopes with "NVG" mode but without "Ti" will go to "NVG" category;
				only scopes with "Normal" mode but without "Ti" and "NVG" will go to "Normal" category;
				only scopes without special modes will go to "none" category. No duplications: each scope
				goes for its best category.
		return: Array: [[(noneScope1, ...)], [(normalScope1, ...)], [(nvgScope1, ...)], [(tiScope1, ...)]]
			noneScope1, normalScope1, nvgScope1, tiScope1, ...: Strings
	*/
	private ["_clName", "_full", "_ret", "_none", "_normal", "_nvg", "_ti"];
	_none = [];
	_normal = [];
	_nvg = [];
	_ti = [];
	_clName = [_this, 0, "", [""]] call BIS_fnc_param;
	_full = [_this, 1, false, [true]] call BIS_fnc_param;
	if (isClass (configFile >> "CfgWeapons" >> _clName)) then {
		private "_opt";
		_opt = [_clName, "CowsSlot"] call pdth_fnc_weapon_slot_comp_items;
		if ((!(isNil "_opt")) && ((count _opt) > 0)) then {
			{
				private ["_optName", "_visModes", "_optModes", "_hasEmpty", "_hasNonEmpty"];
				_optName = _x;
				_visModes = [];
				_hasEmpty = false;
				_hasNonEmpty = false;
				_optModes = configProperties [(configFile >> "CfgWeapons" >> _optName >> "ItemInfo" >> "OpticsModes")];
				{
					private "_optMod";
					_optMod = _x;
					_visModes = (getArray(_x >> "visionMode"));
					scopeName "optMode";
					if ((count _visModes) > 0) then {
						_hasNonEmpty = true;
						if ("Ti" in _visModes) then {
							_ti pushBack _optName;
							if (!_full) then {
								breakTo "optMode";
							};
						};
						if ("NVG" in _visModes) then {
							_nvg pushBack _optName;
							if (!_full) then {
								breakTo "optMode";
							};
						};
						if ("Normal" in _visModes) then {
							if (_full && ("rhs_acc_1pn93_base" in ([(configFile >> "CfgWeapons" >> _optName),true] call BIS_fnc_returnParents))) then {
								// rhs_acc_1pn93_* are broken in RHS 0.3.7, they have ironsight optics mode with "Normal" visMode, when actually there's no "Normal", only visionMode[]={}
								_none pushBack _optName;
								_hasEmpty = true;
							} else {
								_normal pushBack _optName;
							};
						};
					} else {
						_hasEmpty = true;
					};
				} forEach _optModes;
				if (_hasEmpty && !_hasNonEmpty) then {
					_none pushBack _optName;
				};
			} forEach _opt;
		};
	};
	_ret = [_none, _normal, _nvg, _ti];
	_ret
};

pdth_rm_grenades = {
	if (((productVersion) select 2) == 142) then {
		// Dirty fix for ArmA3 v1.42 legacyPort with RHS0.3.7,
		// which caused crazy crashes when players looted and
		// used RGD-5 grenades (and maybe other grenades)
		private ["_u", "_mags", "_checked", "_count"];
		if ((typeName _this) == "ARRAY") then {
			_u = _this select 0;
		} else {
			_u = _this;
		};
		_mags = magazines _u;
		_count = 0;
		_checked = [];
		{
			private "_mag";
			_mag = _x;
			if (!(_mag in _checked)) then {
				if ("HandGrenade" in ([(configFile >> "CfgMagazines" >> _mag),true] call BIS_fnc_returnParents)) then {
					while {(_mag in (magazines _u))} do {
						_u removeMagazineGlobal _mag;
						_count = _count + 1;
					};
				};
				_checked pushBack _mag;
			};
		} forEach _mags;
//		if (_count > 0) then {
//			_u addMagazine ["Handgrenade", _count];
//		};
	};
};

drn_fnc_Escape_OnSpawnGeneralSoldierUnit = {
	private["_nighttime", "_pWeap", "_marksman", "_rnd"];
	_this setVehicleAmmo (0.2 + random 0.6);
	if(daytime > 20 OR daytime < 8) then {
		_nighttime = true;
	} else {
		_nighttime = false;
	};
	//Hopefully fixing BIS broken scripts:
	_this setskill 0.2;
	_this setskill ["aimingspeed", 0.1];
	_this setskill ["spotdistance", 0.2];
	_this setskill ["aimingaccuracy", 0.2];
	_this setskill ["aimingshake", 0.1];
	_this setskill ["spottime", 0.1];
	_this setskill ["commanding", 0.2];
	_this setskill ["general", 0.3];
	_this setskill ["reloadspeed", 0.2];
	_this setskill ["courage", 0.2];
	_this setskill ["endurance", 0.2];

	_this removeItem "FirstAidKit";

	_marksman = false;
	_pWeap = primaryWeapon _this;
	if (_pWeap != "") then {
		if ("rhs_weap_svd" in ([(configFile >> "CfgWeapons" >> _pWeap), true] call BIS_fnc_returnParents)) then {
			_marksman = true;
			// this will still be very few
			_this setVehicleAmmo (0.8 + random 0.2);
		};
	};

	removeAllPrimaryWeaponItems _this;
	// chances for scopes
	// 30% chance to have a scope for non-marksman
	if ((random 100 < 30) || _marksman) then {
		if (_pWeap != "") then {
			private ["_opt", "_optTi", "_optNVG", "_optNormalOnly", "_optNone", "_wNo", "_wNrm", "_wNVG", "_wTi", "_wTotal", "_wRnd", "_scope"];
			_opt = [_pWeap] call pdth_fnc_weapon_scopes;
			_optNone = [_opt, 0, [], [[]]] call BIS_fnc_param;
			_optNormal = [_opt, 1, [], [[]]] call BIS_fnc_param;
			_optNVG = [_opt, 2, [], [[]]] call BIS_fnc_param;
			_optTi = [_opt, 3, [], [[]]] call BIS_fnc_param;
			// _optTi only contains scopes w/ thermal
			// _optNVG only contains scopes w/o thermal, but w/ nvg
			// _optNormalOnly only contains scopes w/o thermal and nvg, but with normal optic zoom (not compatible with nv goggles)
			// _optNone only contains scopes w/o any special vis mode (compatible w/ nv goggles) <--- collimators go there!
			// Weights for different scopes, not actual percents due to params and conditions
			if (_nighttime) then {
				_wNo = if ((count _optNone) > 0) then {10} else {0}; // those are scopes! collimators, ACO, RCO, MRCO, etc. goes here. "No" means no special vis mode here
				_wNrm = if ((count _optNormal) > 0) then {30} else {0};
				_wNVG = if ((Param_NoNightvision==0) && ((count _optNVG) > 0)) then {50} else {0};
				_wTi = if ((Param_NoNightvision==0) && ((count _optTi) > 0)) then {10} else {0};
			} else {
				_wNo = if ((count _optNone) > 0) then {60} else {0};
				_wNrm = if ((count _optNormal) > 0) then {30} else {0};
				_wNVG = 0; // NVG scopes usually do not have "turn off" option for NVG mode, so unusable in daytime anyway
				_wTi = if ((Param_NoNightvision==0) && ((count _optTi) > 0)) then {10} else {0};
			};
			if (_marksman) then {
				// nobody ever uses SVD w/o Normal scope
				_wNo = 0;
			};
			_wTotal = _wNo + _wNrm + _wNVG + _wTi;
			_wRnd = random _wTotal;
			_scope = "";
			if (_wRnd < _wNo) then {
				if ((count _optNone) > 0) then {
					_scope = _optNone select floor(random(count(_optNone)));
				};
			} else {
				if (_wRnd < (_wNo+_wNrm)) then {
					if ((count _optNormal) > 0) then {
						_scope = _optNormal select floor(random(count(_optNormal)));
					};
				} else {
					if (_wRnd < (_wNo+_wNrm+_wNVG)) then {
						if ((count _optNVG) > 0) then {
							_scope = _optNVG select floor(random(count(_optNVG)));
						};
					} else {
						if ((count _optTi) > 0) then {
							_scope = _optTi select floor(random(count(_optTi)));
						};
					};
				};
			};
			if (_scope != "") then {
				_this addPrimaryWeaponItem _scope;
			};
		};
	};

	//Chance for random pointer attachment
	if(((random 100 < 15) && (!_nighttime)) OR ((random 100 < 70) && (_nighttime))) then {
		if (_pWeap != "") then {
			private "_ptrs";
			_ptrs = [_pWeap, "PointerSlot"] call pdth_fnc_weapon_slot_comp_items;
			if (!(isNil "_ptrs")) then {
				if ((count _ptrs) > 0) then {
					_this addPrimaryWeaponItem (_ptrs select floor(random(count(_ptrs))));
				};
			};
		};
	};

	//Bipod chance
	if((random 100 < 20)) then {
		if (_pWeap != "") then {
			private "_bips";
			_bips = [_pWeap, "UnderBarrelSlot"] call pdth_fnc_weapon_slot_comp_items;
			if (!(isNil "_bips")) then {
				if ((count _bips) > 0) then {
					_this addPrimaryWeaponItem (_bips select floor(random(count(_bips))));
				};
			};
		};
	};

	//Chance for silencers
	if(((random 100 < 10) && (!_nighttime)) OR ((random 100 < 40) && (_nighttime))) then {
		if (_pWeap != "") then {
			private "_muzs";
			_muzs = [_pWeap, "MuzzleSlot"] call pdth_fnc_weapon_slot_comp_items;
			if (!(isNil "_muzs")) then {
				if ((count _muzs) > 0) then {
					_this addPrimaryWeaponItem (_muzs select floor(random(count(_muzs))));
				};
			};
		};
	} else {
		_this addPrimaryWeaponItem "rhs_acc_dtk";
	};
	if (random 100 > 20) then {
		_this unlinkItem "ItemMap";
	};
	if (random 100 > 30) then {
		_this unlinkItem "ItemCompass";
	};
	if (random 100 > 5) then {
		_this unlinkItem "ItemGPS";
	};
	if ("Binocular" in (assignedItems _this)) then {
		if (random 100 > 30) then {
			_this unlinkItem "Binocular";
		};
	};
	if ("Rangefinder" in (assignedItems _this)) then {
		if (random 100 > 30) then {
			_this unlinkItem "Rangefinder";
		};
	};
	//if ("NVGoggles_OPFOR" in (assignedItems _this)) then {
	//		if((_nighttime) && (random 100 > 40) || !(_nighttime) && (random 100 > 5) || (Param_NoNightvision>0)) then {
	//			_this unlinkItem "NVGoggles_OPFOR";
	//		};
	//};
	//if ("NVGoggles_INDEP" in (assignedItems _this)) then {
	//		if((_nighttime) && (random 100 > 40) || !(_nighttime) && (random 100 > 5) || (Param_NoNightvision>0)) then {
	//			_this unlinkItem "NVGoggles_INDEP";
	//		};
	//};
	private["_nvgs"];
	_nvgs = hmd _this; //NVGoggles
	if(_nvgs != "") then {
		if((_nighttime) && (random 100 > 40) || !(_nighttime) && (random 100 > 5) || (Param_NoNightvision>0)) then {
			_this unlinkItem _nvgs;
		};
	} else {
		if((((_nighttime) && (random 100 < 40)) || (!(_nighttime) && (random 100 < 5))) && (Param_NoNightvision==0)) then {
			_this linkItem "NVGoggles_OPFOR";
		};
	};
	//_this spawn pdth_rm_grenades;
};

drn_fnc_Escape_FindGoodPos = {
	private ["_i", "_startPos", "_isOk", "_result", "_roadSegments", "_dummyObject"];
    // Choose a random and flat position (for-loopen and markers are for test on new maps).
    for [{_i = 0},  {_i < 1}, {_i = _i + 1}] do {
        _isOk = false;
        while {!_isOk} do {

			_startPos = [(getpos SouthWest select 0) + random (getpos NorthEast select 0),(getpos SouthWest select 1) + random (getpos NorthEast select 1)];


            //diag_log ("startPos == " + str _startPos);
            _result = _startPos isFlatEmpty [5, 0, 0.25, 1, 0, false, objNull];
            _roadSegments = _startPos nearRoads 30;
			_buildings = _startPos nearObjects 30;

            if ((count _result > 0) && (count _roadSegments == 0) && (!surfaceIsWater _startPos) && (count _buildings == 0)) then {
				_startPos = _result;
                _dummyObject = "Land_Can_Rusty_F" createVehicleLocal _startPos;

                if (((nearestBuilding _dummyObject) distance _startPos) > 50) then {
                    _isOk = true;
                };

                deleteVehicle _dummyObject;
            };
        };

        //_marker = createMarker ["marker" + str _i, _startPos];
        //_marker setMarkerType "Warning";
    };

    _startPos
};

drn_fnc_Escape_FindAmmoDepotPositions = {
    private ["_occupiedPositions"];
    private ["_positions", "_i", "_j", "_tooCloseAnotherPos", "_pos", "_maxDistance", "_countNW", "_countNE", "_countSE", "_countSW", "_isOk"];

    _occupiedPositions = _this;

    _positions = [];
    _i = 0;
    _maxDistance = 1000;

    _countNW = 0;
    _countNE = 0;
    _countSE = 0;
    _countSW = 0;
    if(isNil("A3E_AmmoDepotCount")) then {
		A3E_AmmoDepotCount = 8;
	};
    while {count _positions < A3E_AmmoDepotCount} do {
        _isOk = false;
        _j = 0;

        while {!_isOk} do {
            _pos = call drn_fnc_Escape_FindGoodPos;
            _isOk = true;

            if (count _positions < 16) then {
                if (_pos select 0 <= ((getMarkerPos "center") select 0) && _pos select 1 > ((getMarkerPos "center") select 1)) then {
                    if (_countNW < 5) then {
                        _countNW = _countNW + 1;
                    }
                    else {
                        _isOk = false;
                    };
                };
                if (_pos select 0 > ((getMarkerPos "center") select 0) && _pos select 1 > ((getMarkerPos "center") select 1)) then {
                    if (_countNE < 5) then {
                        _countNE = _countNE + 1;
                    }
                    else {
                        _isOk = false;
                    };
                };
                if (_pos select 0 > ((getMarkerPos "center") select 0) && _pos select 1 <= ((getMarkerPos "center") select 1)) then {
                    if (_countSE < 5) then {
                        _countSE = _countSE + 1;
                    }
                    else {
                        _isOk = false;
                    };
                };
                if (_pos select 0 <= ((getMarkerPos "center") select 0) && _pos select 1 <= ((getMarkerPos "center") select 1)) then {
                    if (_countSW < 5) then {
                        _countSW = _countSW + 1;
                    }
                    else {
                        _isOk = false;
                    };
                };
            };

            _j = _j + 1;
            if (_j > 100) then {
                _isOk = true;
            };
        };

        _tooCloseAnotherPos = false;
        {
            if (_pos distance _x < _maxDistance) then {
                _tooCloseAnotherPos = true;
            };
        } foreach _positions;

        if (!_tooCloseAnotherPos) then {
            {
                if (_pos distance _x < _maxDistance) then {
                    _tooCloseAnotherPos = true;
                };
            } foreach _occupiedPositions;
        };

        if (!_tooCloseAnotherPos) then {
            _positions set [count _positions, _pos];
        };

        _i = _i + 1;
        if (_i > 100) exitWith {
            _positions
        };
    };

    _positions
};

drn_fnc_Escape_AllPlayersOnStartPos = {
    private ["_startPos"];
    private ["_allPlayersAtStartPos"];

    _startPos = _this select 0;

    _allPlayersAtStartPos = true;

    {
        if (_x distance _startPos > 30) exitWith {
            _allPlayersAtStartPos = false;
        };
    } foreach call A3E_fnc_GetPlayers;

    _allPlayersAtStartPos
};

drn_fnc_Escape_GetPlayerGroup = {
	private ["_units", "_unit", "_group"];

	_units = call A3E_fnc_GetPlayers;
	_group = objNull;

	if (!(isNil "_units")) then {
		if ((typeName _units) == "ARRAY") then {
			_unit = _units select 0;
			if (!(isNil "_unit")) then {
				_group = group _unit;
			};
		};
	};

	_group
};

drn_fnc_Escape_CreateExtractionPointServer = {
    private ["_extractionPointNo"];

    _extractionPointNo = _this select 0;

    if (isServer) then {
        [_extractionPointNo] execVM "Scripts\Escape\CreateExtractionPoint.sqf";
    }
    else {
        drn_EscapeExtractionEventArgs = [_extractionPointNo];
        publicVariable "drn_EscapeExtractionEventArgs";
    };
};

if (isServer) then {
    "drn_EscapeExtractionEventArgs" addPublicVariableEventHandler {
        drn_EscapeExtractionEventArgs call drn_fnc_Escape_CreateExtractionPointServer;
    };
};

drn_Escape_AskForTimeSynchronizationEventArgs = [];
drn_Escape_SynchronizeTimeEventArgs = [];

drn_fnc_Escape_SynchronizeTimeLocal = {
    setDate _this;
};

drn_fnc_Escape_AskForTimeSynchronization = {
    drn_Escape_AskForTimeSynchronizationEventArgs = [true];
    publicVariable "drn_Escape_AskForTimeSynchronizationEventArgs";
};

"drn_Escape_SynchronizeTimeEventArgs" addPublicVariableEventHandler {
    drn_Escape_SynchronizeTimeEventArgs call drn_fnc_Escape_SynchronizeTimeLocal;
};

if (isServer) then {
    drn_fnc_Escape_SynchronizeTimeAllClients = {
        drn_Escape_SynchronizeTimeEventArgs = + date;
        publicVariable "drn_Escape_SynchronizeTimeEventArgs";
    };

    "drn_Escape_AskForTimeSynchronizationEventArgs" addPublicVariableEventHandler {
        call drn_fnc_Escape_SynchronizeTimeAllClients;
    };
};

drn_fnc_Escape_TrafficSearch = {
    private ["_vehicle", "_referenceMarker", "_distanceFromReferenceMarker", "_minTimeBetweenStopsSek", "_maxTimeBetweenStopsSek"];
    private ["_gunner", "_commander", "_angle", "_i", "_startSearchTime", "_searchTime", "_glanceTime", "_startGlanceTime", "_turnDir", "_startTime", "_waitTime", "_detectedEnemies"];
    private ["_fnc_LookInDirection", "_fnc_hasDetectedEnemies"];

    _vehicle = _this select 0;
    _referenceMarker = drn_searchAreaMarkerName;
    _distanceFromReferenceMarker = 1000;
    _minTimeBetweenStopsSek = 30;
    _maxTimeBetweenStopsSek = 180;

    scopeName "mainScope";
    _gunner = gunner _vehicle;
    _commander = commander _vehicle;
    _angle = 0;

    {
        _x call drn_fnc_Escape_OnSpawnGeneralSoldierUnit;
    } foreach units group _vehicle;

    if ((isNull _gunner) && (isNull _commander)) exitWith {};

    _fnc_LookInDirection = {
        private ["_unit", "_dir"];
        private ["_x", "_y", "_pos"];

        _unit = _this select 0;
        _dir = _this select 1;

        _x = ((getPos _unit) select 0) - (1000 * cos (_dir + 90));
        _y = ((getPos _unit) select 1) + (1000 * sin (_dir + 90));
        _pos = [_x, _y, 0];

        _unit doWatch _pos;

//        deleteMarkerLocal "debugMarker";
//        _marker = createMarkerLocal ["debugMarker", _pos];
//        _marker setMarkerTypeLocal "Warning";
    };

    _fnc_hasDetectedEnemies = {
        private ["_unit"];
        private ["_nearestEnemy", "_result"];

        _unit = _this select 0;

        _nearestEnemy = _unit findNearestEnemy (getPos _unit);
        _result = false;

        if (!isNull _nearestEnemy) then {
            _result = true;
        };

        _result
    };

    sleep (_minTimeBetweenStopsSek + random (_maxTimeBetweenStopsSek - _minTimeBetweenStopsSek));
    _detectedEnemies = false;

    while {damage _vehicle < 0.1 && !_detectedEnemies} do {
        private ["_pos", "_makeSearchStop"];

        _makeSearchStop = true;
        if (_referenceMarker != "") then {
            if ((getMarkerPos _referenceMarker) distance _vehicle > _distanceFromReferenceMarker) then {
                _makeSearchStop = false;
            };
        };

        if (_makeSearchStop) then {
            _startSearchTime = time;
            _searchTime = 15 + random 30;
            _turnDir = [1, -1] select floor random 2;
            _angle = getDir _vehicle;
            while {time < _startSearchTime + _searchTime} do {
                _glanceTime = 1 + random 6;
                _startGlanceTime = time;
                _i = 0;
                while {time < _startGlanceTime + _glanceTime} do {
                    if (!isNull _gunner) then {
                        if ([_gunner] call _fnc_hasDetectedEnemies) then {
                            _detectedEnemies = true;
                            breakTo "mainScope";
                        };
                        if (_i == 0) then {
                            [_gunner, _angle] call _fnc_LookInDirection;
                        };
                    };
                    if (!isNull _commander) then {
                        if ([_commander] call _fnc_hasDetectedEnemies) then {
                            _detectedEnemies = true;
                            breakTo "mainScope";
                        };
                        if (_i == 0) then {
                            [_commander, _angle] call _fnc_LookInDirection;
                        };
                    };

                    _vehicle limitSpeed 0;
                    sleep 0.05;
                    _i = _i + 1;
                };

                _angle = _angle + (10 + random 120) * _turnDir;
                if (_angle > 360) then {
                    _angle = _angle - 360;
                };
            };

            if (!isNull _gunner) then {
                [_gunner, getDir _vehicle] call _fnc_LookInDirection;
            };
            if (!isNull _commander) then {
                [_commander, getDir _vehicle] call _fnc_LookInDirection;
            };

            _startTime = time;
            _waitTime = 2;
            while {time < _startTime + _waitTime} do {
                _vehicle limitSpeed 0;
                sleep 0.05;
            };

            if (!isNull _gunner) then {
                if ([_gunner] call _fnc_hasDetectedEnemies) then {
                    _detectedEnemies = true;
                    breakTo "mainScope";
                };
            };
            if (!isNull _commander) then {
                if ([_commander] call _fnc_hasDetectedEnemies) then {
                    _detectedEnemies = true;
                    breakTo "mainScope";
                };
            };

            if (!isNull _gunner) then {
                _gunner doWatch objNull;
            };
            if (!isNull _commander) then {
                _commander doWatch objNull;
            };

            _startTime = time;
            _waitTime = 2;
            while {time < _startTime + _waitTime} do {
                _vehicle limitSpeed 0;
                sleep 0.05;
            };
        };

        _startTime = time;
        _waitTime = _minTimeBetweenStopsSek + random (_maxTimeBetweenStopsSek - _minTimeBetweenStopsSek);
        while {time < _startTime + _waitTime} do {
            if (!isNull _gunner) then {
                if ([_gunner] call _fnc_hasDetectedEnemies) then {
                    _detectedEnemies = true;
                    breakTo "mainScope";
                };
            };
            if (!isNull _commander) then {
                if ([_commander] call _fnc_hasDetectedEnemies) then {
                    _detectedEnemies = true;
                    breakTo "mainScope";
                };
            };

            sleep 5;
        };
    };

    if (_detectedEnemies) then {
        (group _vehicle) setBehaviour "COMBAT";
        (group _vehicle) setCombatMode "RED";
    };
};


drn_fnc_Escape_AddRemoveComCenArmor = {
    private ["_comCenArmorIndex", "_armorClasses", "_armorObjects"];
    private ["_comCenArmorItem", "_result", "_pos", "_crew"];

    _comCenArmorIndex = _this select 0;

    _comCenArmorItem = a3e_arr_Escape_ComCenArmors select _comCenArmorIndex;

    _pos = _comCenArmorItem select 0;
    _armorClasses = _comCenArmorItem select 1;
    _armorObjects = _comCenArmorItem select 2;

    if (count _armorObjects == 0) then {
        private ["_spawnedArmors", "_vehicle", "_group", "_waypoint", "_roadSegments", "_spawnPos"];

        _spawnedArmors = [];

        {
            _roadSegments = (_pos nearRoads 250);
            if (count _roadSegments == 0) then {
				_roadSegments = (_pos nearRoads 500);
			};
			if (count _roadSegments == 0) then {
				_roadSegments = (_pos nearRoads 1000);
			};
            _spawnPos = getPos (_roadSegments select floor random count _roadSegments);
            _result = [_spawnPos, 0, _x, A3E_VAR_Side_Opfor] call BIS_fnc_spawnVehicle;
            _vehicle = _result select 0;
            _crew = _result select 1;
            _group = _result select 2;

            {
                _x call drn_fnc_Escape_OnSpawnGeneralSoldierUnit;
            } foreach _crew;

            _waypoint = _group addWaypoint [_pos, 70];
            _waypoint setWaypointType "GUARD";
            _waypoint setWaypointBehaviour "AWARE";
            _waypoint setWaypointCombatMode "YELLOW";

            _spawnedArmors set [count _spawnedArmors, _vehicle];
        } foreach _armorClasses;

        _comCenArmorItem set [2, _spawnedArmors];
    }
    else {
        private ["_group"];

        {
            _group = group _x;

            {
                deleteVehicle _x;
            } foreach crew _x;

            deleteVehicle _x;
            deleteGroup _group;
        } foreach _armorObjects;

        _comCenArmorItem set [2, []];
    };
};

drn_fnc_Escape_InitializeComCenArmor = {
    private ["_referenceGroup", "_comCenPositions", "_enemySpawnDistance", "_enemyFrequency"];
    private ["_index", "_pos", "_trigger"];

    _referenceGroup = _this select 0;
    _comCenPositions = _this select 1;
    _enemySpawnDistance = _this select 2;
    _enemyFrequency = _this select 3;

    a3e_arr_Escape_ComCenArmors = [];
    _index = 0;

    {
        _pos = _x;

        switch (_enemyFrequency) do
        {
            case 1:
            {
                a3e_arr_Escape_ComCenArmors set [count a3e_arr_Escape_ComCenArmors, [_pos, [a3e_arr_ComCenDefence_lightArmorClasses select floor random count a3e_arr_ComCenDefence_lightArmorClasses], []]];
            };
            case 2:
            {
                a3e_arr_Escape_ComCenArmors set [count a3e_arr_Escape_ComCenArmors, [_pos, [a3e_arr_ComCenDefence_heavyArmorClasses select floor random count a3e_arr_ComCenDefence_heavyArmorClasses], []]];
            };
            default
            {
                a3e_arr_Escape_ComCenArmors set [count a3e_arr_Escape_ComCenArmors, [_pos, [a3e_arr_ComCenDefence_lightArmorClasses select floor random count a3e_arr_ComCenDefence_lightArmorClasses, a3e_arr_ComCenDefence_heavyArmorClasses select floor random count a3e_arr_ComCenDefence_heavyArmorClasses], []]];
            };
        };

        _trigger = createTrigger["EmptyDetector", _pos];
        _trigger triggerAttachVehicle [units _referenceGroup select 0];
        _trigger setTriggerArea[_enemySpawnDistance + 50, _enemySpawnDistance + 50, 0, false];
        _trigger setTriggerActivation["MEMBER", "PRESENT", true];
        _trigger setTriggerTimeout [2, 2, 2, true];
        _trigger setTriggerStatements["this", "_nil = [" + str _index + "] spawn drn_fnc_Escape_AddRemoveComCenArmor;", "_nil = [" + str _index + "] spawn drn_fnc_Escape_AddRemoveComCenArmor;"];

        _index = _index + 1;
    } foreach _comCenPositions;
};

drn_fnc_Escape_FindSpawnSegment = {
    private ["_referenceGroup", "_minSpawnDistance", "_maxSpawnDistance"];
    private ["_refUnit", "_roadSegments", "_roadSegment", "_isOk", "_tries", "_result", "_spawnDistanceDiff", "_refPosX", "_refPosY", "_dir", "_tooFarAwayFromAll", "_tooClose"];

    _referenceGroup = _this select 0;
    _minSpawnDistance = _this select 1;
    _maxSpawnDistance = _this select 2;

    _spawnDistanceDiff = _maxSpawnDistance - _minSpawnDistance;
    _roadSegment = "NULL";
    _refUnit = vehicle ((units _referenceGroup) select (floor (random (count (units _referenceGroup)))));

    _isOk = false;
    _tries = 0;
    while {!_isOk && _tries < 25 && (!(isNil "_refUnit"))} do {
        _isOk = true;

        _dir = random 360;
        _refPosX = ((getPos _refUnit) select 0) + (_minSpawnDistance + _spawnDistanceDiff) * sin _dir;
        _refPosY = ((getPos _refUnit) select 1) + (_minSpawnDistance + _spawnDistanceDiff) * cos _dir;

        _roadSegments = [_refPosX, _refPosY] nearRoads (_spawnDistanceDiff);

        if (count _roadSegments > 0) then {
            _roadSegment = _roadSegments select floor random count _roadSegments;

            // Check if road segment is at spawn distance
            _tooFarAwayFromAll = true;
            _tooClose = false;
            {
                private ["_tooFarAway"];

                _tooFarAway = false;

                if ((vehicle _x) distance (getPos _roadSegment) < _minSpawnDistance) then {
                    _tooClose = true;
                };
                if ((vehicle _x) distance (getPos _roadSegment) > _maxSpawnDistance) then {
                    _tooFarAway = true;
                };
                if (!_tooFarAway) then {
                    _tooFarAwayFromAll = false;
                };

            } foreach units _referenceGroup;

            _isOk = true;
            if (_tooClose || _tooFarAwayFromAll) then {
                _isOk = false;
                _tries = _tries + 1;
            };
        }
        else {
            _isOk = false;
            _tries = _tries + 1;
        };
    };

    if (!_isOk) then {
        _result = "NULL";
    }
    else {
        _result = _roadSegment;
    };

    _result
};

drn_fnc_Escape_PopulateVehicle = {
    private ["_vehicle", "_side", "_unitTypes", "_enemyFrequency"];
    private ["_group", "_maxSoldiersCount", "_soldierCount", "_continue", "_unitType", "_insurgentSoldier"];

    _vehicle = _this select 0;
    _side = _this select 1;
    _unitTypes = _this select 2;
    if (count _this > 3) then { _enemyFrequency = _this select 3; } else { _enemyFrequency = 3; };

    _maxSoldiersCount = _enemyFrequency + 3 + floor random (4 * _enemyFrequency);
    _group = createGroup _side;

    _soldierCount = 0;

    // Driver
    _continue = true;
    while {_continue && (_soldierCount <= _maxSoldiersCount)} do {
        _unitType = _unitTypes select floor random count _unitTypes;
        _insurgentSoldier = _group createUnit [_unitType, [0,0,0], [], 0, "FORM"];

        _insurgentSoldier setRank "LIEUTNANT";
	_insurgentSoldier call drn_fnc_Escape_OnSpawnGeneralSoldierUnit;
        _insurgentSoldier moveInDriver _vehicle;

        if (vehicle _insurgentSoldier != _insurgentSoldier) then {
            _insurgentSoldier assignAsDriver _vehicle;
            _soldierCount + _soldierCount + 1;
        }
        else {
            deleteVehicle _insurgentSoldier;
            _continue = false;
        };
    };

    // Gunner
    _continue = true;
    while {_continue && _soldierCount <= _maxSoldiersCount} do {
        _unitType = _unitTypes select floor random count _unitTypes;
        _insurgentSoldier = _group createUnit [_unitType, [0,0,0], [], 0, "FORM"];

        _insurgentSoldier setRank "LIEUTNANT";
	_insurgentSoldier call drn_fnc_Escape_OnSpawnGeneralSoldierUnit;
        _insurgentSoldier moveInGunner _vehicle;

        if (vehicle _insurgentSoldier != _insurgentSoldier) then {
            _insurgentSoldier assignAsGunner _vehicle;
            _soldierCount + _soldierCount + 1;
        }
        else {
            deleteVehicle _insurgentSoldier;
            _continue = false;
        };
    };

    // Commander
    _continue = true;
    while {_continue && _soldierCount <= _maxSoldiersCount} do {
        _unitType = _unitTypes select floor random count _unitTypes;
        _insurgentSoldier = _group createUnit [_unitType, [0,0,0], [], 0, "FORM"];

        _insurgentSoldier setRank "LIEUTNANT";
	_insurgentSoldier call drn_fnc_Escape_OnSpawnGeneralSoldierUnit;
        _insurgentSoldier moveInCommander _vehicle;

        if (vehicle _insurgentSoldier != _insurgentSoldier) then {
            _insurgentSoldier assignAsCommander _vehicle;
            _soldierCount + _soldierCount + 1;
        }
        else {
            deleteVehicle _insurgentSoldier;
            _continue = false;
        };
    };

    // Cargo
    _continue = true;
    while {_continue && _soldierCount <= _maxSoldiersCount} do {
        _unitType = _unitTypes select floor random count _unitTypes;
        _insurgentSoldier = _group createUnit [_unitType, [0,0,0], [], 0, "FORM"];

        _insurgentSoldier setRank "LIEUTNANT";
	_insurgentSoldier call drn_fnc_Escape_OnSpawnGeneralSoldierUnit;
        _insurgentSoldier moveInCargo _vehicle;

        if (vehicle _insurgentSoldier != _insurgentSoldier) then {
            _insurgentSoldier assignAsCargo _vehicle;
            _soldierCount + _soldierCount + 1;
        }
        else {
            deleteVehicle _insurgentSoldier;
            _continue = false;
        };
    };

    _group
};

if (isServer) then {
    a3e_var_Escape_FunctionsInitializedOnServer = true;
    publicVariable "a3e_var_Escape_FunctionsInitializedOnServer";
};



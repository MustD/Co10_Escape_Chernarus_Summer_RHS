//############################
// Register a function or code to chronos scheduling system
// Param1: Function or Code
// Param2: Call or Spawn (Default Spawn)
// Param3: Interval of calling the function or timeout
// Param4: true, when Timeout (Single call; Default: false)
//############################
params [["_function", "", [""]], ["_calltype", "spawn", [""]], ["_time", 1, [0]], ["_isTimeout", false, [false]]];
private ["_lastCall"];

_lastCall = diag_tickTime;
A3E_CronProcesses pushBack [_function,_calltype, _time, _lastCall, _isTimeout,scriptNull];

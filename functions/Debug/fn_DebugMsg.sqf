params [["_msg", "Empty message", [""]]];
waituntil{time>2};
if(A3E_Debug) then {
	[_msg] remoteExec ["a3e_fnc_systemChat", 0];
	[_msg] remoteExec ["a3e_fnc_rptLog", 0];
};

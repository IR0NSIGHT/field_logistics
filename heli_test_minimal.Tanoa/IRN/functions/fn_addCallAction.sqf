/*
Author: IR0NSIGHT

Description:
Adds ace action to given object (ideally player) to order a helo to supply him.

parameter(s):
0 :
player - player, default: player (optional)
1 :
ARRAY - [[helicopters to use], helipad for RTB, crate to clone (must be airliftable)] 
2 :
STRING - display name of action (defaults to german) (optional)
3 :
ARRAY (strings) - marker names for LZ, idx 0 is always prefix (defaults to "Unterstützung" + russian girls names) (optional)

Returns:
normalized direction.
*/
_lznames = ["Unterstützung ", "Anastasia", "Annika", "Galina", "Irina", "Katina", "Katerine", "Khristina", "Lada", "Lelyah"];
params [
    ["_caller", player, [player]], 	// target for helo
    ["_heliParams", [[supply_helo_01],airport_01,crate_01],[],[3]],
    ["_displayname", "Versorgung anfordern.", ["uwu"]],
    ["_lznames", _lznames, [[]]]
];

_lzPrefix = _lznames select 0;
_lznames = _lznames - [_lzPrefix];
_heliParams params ["_helos","_helipad","_crate"];

//publish helo array for manipulation on runtime
missionNamespace setVariable["IRN_supplyHelos_helos",_helos,true];
missionNamespace setVariable["IRN_supplyHelos_crate",_crate,true];

//create action
_action = [
    "Request supply",
    _displayname,
    "",
    {       
        // action code	//todo give option for random babble.
        (_this select 2) params ["_targetobj", "_lzPrefix", "_lznames", "_helipad"];


        //get crate to transport
        _crate = missionNamespace getVariable ["IRN_supplyHelos_crate",crate_01];


        //get helos, clean out dead ones
        _helos = missionNamespace getVariable ["IRN_supplyHelos_helos",[supply_helo_01]] select {alive _x};
        if (count _helos == 0) exitWith {
            systemChat "Es gibt keinen verfügbaren Hubschrauber.";
        };
        _helo = _helos select 0;


        //call order supply function
        _markername = _lzPrefix + (selectRandom _lznames);
        [_helo,_helipad,_targetobj, _crate, false, _markername] remoteExec ["IRN_fnc_orderSupply", 2, false];

        //wait until helo is RTB to notify caller.
        if (_helo getVariable ["RTB", true]) then {
            [_helo] spawn {
                params["_helo"];
                waitUntil {
                    sleep 10;
                    _done = _helo getVariable ["RTB", true];
                    _done
                };
                systemChat "Hubschrauber wieder einsatzbereit.";
            };
        };
    },//statement
    { //condition
       (_target in (allCurators apply {getAssignedCuratorUnit _x}))
    },
    {}, //child code
    [_caller, _lzPrefix, _lznames,_helipad]
] call ace_interact_menu_fnc_createaction;
["Man", 1, ["ACE_SelfActions"], _action, true] call ace_interact_menu_fnc_addActiontoClass;






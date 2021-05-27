/*
Author: IR0NSIGHT

Description:
Adds ace action to given object (ideally player) to order a helo to supply him.

parameter(s):
0 :
player - player, default: player (optional)
1 :
BOOLEAN - selfaction (true), foreign action (false), default: true (optional)
2 :
strinG - display name of action (defaults to german) (optional)
3 :
ARRAY (strings) - marker names for LZ, idx 0 is always prefix (defaults to "Unterstützung" + russian girls names) (optional)
Returns:
normalized direction.
*/
_lznames = ["Unterstützung ", "Anastasia", "Annika", "Galina", "Irina", "Katina", "Katerine", "Khristina", "Lada", "Lelyah"];
params [
    ["_caller", player, [player]], 	// target for helo
    ["_selfaction", true, [true]],
    ["_displayname", "Versorgung anfordern.", ["uwu"]],
    ["_lznames", _lznames, [[]]]	// todo is this allowed?
];

_lzPrefix = _lznames select 0;
_lznames = _lznames - [_lzPrefix];
_helo = supply_helo_01;
_crate = crate_01;

diag_log["[_caller, _lzPrefix, _lznames, _helo, _crate]", [_caller, _lzPrefix, _lznames, _helo, _crate]];
_action = [
    "Request supply",
    _displayname,
    "",
    {
        // action code	//todo give option for random babble.
        diag_log ["helo order action was called with: ", _this];
        (_this select 2) params ["_targetobj", "_lzPrefix", "_lznames", "_helo", "_crate"];
        
        _markername = _lzPrefix + (selectRandom _lznames);
        diag_log["helo: ", _helo];
        [_targetobj, _crate, false, _markername] remoteExec ["IRN_fnc_orderSupply", 2, false];
        // [player, crate_01, false, _markername] execVM "order_supply.sqf";
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
    },
    {
        true
    },
    {},
    [_caller, _lzPrefix, _lznames, _helo, _crate]
] call ace_interact_menu_fnc_createaction;
[typeOf player, 1, ["ACE_Selfactions", "ACE_Equipment"], _action] call ace_interact_menu_fnc_addActiontoClass;
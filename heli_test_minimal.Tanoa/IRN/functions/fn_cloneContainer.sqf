/*
Author: IR0NSIGHT

Description:
Will clone a container with all its inventory and ace cargo (and their inventory and ace cargo etc).

parameter(s):
0 :
OBJECT - original container to clone
1 (optional):
OBJECT - container to use instead of new clone
Returns:
clone
*/
params [
    ["_crate", objNull, [objNull]],
    ["_clone", objNull, [objNull]]
];
// todo param selection
if (isNull _crate) exitwith {
    ["target object is nil."] call BIS_fnc_error;
};

// crate object clone
if (isNull _clone) then {
    _clone = (typeOf _crate) createvehicle (getPos _crate);
    _clone setPos ([getPos _crate, 1, 30, 2] call BIS_fnc_findSafePos);
    [_clone] call IRN_fnc_clearContainer;
    // diag_log "creating new clone container.";
    // _clone enableSimulationGlobal false;
};

private ["_items", "_mags", "_weapons", "_containers", "_backpackitems"];
_items = getitemCargo _crate;
_mags = getmagazineCargo _crate;
_weapons = weaponsItemsCargo _crate;
_containers = everyContainer _crate;
// _backpackitems = backpackCargo _crate;
// diag_log [_items, _mags, _weapons, _containers, _backpackitems];

{
    _arr = _x;
    _itemtypes = _x select 0;
    _itemcounts = _x select 1;
    {
        _item = _x;
        _count = _itemcounts select _forEachindex;
        _clone additemCargoGlobal [_item, _count];
    } forEach (_itemtypes);
} forEach [_items, _mags];

{
    _clone addWeaponwithAttachmentsCargoGlobal [_x, 1];
} forEach _weapons;

if (count _containers != 0) then {
    {
        _type = _x select 0;
        // diag_log ["adding container: ", _type, " is backpack: ", (_type in _backpackitems)];
        if (_type in _backpackitems) then {	//TODO does it work on backpacks?
            _clone addbackpackCargoGlobal [_type, 1];
        } else {
            _clone additemCargoGlobal [_type, 0];
            // !needs to be zero, otherwise double added. idk why
        };
    } forEach _containers;
    _backpacksClone = everyContainer _clone;
    {
        // find a container of same type, delete from list.
        _orgtype = _x select 0;
        _temp = _backpacksClone select {
            (_x select 0) isEqualto _orgtype
        };
        // diag_log ["temp: ", _temp];
        _cloneContainer = _temp select 0 select 1;
        _backpacksClone = _backpacksClone - [_cloneContainer];
        // diag_log ["recurse into backpack:", _cloneContainer];
        [_cloneContainer] call IRN_fnc_clearContainer;
        [_x select 1, _cloneContainer] call IRN_fnc_cloneContainer;
    } forEach _containers;
    // diag_log ["done for: ", typeOf _crate];
};

private _loaded = _crate getVariable ["ace_cargo_loaded", []];
// copy over ace cargo values
_size = [_crate] call ace_cargo_fnc_getsizeItem;
[_clone, _size] call ACE_cargo_fnc_setsize;

// get total space: spaceleft + size of all loaded
_space = [_crate] call ACE_cargo_fnc_getcargospaceleft;
{
    _space = (_space + ([_x] call ace_cargo_fnc_getsizeItem));
} forEach _loaded;
[_clone, _space] call ACE_cargo_fnc_setSpace;
// diag_log ["size: ", _size, "space: ", _space];

// diag_log ["loaded: ", _loaded];
{
    private _new =[_x] call IRN_fnc_cloneContainer;
    [_new, _clone, true] call ace_cargo_fnc_loadItem;
} forEach _loaded;
_clone
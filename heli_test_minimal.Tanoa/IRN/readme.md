# IRN Helicopter Airlifting supply
This script framework provides the Zeus with an ace selfaction to call a supply helicopter which will copy a crate with all its inventory and ace carge and airlift it to a nearby LZ from where the Zeus is when he calls the supply.

The helicopter has to be defined in a global variable.
The crate has to be defined in a global varialbe.
A helipad where the supply helo RTBs has to be supplied to the script. 

To use the supply script you have to:
- register the functions
- add the action to all players

## register the functions:
Functions are delcared in the description.ext. This is a file that goes into the missions main directoy, if it doesnt exist yet, just rightclick, new file, "description.ext" and paste the code below.
```cpp
class CfgFunctions {
  #include "IRN\functions\func.hpp"
};
```

## add action to all players
create the file "initPlayerLocal.sqf" in your missions main directory, paste code below.
[player,[[supply_helo_01,supply_helo_02],airport_01,crate_01]] call IRN_fnc_addCallAction;

- The first nested array consists of the availalbe supply helicopters, so you can place two helis in the editor and call them "supply_helo_01" and "supply_helo_02".
- place a (vanilla!) helipad (can be an invisible one) and name it "airport_01".
- place an (airliftable crate (vanilla supply cargo net)) and call it "crate_01"
- you can add more or less helos to the array, the function will pick the lowest index (left most in array), and also sort out non alive/not existent ones.
- to make your life easier, you can clear all inventory out of any cargo box by pasting this code in its init field:
```sqf
[this] call IRN_fnc_clearContainer;
```


## manage crates and helos during mission
if you loose your supply helo or crate by accident, you can assign new ones to airlift.
Spawn a new crate, execute this code on the crate:
missionNamespace setVariable["IRN_supplyHelos_crate",_this,true];
(to clear out all inventory run this code:
[_this] call IRN_fnc_clearContainer;
)
Spawn a new heli, execute this code on the heli:


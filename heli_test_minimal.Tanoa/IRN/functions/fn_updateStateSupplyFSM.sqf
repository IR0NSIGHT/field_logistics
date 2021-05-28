//update the helos FSM
params [
	["_helo",objNull,[objNull]],
	["_dangerType",0,[0]], //danger type 0 = none, 1 = ground, low danger, 2 = air, high, 3 = ground AA, high
	["_supplyOrder",[],[],[0,3]] //order = [object to transport, target destination, state] (state = "success"/"pickup"/"deliver"/"failed")
];

diag_log["_this",_this," supply order:",_supplyOrder];
//parse supply order into its variables
_supplyOrder params [
	["_supplyCargo",objNull],
	["_supplyDestination",[0,0,0]],
	["_supplyState",0]	//0 = no order, 1 == cancelled, 
];
//_supplyCargo = _supplyOrder select 0;

private ["_state","_nextState","_heloBasePos"];
_nextState = -1;
_state = _helo getVariable ["IRN_heloSupply_stateFSM",0];
_heloBasePos = _helo getVariable ["IRN_heloSupply_base",[0,0,0]];

//abort if helo cant fly/is dead/in state dead
if (alive _helo || canMove _helo || _state == 5) exitWith {
	_nextState = 5;
	_nextState
};

//get state of helo
switch (_state) do {
	case "value": { };
	case 0: {
		//supply order, go pickup stuff
		if (_danger == 0 && _supplyState != 0) then {
			//TODO waypoint to pickup
			_nextState = 1; //pickup
		};

		//new base assigned, helo still at old one
		if (!(_heloBasePos isEqualTo [0,0,0]) && ((getPos _helo) distance _heloBasePos) < 100) then {
			//TODO waypoint to new base
			_nextState = 3 //RTB bc not at base
		};
	};
	case 1: {
		//RTB bc danger, or order not needed anymore
		if (_danger > 0 || _supplyState == 0 || _supplyState == 1) then {
			//TODO waypoint to base
			_nextState = 3;
		};

		//successfull hook with object
		if (_supplyCargo in (ropeAttachedObjects _helo)) then {
			//TODO wp to dropoff zone
			_nextState = 2;
		}
	};
	case 2: {
		//danger or order cancelled
		if (_danger > 0 || _supplyState == 0 || _supplyState == 1) then {
			//TODO cut ropes + wp to base
			_nextState = 3;
		};

		//successful unhook
		if (ropeAttachedObjects _helo isEqualTo []) then {
			//TODO wp to base
			_nextState = 3;
		};
	};
	case 3: {
		//close to base, start landing there.
		if ((getPos _helo distance2D _heloBasePos) < 50) then {
			//TODO land at base WP
			_nextState = 4;
		}
	};
	case 4: {
		//TODO check if helicopter is landed
		if (true) then {
			//TODO turn off motor
			_nextState = 0;
		};
	};
	default {

	};
};

if (_nextState == -1) then {
	["Helo supply FSM produced invalid state -1 for state: (%0)",_state] call BIS_fnc_error
};
//return
_nextState


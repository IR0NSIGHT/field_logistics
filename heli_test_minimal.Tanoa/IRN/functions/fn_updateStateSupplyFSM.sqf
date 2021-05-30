//update the helos FSM
params [
	["_helo",objNull,[objNull]],
	["_dangerType",0,[0]], //danger type 0 = none, 1 = ground, low danger, 2 = air, high, 3 = ground AA, high
	["_distanceToBase",0,[1234]],	//TODO get rid of this? 
	["_heloBase",[0,0,0],[[]],[3]], //distance to helobase
	["_hookedCargo",[],[[]]], //list of hooked cargo
	["_isLanded",true,[true]],
	["_supplyOrder",[],[[]],[0,3]] //order = [object to transport, target destination, state] (state = "success"/"pickup"/"deliver"/"failed")
];

//diag_log["_this",_this," supply order:",_supplyOrder];
//parse supply order into its variables
_supplyOrder params [
	["_supplyCargo",objNull],
	["_supplyDestination",[0,0,0]],
	["_supplyState",0]	//0 = no order, 1 == cancelled, 
];
//_supplyCargo = _supplyOrder select 0;

_log = {
	params[["_mssg","no mssg",["uwu"]]];
	diag_log[_mssg];
	systemChat _mssg;
};

_clearWP = {
	params["_grp"];
	{
		deleteWaypoint [_grp,0];
	} foreach (waypoints _grp)
};

private ["_state","_nextState"];
_state = _helo getVariable ["IRN_heloSupply_stateFSM",0];
_nextState = _state;



//abort if helo cant fly/is dead/in state dead
if (!(alive _helo) || !(canMove _helo) || _state == 5) exitWith {
	_nextState = 5;
	["helo is dead/no fly"] call _log;	//dead no fly has to go into switch
	_nextState
};

_heloGrp = group driver _helo;
diag_log ["group",_heloGrp];

//get state of helo
switch (_state) do {
	case "value": { };
	case 0: {
		//supply order, go pickup stuff
		if (_dangerType == 0 && _supplyState != -1) then {
			_nextState = 1; //pickup
			["helo is going pickup"] call _log;

			[_heloGrp] call _clearWP;
			_wp = _heloGrp addWaypoint [getPos _supplyCargo,0,0,"pickup"];
			_wp setWaypointType "HOOK";
		};

		//new base assigned, helo still at old one
		if (_distanceToBase > 100) then {
			_nextState = 3; //RTB bc not at base
			["helo go to new base"] call _log;

			//TODO waypoint to new base
			[_heloGrp] call _clearWP;
			_wp = _heloGrp addWaypoint [_heloBase,0,0,"RTB"];
		};
	};
	case 1: {
		//RTB bc danger, or order not needed anymore
		//TODO attach wp to crate
		if (_dangerType > 0 || _supplyState == -1) then {
			_nextState = 3;
			["helo go RTB, danger or aborted order"] call _log;

			
			[_heloGrp] call _clearWP;
			_wp = _heloGrp addWaypoint [_heloBase,0,0,"RTB"];
		};

		//successfull hook with object
		if (_supplyCargo in _hookedCargo) then {
			
			_nextState = 2;
			["helo has picked up, go deliver now"] call _log;

			
			[_heloGrp] call _clearWP;
			_wp = _heloGrp addWaypoint [_supplyDestination,0,0,"dropoff"];
			_wp setWaypointType "UNHOOK";
		}
	};
	case 2: {
		//danger or order cancelled
		if (_dangerType > 0 || _supplyState == -1) exitWith {
			_nextState = 3;
			["cut ropes, helo in danger, RTB"] call _log;

			//TODO cut ropes + wp to base
			_helo setSlingLoad objNull;
			[_heloGrp] call _clearWP;
			_wp = _heloGrp addWaypoint [_heloBase,0,0,"RTB"];
		};
		//todo fallthrough to successfull unhook?

		//successful unhook
		if (!(_supplyCargo in _hookedCargo)) exitWith {
			_nextState = 3;
			["helo has no cargo, RTB"] call _log;

			//TODO wp to base
			[_heloGrp] call _clearWP;
			_wp = _heloGrp addWaypoint [_heloBase,0,0,"RTB"];
		};
	};
	case 3: {
		//close to base, start landing there.
		if (_distanceToBase < 50) then {
			_nextState = 4;
			["helo close to base, LAND"] call _log;

			//TODO land at base WP
			[_heloGrp] call _clearWP;
			//_wp = _heloGrp addWaypoint [_heloBase,0,0,"RTB"];
			_helo land 'LAND';	//didnt work?
		};

		if (_dangerType == 0 && _supplyState != -1) then {
			_nextState = 1;

			//TODO waypoint to pickup
			[_heloGrp] call _clearWP;
			_wp = _heloGrp addWaypoint [getPos _supplyCargo,0,0,"pickup"];
			_wp setWaypointType "HOOK";
		};
	};
	case 4: {
		//TODO check if helicopter is landed
		if (_isLanded) then {

			//TODO turn off motor
			_nextState = 0;
			["helo has landed."] call _log;
		};
	};
	default {

	};
};
if (_state == _nextState) then {
	["no change in helo."] call _log;
};

if (_nextState == -1) then {
	["Helo supply FSM produced invalid state -1 for state: (%0)",_state] call BIS_fnc_error
};

//set next state
_helo setVariable ["IRN_heloSupply_stateFSM",_nextState,true];
diag_log["heli went from state: ",_state,"to",_nextState ,"with danger",_dangerType," supply state",_supplyState];

//return
_nextState


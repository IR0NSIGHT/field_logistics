//update the helos FSM
params [
	["_helo",objNull,[objNull]],
	["_dangerType",0,[0]], //danger type 0 = none, 1 = ground, low danger, 2 = air, high, 3 = ground AA, high
	["_distanceToBase",0,[1234]],	//TODO get rid of this? 
	["_heloBase",objNull,[objNull]], //distance to helobase, MUST BE ASL
	["_hookedCargo",[],[[]]], //list of hooked cargo
	["_isLanded",true,[true]],
	["_supplyOrder",[],[[]],[0,3]] //order = [object to transport, target destination (ASL), state] (state = "success"/"pickup"/"deliver"/"failed")
];

//TODO complain when wrong input
//TODO dropoff close to helobase causes autocompletion of move rtb wp.

//parse supply order into its variables
_supplyOrder params [
	["_supplyCargo",objNull],
	["_supplyDestination",[0,0,0]],
	["_supplyState",0]	//0 = no order, 1 == cancelled, 
];

if (isNull _heloBase) exitWith {
	["helo base is not defined."] call BIS_fnc_error;
};

_log = {
	params[["_mssg","no mssg",["uwu"]]];
	diag_log[_mssg];
	systemChat _mssg;
	//get helos varname => is 
	_subjectID = "IRN_supply";
	_exists = player diarySubjectExists "subjectName";
	if (!_exists) then {
		_index = player createDiarySubject ["IRN_supply","Logistics"];
	};
	_timestamp = [daytime] call BIS_fnc_timeToString;
	_record = _helo getVariable["IRN_supply_record", player createDiaryRecord [_subjectID,[groupId (group _helo)," UWU! "]]];

	_timestamp +" - "+ _mssg
	_helo setVariable["IRN_supply_record",_record,false];
};

_clearWP = {
	params["_grp"];
	{
		deleteWaypoint [_grp,0];
	} foreach (waypoints _grp)
};

_setDeliverWP = {
	[_heloGrp] call _clearWP;
	_wp = _heloGrp addWaypoint [_supplyDestination,-1,0,"dropoff"];
	_wp setWaypointType "UNHOOK";
};

_setRTP_WP = {
	[_heloGrp] call _clearWP;
	_wp = _heloGrp addWaypoint [_heloBase,-1,0,"RTB"];
	_wp setWaypointCompletionRadius 5;
	_wp setWaypointTimeout [5, 5, 5];
};

//correct false destination position
if (ASLToAGL _supplyDestination select 2 < 0) then {
//	["supply destination is below map."] call _log;
	_supplyDestination = [
		_supplyDestination select 0,
		_supplyDestination select 1,
		getTerrainHeightASL _supplyDestination
	];
};

private ["_state","_nextState"];
_state = _helo getVariable ["IRN_heloSupply_stateFSM",0];
_nextState = _state;



//abort if helo cant fly/is dead/in state dead
if (!(alive _helo) || !(canMove _helo) || _state == 5) exitWith {
	_nextState = 5;
	["Helo can't fly."] call _log;	//dead no fly has to go into switch
	_nextState
};

_heloGrp = group driver _helo;
diag_log ["group",_heloGrp];

//get state of helo
switch (_state) do {
	case "value": { };
	case 0: {
		//supply order, go pickup stuff
		if (_dangerType == 0 && _supplyState > 0) exitWith {
			_nextState = 1; //pickup
			["Helo is moving to pickup point."] call _log;

			[_heloGrp] call _clearWP;
			_wp = _heloGrp addWaypoint [getPosASL _supplyCargo,-1,0,"pickup"];
			_wp waypointAttachVehicle _supplyCargo;
			_wp setWaypointType "HOOK";
		};

		//new base assigned, helo still at old one
		if (_distanceToBase > 100) exitWith {
			_nextState = 3; //RTB bc not at base
			["Helo is moving to new base."] call _log;

			//TODO waypoint to new base
			[_heloGrp] call _clearWP;
			_wp = _heloGrp addWaypoint [_heloBase,-1,0,"RTB"];
			
		};
	};
	case 1: {
		//RTB bc danger, or order not needed anymore
		//TODO attach wp to crate
		if (_dangerType > 0 || _supplyState <= 0) exitWith {
			_nextState = 3;
			["Danger/Order cancelled. RTB"] call _log;
			_supplyState = -1;	//aborted //TODO refine supply states.
			
			[_heloGrp] call _clearWP;
			_wp = _heloGrp addWaypoint [_heloBase,-1,0,"RTB"];
		};

		//successfull hook with object
		if (_supplyCargo in _hookedCargo) exitWith {
			
			_nextState = 2;
			["Cargo is hooked. Moving to target destination."] call _log;

			
			[] call _setDeliverWP;
		}
	};
	case 2: {
		//danger or order cancelled
		if (_dangerType > 0 || _supplyState <= 0) exitWith {
			_nextState = 3;
			["Danger/order cancelled. Cutting ropes, RTB"] call _log;
			_supplyState = -2;	//LOST
			//TODO cut ropes + wp to base
			_helo setSlingLoad objNull;
			[_heloGrp] call _clearWP;
			_wp = _heloGrp addWaypoint [_heloBase,-1,0,"RTB"];
		};
		//todo fallthrough to successfull unhook?
		//TODO test if cargo is actually at destination.
		//successful unhook
		if (!(_supplyCargo in _hookedCargo)) exitWith {
			_nextState = 3;
			["Helo dropped off cargo, RTB"] call _log;
			_supplyState = 0;	//SUCCESS
			//TODO wp to base
			[_heloGrp] call _clearWP;
			_wp = _heloGrp addWaypoint [_heloBase,-1,0,"RTB"];
			_wp setWaypointCompletionRadius 5;
		};

		//make sure the WP is still at the wanted coords
		if (_supplyState > 0 && ((waypointPosition [_heloGrp,0]) distance2D _supplyDestination) > 5) exitWith {
			//waypoint is off. recreate WP.
			["Redirecting Helo to base."] call _log;
			[] call _setDeliverWP;
		}
	};
	case 3: {
		//close to base, start landing there.
		if (_distanceToBase < 10) exitWith {
			_nextState = 4;
			["Landing at base."] call _log;

			//TODO land at base WP
			[_heloGrp] call _clearWP;
			//_wp = _heloGrp addWaypoint [_heloBase,0,0,"RTB"];
			_helo land "LAND";	//didnt work?
		};

		if (_dangerType == 0 && _supplyState > 0) exitWith {
			_nextState = 1;
			_supplyState = 1;	//pickup on the way

			["Order received. Moving to pickup point"] call _log;

			//TODO waypoint to pickup
			[_heloGrp] call _clearWP;
			_wp = _heloGrp addWaypoint [getPosASL _supplyCargo,-1,0,"pickup"];
			_wp waypointAttachVehicle _supplyCargo;
			_wp setWaypointType "HOOK";
		};

		//make sure helo has an RTB WP.
		if (waypoints _heloGrp isEqualTo [] || (waypointPosition [_heloGrp,0] distance2D _heloBase) > 5) then {
			["Redirecting to base."] call _log;
		};

	};
	case 4: {
		//TODO check if helicopter is landed
		if (_isLanded) exitWith {

			//TODO turn off motor
			_nextState = 0;
			["Helo is landed at base."] call _log;
		};
	};
	default {

	};
};
if (_state == _nextState) then {
	systemChat "no change.";
};

if (_nextState == -1) then {
	["Helo supply FSM produced invalid state -1 for state: (%0)",_state] call BIS_fnc_error
};

//set next state
_helo setVariable ["IRN_heloSupply_stateFSM",_nextState,true];
diag_log["heli went from state: ",_state,"to",_nextState ,"with danger",_dangerType," supply state",_supplyState];

//return
[_nextState,_supplyState];


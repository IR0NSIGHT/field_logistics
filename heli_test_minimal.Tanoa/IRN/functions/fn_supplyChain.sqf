//init the central savepoint for supply orders.
systemChat "supply chain init";
diag_log "supply chain init";
//create diary stuff
if (!(player diarySubjectExists "subjectName")) then {
	player createDiarySubject ["IRN_supply","Logistics"];
};


/*centralised supply chain manager:
- holds all orders
- decides which order should be delivered by which helicopter
- updates orders
*/
_log = {
	params["_mssg"];
	systemChat _mssg;
	diag_log _mssg;
};

//loop
SupplyChainRun = true;
//holds all orders. 
//TODO add time stamp, add priority
OrderQueue = [
	[crate_01,[1000,1000,0],1]
];

//finished orders
FinishedOrders = [];

//fleet of available helicopters
_heloFleet = [
	[supply_helo_01,airport_01],
	[supply_helo_02,airport_02]
];

//active orders by helicopters. helos autopull from here.
supplyOrders = createHashMap;
//supplyOrders set [vehicleVarName supply_helo_02, [crate_01,[1000,0,1000],0]];
publicVariable "supplyOrders";

while {SupplyChainRun} do {
	//make sure helo fleet have running FSMs
	
	{
		_helo = _x select 0;
		_state = _helo getVariable ["IRN_heloSupply_stateFSM",-1];
		if (_state == -1) then {
			[_helo,getPosAsl airport_01,0] spawn IRN_fnc_initHeloFSM;
			["helo" + groupId (group _helo) + " had FSM started."] call _log;
		}
	} foreach _heloFleet;

	//assign orders to helos
	{
		_skip = false;
		_queuedOrder = _x;
		_queuedOrder params ["_obj","_pos","_state"];
		_orderIdx = _foreachIndex;
		//get queued order
		//find available heli that can carry out order
		{
			_helo = _x select 0;
			_currentOrder = supplyOrders getOrDefault [(vehicleVarName _helo),[objNull,[0,0,0],-404]];
			if (_currentOrder select 2 < 1 && (_helo canSlingLoad _obj)) exitWith {
				//helo has no active order, object in order exists, and can be transported.
				supplyOrders set [vehicleVarName _helo, _queuedOrder];
				["helo" + groupId (group _helo)+ " was assigned: "+str _queuedOrder] call _log;
				OrderQueue deleteAt _orderIdx; 
			};
			//else
			["helo " + groupId (group _helo)+ "not suited for " + str _queuedOrder] call _log;

		} forEach _heloFleet;
		//add order to heli
	} forEach OrderQueue;

	//clean up active order list:
	{
		if ((_y select 2) < 1) then {
			supplyOrders deleteAt _x;
			FinishedOrders pushBack _y;
			[_x + " had its order cleared: " + str _y] call _log;
		}
	} forEach supplyOrders;

	["supply chain cycle ++"] call _log;
	sleep 5;
};

{
	OrderQueue pushBack _x;
} foreach [
	[crate_02,getPosASL player,1],
	[quad_01,getPosASL player,1],
	[crate_03,getPosASL player,1],
	[quad_02,getPosASL player,1]
];
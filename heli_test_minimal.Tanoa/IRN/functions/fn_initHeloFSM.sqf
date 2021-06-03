//set helo default state
//set helo base
_pass=params[
	["_helo",objNull,[objNull]],
	["_basePos",[0,0,0],[[]],[3]],
	["_state",0,[1]]
];
diag_log["init helo FSM called with: helo ",_helo," basepos ",_basePos,"state",_state];
if (!_pass) exitWith {
	["helo was given false params: ",_this] call BIS_fnc_error;
};

//set helo state
_helo setVariable ["IRN_heloSupply_stateFSM",_state,true];
_supplyState = 0;

//start update loop
while {alive _helo} do {
	(driver _helo) setSkill 1;
	_supplyOrderMap = missionNamespace getVariable ["supplyOrders",[]];
	if (!(_supplyOrderMap isEqualTo [])) then {
		_order = _supplyOrderMap getOrDefault [vehicleVarName _helo,[objNull,[0,0,0],-404]];
		_arr = ([
			//TODO getDangerType
			_helo,
			0,
			_helo distance2d airport_01,
			airport_01,
			ropeAttachedObjects _helo,
			isTouchingGround _helo,
			_order
		] call IRN_fnc_updateStateSupplyFSM);
		_state = _arr select 0;
		_supplyState = _arr select 1;
		
		//set next state
		_helo setVariable ["IRN_heloSupply_stateFSM",_state,true];

		//update central order list with new supply state.
		if ((_order select 2) != -404) then {
		//	systemChat (" helo "+str _helo + "was given supply state "+str (_order select 2) + " returned (updating): "+ str _supplyState);
			_order set [2,_supplyState];
			_supplyOrderMap set [vehicleVarName _helo,_order];
		}
	};
	
	sleep 5;
}
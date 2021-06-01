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

//set helo basepos (obsolete)
//_helo setVariable ["IRN_heloSupply_base",_basePos,true];

//create diary stuff
_index = player createDiarySubject ["IRN_supply","Logistics"];
_record = player createDiaryRecord ["IRN_supply",[groupId (group _helo),"I am text!"]];

_supplyState = 0;
//TODO remove debug
Order = [crate_01,[1000,0,1000],_supplyState];

//start update loop
while {alive _helo} do {
	(driver _helo) setSkill 1;

	_arr = ([
		//TODO getDangerType
		//auto abort if crate not exist
		supply_helo_02,
		0,
		supply_helo_02 distance2d airport_01,
		airport_01,
		ropeAttachedObjects supply_helo_02,
		isTouchingGround _helo,
		Order
	] call IRN_fnc_updateStateSupplyFSM);
	_state = _arr select 0;
	_supplyState = _arr select 1;

	Order = [Order select 0, Order select 1,_supplyState];


	sleep 5;
}
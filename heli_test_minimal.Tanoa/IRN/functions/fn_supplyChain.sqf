//init the central savepoint for supply orders.
//maps helo vs order
supplyOrders = createHashMap;
supplyOrders set [vehicleVarName supply_helo_02, [crate_01,[1000,0,1000],0]];
publicVariable "supplyOrders";
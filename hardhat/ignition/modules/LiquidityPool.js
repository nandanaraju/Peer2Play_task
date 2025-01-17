const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("LiquidityModule", (m) => {
    const token1Address = "0x50E00bC33d107108D935B07EF7D82594651B1968";
    const token2Address = "0x3070ef83F647838DB86f276c7D9E58B83559a788";

    const pool = m.contract("LiquidityPool", [token1Address, token2Address]);

    return { pool };
});

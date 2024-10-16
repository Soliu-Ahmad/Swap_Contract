import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const SwapTokenModule = buildModule("SwapTokenModule", (m) => {
  const celoToken = m.contract("CeloToken", ["0x0D33Ee49A31FfB9B579dF213370f634e4a8BbEEd"]);

  const usdtToken = m.contract("UsdtToken", ["0x0D33Ee49A31FfB9B579dF213370f634e4a8BbEEd"]);

  const swap = m.contract("SwapToken", [celoToken, usdtToken]);



  return { swap };
});

export default SwapTokenModule;
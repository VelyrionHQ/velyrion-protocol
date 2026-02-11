import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const VelyrionModule = buildModule("VelyrionModule", (m) => {
  const marketplace = m.contract("VelyrionMarketplace");
  return { marketplace };
});

export default VelyrionModule;

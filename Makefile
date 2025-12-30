-include .env
deploy-sepolia:
	forge script script/DeployRaffleFactory.s.sol:DeployRaffleFactory --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvv;
deploy-anvil:
	forge script script/DeployRaffleFactory.s.sol:DeployRaffleFactory --rpc-url $(ANVIL_URL) --private-key $(ANVIL_PRIVATEKEY) --broadcast

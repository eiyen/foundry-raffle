-include .env

deploy-anvil:
	forge script \
	script/Raffle.s.sol:RaffleScript \
	--rpc-url $(ANVIL_RPC_URL) \
	--private-key $(ANVIL_DEFAULT_PRIVATE_KEY) \
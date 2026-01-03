# Drifters Onchain Raffle

## What Problem Does This Contract Solve?
The `RaffleFactory` contract enables Drifters, a shoe store in Buenos Aires, to organize raffles in a transparent and decentralized manner using the Ethereum blockchain. This ensures that the raffles are fair and verifiable thanks to the use of Chainlink VRF (Verifiable Random Function) for generating random numbers.

## Raffle Flow
1. **Raffle Creation:**
   - The admin creates a new raffle specifying the start and end dates.
2. **Participation:**
   - Users can join the raffle during the open period.
3. **Raffle Closure:**
   - Once the participation period ends, the admin can request a winner.
4. **Winner Selection:**
   - Chainlink VRF generates a random number to fairly select the winner.

## Roles
### Admin
- Create new raffles.
- Request the winner of a raffle.
- Configure initial contract parameters.

### Users
- Participate in raffles.
- Check the status of raffles and verify winners.

## How Does Randomness Work?
The contract uses Chainlink VRF (Verifiable Random Function) to ensure that random numbers are unpredictable and verifiable. The process is as follows:
1. The admin requests a random number when a raffle ends.
2. Chainlink VRF responds with a random number that is used to select the winner.
3. This process is completely transparent and auditable on the blockchain.

## Raffle States
- **Pending:** The raffle has been created but is not yet open.
- **Open:** Users can participate.
- **Closed:** The participation period has ended.
- **Finished:** A winner has been selected.

## Events
- `RaffleCreated`: Emitted when a new raffle is created.
- `ParticipantAdded`: Emitted when a user joins a raffle.
- `WinnerSelected`: Emitted when a winner is selected.

These events allow developers to track the state of raffles and user interactions.

## Security Considerations
- **Restricted Access:** Only the admin can create raffles and request winners.
- **Double Participation Prevention:** Users cannot join the same raffle more than once.
- **Reliable Randomness:** Chainlink VRF ensures that results are fair and verifiable.
- **Input Validation:** The contract validates that dates and parameters are correct when creating a raffle.

---

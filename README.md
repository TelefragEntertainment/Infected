# Infected
 Infected mod for Quake.

Humans must fight off the infected hell hounds. Health, ammo, and weapons, can be found randomly around the level.

- Infected gain abilities the longer they live.
	- LEVEL 1 - Corrupt Carapace :Increased Health and Health Recovers After Time.
	- Level 2 - Unholy Adrenaline: Run Faster and Leap Farther.
	- Level 3 - Vile Soul: Explode on death.
	- Level 4 - Vicious Bite: Increased Bite Damage.

## Running The Game
When running the game you will spawn as an Observer. This means you're not part of the game and can float around watching people play. If you wish to play you can use `IMPULSE 110` to spawn as a player. You will need to do this on each map.
### There is a bug with observer switching!
If you switch from Observer to Player and then another player leaves, it seems to throw off the count of total Humans alive, causing the game to get stuck. You can manually change the level to continue play: `changelevel dm2`

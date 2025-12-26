## Bugs to fix
- Chest contents not persisting between sessions
- furnace: items put in furnace are not visible immediately, but are visible after closing and reopening the widget
- furnace: mine and homepage have identical furnace content, need a separate furnace instance for the different pages
- Sometimes when moving from backpack, if dropped around the edges of backpack grid, the item is lost
- not getting coal mine in search for mine
- looks like the probability of finding any mine-type is more or less equal


## Feature additions
- Add a home button on mine page which takes you back to home, saving and persisting mine status
- Show hammerfells and coins on minepage and consume 1 hammerfell on each mine
- Implement to divide the stack into half on long press on a grid. Apply to all grids in backpack, chest and furnace

### Mine
- Add chest to mine page, this chest would be mine's own chest, separate from any other chest
- Add minecart to mine to hold items and when needed to transport to homepage (need logic for that)
- Minecart will behave as a chest, but with the ability to move (behind the scene) and transport the items to homepage
- When minecart reaches homepage, ability to move the items to chest and/or backpack

### Forest
- add forest page with trees to cut and obtain wood
- functionality more or less like mine page
- With backpack available at the bottom
### Craft
- Add widget/page to land for craft
- Decide whether a new page would be better or just a widget
- Add 9x9 grid to place items and create output in output grid
- Keep backpack visible and items movable to/from craft grid by drag-and-drop

### Smithy
- A separate page for smithy,  with button on the homepage
- Smithy will have forge as the main clicker button
- Forge will need a fuel input of coal in a fuel grid (like furnace). Forge is only usable as long as a fuel is burning.
- Forge will have 9x9 grids (like craft) to add items and an output grid (for created items)
- Creating items will need long press clicks on hammer button (which will consume hammerfells)
- Backpack visible at the bottom to transfer the items to and from
- A chest will be there (smithy's own instance) to hold the items







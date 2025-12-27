## Bugs to fix
- Chest contents not persisting between sessions
- furnace: mine and homepage have identical furnace content, need a separate furnace instance for the different pages
- Sometimes when moving from backpack, if dropped around the edges of backpack grid, the item is lost
- looks like the probability of finding any mine-type is more or less equal
- Home button in minepage not taking me back to homepage
- furnace is not working. after adding ore and fuel, no option to start smelting is given and smelting does not start
- mining button in minepage on presshold, image changes to red cross (like when not finding the image file)


## Feature additions
- Show hammerfells and coins on minepage and consume 1 hammerfell on each mine
- Implement to divide the stack into half on long press on a grid. Apply to all grids in backpack, chest and furnace

### Shelves
- the ore and ingot grids on the homepage will now be called left and right shelves. do any refactor for that if needed.
- the shelves will essentially behave like minecraft grids (as implemented in backpack, chest etc) with the following difference: the grid stack will not have an upper cap of max amount of 64, it can hold any amount of a single item.
- need to find a way to transfer items between shelves and chest on homepage


### Mine
- add image of the ore being mined on the mining button on minepage, instead of the ore being mined. The images will be available with these names in assests/image: {coal_ore_block.png, copper_ore_block.png, iron_ore_block.png, silver_ore_block.png, gold_ore_block.png, diamond_ore_block.png, stone_block.png (stone will not have _ore)}
- Add chest to mine page, this chest would be mine's own chest, separate from any other chest
- Add minecart to mine to hold items and when needed to transport to homepage (need logic for that)
- Minecart will behave as a chest, but with the ability to move (behind the scene) and transport the items to homepage
- When minecart reaches homepage, ability to move the items to chest and/or backpack
- add one more mine button on minepage above the first button

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







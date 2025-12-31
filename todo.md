## Bugs to fix
- Hammerfells not consuming when mining
- Home button in minepage not taking me back to homepage first time


## Feature additions
-[deffered] Implement to divide the stack into half on long press on a grid. Apply to all grids in chest and furnace


### Mine
- Add chest to mine page (this will appear as minecart), this chest would be mine's own chest, separate from any other chest to hold items and when needed to transport to homepage (need logic for that)
- chest will have additional behaviour as a minecart,  with the ability to move (behind the scene) and transport the items to homepage
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



I recommend implementing these features one by one in the following order, with testing after each:

[tested] Phase 1: Quick Wins (Low Risk, High Value)
[tested]Show hammerfells and coins on minepage - Simple UI addition, test immediately
[tested] Change mining button to show ore block image - Quick asset swap, easy to test
[tested] Add one more mine button on minepage - Simple duplication of existing functionality

Phase 2: Core Mechanics Enhancement
[tested] Consume 1 hammerfell on each mine - Test economy balance carefully
[tested] Stack splitting on long press - Complex interaction change, needs thorough testing across all grids
[deffered] implement stack split in chest and furnace

[tested] Phase 3: Shelves System (Related Changes) ✅
[tested] Refactor ore/ingot grids to shelves - Rename and restructure
[tested] Implement unlimited stack shelves - New grid behavior
[tested] Shelf ↔ backpack transfer system - New interaction pattern (drag and drop enabled)
[tested] Left shelf ↔ right shelf transfers - Cross-shelf item movement

Phase 4: Mine Expansion (Related Features)
Add mine-specific chest - New persistence instance
Add minecart widget - New UI component
Minecart transport logic - Complex state management
Minecart → homepage transfer - Integration testing needed

Phase 5: New Pages (Largest Changes)
Forest page - Clone and adapt mine page structure
Craft page/widget - New 9x9 grid system, recipe logic needed
Smithy page - Most complex: forge + fuel + 9x9 grid + hammer mechanics




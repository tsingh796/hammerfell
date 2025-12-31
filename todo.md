## Bugs to fix

        
-[lowPriority] Home button in minepage not taking me back to homepage first time



## Feature additions
-[deffered] Implement to divide the stack into half on long press on a grid. Apply to all grids in chest and furnace
-[done] reset buttons not showing (both reset and reset-debug)
    - reset will reset all of these to zero: hammerfell, coins, items in shelves, items in backpack
    - reset-debug will do reset plus:
        - add 10 to hammerfell and each coin
        - add 10 coal, 10 iron-ore, 10 diamond to backpack


### Mine
- Add minecart to mine page. minecart will essentially be a chest for minepage. mincart would be mine's own chest, separate from any other chest to hold items and when needed to transport to homepage (need logic for that)
- minecart will have additional behaviour (then chest),  with the ability to move (behind the scene) and transport the items to homepage
- When minecart reaches homepage, ability to move the items to backpack
[deffered] implement stack split in chest and furnace



### Forest [deffered]
- add forest page with trees to cut and obtain wood
- functionality more or less like mine page
- With backpack available at the bottom


### Craft
- Add widget/page to land for craft
- Decide whether a new page would be better or just a widget
- Add 9x9 grid to place items and create output in output grid
- Keep backpack visible and items movable to/from craft grid by drag-and-drop
- recipe (for craft)


### Smithy
- A separate page for smithy,  with button on the homepage
- Smithy will have forge as the main clicker button
- Forge will need a fuel input of coal in a fuel grid (like furnace). Forge is only usable as long as a fuel is burning.
- Forge will have 9x9 grids (like craft) to add items and an output grid (for created items)
- Creating items will need long press clicks on hammer button (which will consume hammerfells)
- Backpack visible at the bottom to transfer the items to and from
- A chest will be there (smithy's own instance) to hold the items


I recommend implementing these features one by one in the following order, with testing after each:


Phase 4: Mine Expansion (Related Features)
Add mine-specific chest - New persistence instance
Add minecart widget - New UI component
Minecart transport logic - Complex state management
Minecart → homepage transfer - Integration testing needed

Phase 5: New Pages (Largest Changes)
Forest page - Clone and adapt mine page structure
Craft page/widget - New 9x9 grid system, recipe logic needed
Smithy page - Most complex: forge + fuel + 9x9 grid + hammer mechanics




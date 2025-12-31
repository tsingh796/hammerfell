# Hammerfell: Minecraft-Inspired Idle Mining Game

Hammerfell is a Flutter-based idle mining and crafting game inspired by Minecraft. Players can search for mines, mine ores with animated feedback, manage a persistent backpack inventory, smelt ores into ingots, and use a drag-and-drop interface for inventory management. The game is highly configurable via YAML files and supports persistent state across sessions.

## Features

- **Search for Mines:**
  - Players can search for new mines, each with unique ore probabilities.
  - Mines are defined in a YAML config file (`assets/config/game_config.yaml`).
  - The last entered mine is persisted between sessions.

- **Animated Mining:**
  - Long-press to mine ores with cracking animation and haptic feedback.
  - Mining costs resources and yields ores based on weighted probabilities.

- **Backpack Inventory:**
  - Minecraft-style 5-slot backpack for ores and items.
  - Drag-and-drop to move, stack, or split items between slots.
  - Inventory persists between sessions using SharedPreferences.

- **Ore and Ingot Management:**
  - Separate grids for ores, ingots, and backpack.
  - Smelt ores into ingots using the Furnace modal.
  - Coin and resource management for upgrades and crafting.

- **Configurable Game Settings:**
  - Ore probabilities, mine types, and other settings are defined in `assets/config.yml`.
  - Easy to add new ores, mines, or change probabilities by editing the YAML file.

- **Modern UI/UX:**
  - Responsive layout with animated buttons, grid views, and visual feedback.
  - Drag-and-drop inventory with stacking logic and partial moves.
  - Visual and haptic feedback for mining and inventory actions.

## Project Structure

- `lib/main.dart` — Main app entry, state management, navigation, persistent storage, and UI layout.
- `lib/pages/mine_page.dart` — Mine UI, mining logic, backpack grid, and drag-and-drop implementation.
- `lib/modals/furnace_modal.dart` — Furnace modal for smelting ores (extendable for more features).
- `lib/modals/mine_search_modal.dart` — Modal for searching and entering new mines.
- `lib/utils/random_utils.dart` — Weighted random selection utility for mining probabilities.
- `assets/config/game_config.yaml` — YAML configuration for mines, ores, and probabilities.
- `assets/images/` — SVG and PNG assets for ores, ingots, and UI icons.

## Configuration

### Game Settings (YAML)
- Located at `assets/config.yml`.
- Example structure:
  ```yaml
  mines:
    iron:
      iron: 0.7
      stone: 0.3
    gold:
      gold: 0.5
      stone: 0.5
    diamond:
      diamond: 0.2
      stone: 0.8
  ```
- You can add new mines or ores, or adjust probabilities as needed.

### Persistent Storage
- Uses `SharedPreferences` to store:
  - Backpack inventory (as JSON)
  - Ores, ingots, coins
  - Last entered mine (as JSON)
- State is loaded on app start and saved after relevant actions.

## Inventory Drag-and-Drop
- Long-press an item in the backpack to drag it.
- Drop onto another slot to stack (if same type) or move (if empty).
- If the destination is full or a different type, the move is reverted.
- Partial stacking is supported (remaining amount stays in source if destination is partially full).

## Extending the Game
- **Add new ores/mines:** Edit `game_config.yaml` and add new SVG assets.
- **Change inventory size:** Adjust the `backpack` list size in `main.dart` and update grid views.
- **Add new features:** Extend modals, add new pages, or enhance inventory logic as needed.

## Running the App
1. Install Flutter and dependencies.
2. Run `flutter pub get` to fetch packages.
3. Run on your device/emulator:
   ```sh
   flutter run
   ```

## Credits
- Inspired by Minecraft and idle/clicker games.
- Built with Flutter, Dart, and open-source packages.

---

For more details, see the code comments and configuration files. Contributions and suggestions are welcome!

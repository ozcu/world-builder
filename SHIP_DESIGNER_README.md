# Ship Designer System - Phase 2 Complete

## Overview
Complete ship designer system with interactive UI for visual ship construction using tiles and parts.

## Files Created

### Core Data Structures
- `scripts/ship_designer/PartCategory.gd` - Enums for part types, tile types, orientations
- `scripts/ship_designer/ShipTile.gd` - Resource for tiles (corridors, doors, airlocks)
- `scripts/ship_designer/ShipPart.gd` - Resource for functional parts with door system
- `scripts/ship_designer/PartPlacement.gd` - Tracks where parts are placed on grid
- `scripts/ship_designer/ShipDefinition.gd` - Complete ship data with validation

### Mockup System
- `scripts/ship_designer/MockupGenerator.gd` - Generates placeholder sprites
- `scripts/ship_designer/TestDataGenerator.gd` - Creates test tiles and parts
- `scripts/ship_designer/ShipDesignerExample.gd` - Example usage demonstration
- `scripts/ship_designer/ShipRenderer.gd` - Renders ShipDefinition visually

### UI Components (Phase 2)
- `scripts/ship_designer/ShipDesigner.gd` - Main UI controller
- `scripts/ship_designer/GridEditor.gd` - Interactive grid with mouse placement
- `scripts/ship_designer/TilePalette.gd` - Tile selection panel
- `scripts/ship_designer/PartPalette.gd` - Part selection panel
- `scripts/ship_designer/StatsPanel.gd` - Ship statistics display

### Scenes
- `scenes/ShipDesigner.tscn` - Complete UI layout (runnable with F6)
- `scenes/TestShipDesigner.tscn` - Programmatic test scene

## Features Implemented

### Tile System
- Corridors (straight, corner, T-junction, X-junction)
- Standard doors
- Airlocks
- Connection tracking (which sides connect)

### Part System
- **Propulsion**: Small thruster (1x2), Medium thruster (2x2)
- **Energy**: Nuclear reactor (4x4), Energy storage (2x3)
- **Crew**: Bunk beds (2x2), Crew quarters (3x3), Bridge (4x4)
- **Sensors**: Basic sensor (2x2)
- **Utility**: Tractor beam (2x2), Small cargo hold (3x3)
- **Defense**: Armor plate (1x1)

### Door Connection System
- Each part has designated door positions
- Doors must connect to corridor tiles
- Automatic validation when placing parts
- Support for horizontal/vertical orientation

### Validation Rules
- Must have at least one corridor
- Must have at least one crew quarters
- Must have at least one airlock
- All parts must have valid door connections

### Ship Properties
Auto-calculated from parts:
- Total mass
- Thrust power
- Energy capacity
- Crew capacity
- Cargo capacity

## Mockup Sprites

All sprites are procedurally generated colored rectangles:
- **Corridors**: Gray with walls on non-connecting sides
- **Doors**: Brown/orange
- **Airlocks**: Yellow circle
- **Parts**: Color-coded by category with green door indicators
  - Propulsion: Orange
  - Energy: Green
  - Crew: Blue
  - Sensors: Yellow
  - Utility: Purple/Brown
  - Defense: Gray

## Usage Example

```gdscript
# Create ship
var ship = ShipDefinition.new()
ship.ship_name = "My Ship"

# Get test data
var tiles = TestDataGenerator.create_test_tiles()
var parts = TestDataGenerator.create_test_parts()

# Place tiles
ship.set_tile(Vector2i(10, 10), tiles["corridor_straight_v"])
ship.set_tile(Vector2i(10, 11), tiles["airlock"])

# Place part
var placement = PartPlacement.new()
placement.part = parts["thruster_medium"]
placement.grid_position = Vector2i(9, 8)
placement.horizontal = true

if ship.can_place_part(placement):
    ship.add_part(placement)

# Validate
var result = ship.validate()
if result.valid:
    print("Ship is valid!")
else:
    for error in result.errors:
        print("Error: ", error)

# Export
var json = ship.to_json()
```

## Design Specifications

- **Grid Size**: 64x64 cells (fixed)
- **Tile Size**: 32x32 pixels per cell
- **Orientation**: Horizontal or vertical only (no rotation)
- **File Format**: JSON (.ship files)

## Phase 2 UI Features

### Interactive Editor
- **Mouse Placement**: Click to place tiles/parts on grid
- **Hover Preview**: Visual preview showing valid/invalid placement (green/red)
- **Grid Display**: 64x64 grid with 32x32 pixel cells
- **Real-time Rendering**: Ship updates as you build

### Palettes
- **Tile Palette** (left panel): Select corridors, doors, airlocks by category
- **Part Palette** (right panel): Select parts organized by type:
  - Propulsion (thrusters)
  - Energy (reactor, storage)
  - Crew (bunks, quarters, bridge)
  - Sensors
  - Utility (tractor beam, cargo)
  - Defense (armor)

### Toolbar Features
- **Orientation Toggle**: Switch between horizontal/vertical part placement
- **Erase Mode**: Remove tiles or parts
- **Save/Load**: Persist ships to user://test_ship.ship
- **Clear**: Start fresh ship

### Stats Panel (Bottom)
- Real-time display of ship properties:
  - Mass (kg)
  - Thrust (N)
  - Energy capacity (kW)
  - Crew capacity
  - Cargo capacity
- Validation status with error tooltips

### Validation Feedback
- Green preview = valid placement
- Red preview = invalid (doors not on corridors)
- Status indicator shows ship completeness
- Hover over status for error details

## Next Steps (Phase 3 - Future)

1. Add symmetry tools (mirror X/Y)
2. Implement undo/redo
3. Add file dialog for save/load
4. Multi-select for bulk operations
5. Copy/paste sections
6. Ship preview/render to image
7. Integration with runtime ship controller

## How to Use

### Option 1: Interactive UI (Recommended)
1. Open `scenes/ShipDesigner.tscn` in Godot
2. Press F6 to run the scene
3. Use the left panel to select tiles (corridors, doors, airlocks)
4. Click on the grid to place tiles
5. Use the right panel to select parts (thrusters, crew quarters, etc.)
6. Toggle orientation if needed (horizontal/vertical)
7. Click to place parts - they must connect via doors to corridors
8. Watch the bottom panel for real-time stats and validation
9. Use Save/Load buttons to persist your designs

### Option 2: Programmatic Test
1. Open `scenes/TestShipDesigner.tscn`
2. Press F6 to run
3. See console output for validation and stats
4. Visual rendering of programmatically created ship

### Tips
- Parts show green preview when placement is valid (doors connect to corridors)
- Parts show red preview when invalid (doors don't connect)
- Use Erase Mode to remove tiles or parts
- Ship must have: corridor, airlock, and crew bunks to be valid

The system is ready for pixel art sprite replacement - just swap the mockup textures!

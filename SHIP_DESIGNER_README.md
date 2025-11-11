# Ship Designer System - Phase 1A Complete

## Overview
Foundation for the ship designer system with core data structures and mockup sprites.

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

## Next Steps (Phase 2)

1. Create ShipDesigner UI scene
2. Implement GridEditor for visual tile placement
3. Create TilePalette and PartPalette UI
4. Add mouse interaction for placing tiles/parts
5. Add symmetry tools
6. Add save/load functionality

## Testing

Run `ShipDesignerExample.gd` to see the system in action:
- Creates a simple ship with corridors, airlock, thruster, and bunks
- Validates the ship
- Prints stats and JSON export

All core data structures are ready for UI development!

# World Builder - Godot Solar System Generator

A procedural 2D solar system generator with realistic planet types, orbital mechanics, and dynamic lighting.

## Project Structure

```
world-builder/
├── scenes/              # Scene files (.tscn)
│   ├── Main.tscn       # Main solar system scene
│   ├── Planet2D.tscn   # Planet prefab
│   └── Sun2D.tscn      # Sun prefab
│
├── scripts/            # GDScript files (.gd)
│   ├── SolarSystem.gd        # Main controller for solar system
│   ├── OrbitalBody.gd        # Elliptical orbit mechanics
│   └── Planet2DGenerator.gd  # Planet generation & customization
│
├── shaders/            # Shader files (.gdshader)
│   ├── Planet2D.gdshader     # Procedural planet surface
│   ├── Clouds2D.gdshader     # Cloud layer
│   ├── Atmos2D.gdshader      # Atmospheric scattering
│   ├── Rings2D.gdshader      # Planetary rings
│   └── Sun2D.gdshader        # Animated sun surface
│
└── assets/
    ├── textures/       # Image files
    │   └── planet.png  # Base planet texture
    └── materials/      # Material resources
        └── white1x1.tres  # Utility texture for shaders
```

## Features

- **8 Planet Archetypes**: Earthlike, Desert/Mars, Ice, Ocean, Venus, Gas/Uranus, Gas/Neptune, Gas/Saturn
- **Procedural Generation**: Each planet has unique terrain, clouds, and atmospheric effects
- **Orbital Mechanics**: Elliptical orbits with configurable periods and eccentricity
- **Dynamic Lighting**: Sun-based lighting that updates as planets orbit
- **Planet Rotation**: Procedural surface rotation independent of orbital motion
- **Auto Camera**: Automatically zooms to fit the entire solar system

## Usage

Run `scenes/Main.tscn` to see the solar system in action.

### Customizing Planets

Select any `Planet2D` instance and modify:
- `archetype`: Choose from 8 planet types
- `seed`: Change for different terrain generation
- `spin_enabled`: Toggle planet rotation

### Customizing Orbits

Select any `Orbit` node and modify:
- `semi_major_axis` / `semi_minor_axis`: Orbit size and eccentricity
- `orbital_period`: Time for one complete orbit (seconds)
- `clockwise`: Orbit direction
- `start_angle`: Initial position on orbit

## Technical Details

- Built with Godot 4.5
- Uses procedural noise (FBM) for terrain generation
- Shader-based planet rendering for performance
- No external dependencies

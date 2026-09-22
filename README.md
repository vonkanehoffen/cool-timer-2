# Cool Timer (Godot)

A native **Godot 4.3+** countdown timer inspired by [Cool Timer](https://github.com/vonkanehoffen/Cool-timer). Set a duration, start the countdown, and watch interchangeable game-style animations visualize the passage of time — while a clear text readout always shows the remaining time.

## Quick start

1. Install [Godot 4.3 or newer](https://godotengine.org/download).
2. Clone this repository and open the project folder in Godot (**Project → Import** or open `project.godot`).
3. Press **F5** (or click **Run Project**) to play.

The main scene is `scenes/main.tscn`.

## Controls

| Control | Behavior |
| -------- | -------- |
| **Duration (H : M : S)** | Editable when idle or completed; locked while running or paused. Range: 1 second – 24 hours. Default: 5 minutes. |
| **Start / Pause / Resume** | Primary action follows timer state. |
| **Reset** | Stops and restores the selected duration. |
| **Animation** | Switch visuals anytime — the countdown keeps running. |

When time reaches zero the timer stops, shows **Time's up!**, plays a short chime, and offers **Start again** with the same duration.

## Architecture

The timer engine and animations are deliberately separate:

```
scripts/
├── timer/
│   ├── timer_engine.gd      # Deadline-based countdown (no drift)
│   └── timer_constants.gd   # Duration limits and status strings
├── animations/
│   ├── animation_props.gd   # Shared props contract
│   ├── animation_base.gd    # Optional base class (duck-typed)
│   ├── animation_registry.gd# Catalogue of animations
│   ├── animation_host.gd    # Mounts selected animation, feeds props
│   ├── plain_progress.gd
│   ├── snake_trail.gd
│   ├── snake_path.gd
│   ├── falling_gems.gd
│   └── gem.gd
└── ui/
    ├── main_screen.gd       # Wires UI ↔ timer ↔ animation host
    ├── time_display.gd      # Formats remaining time text
    └── chime_player.gd      # Completion chime
```

### Timer engine

`TimerEngine` tracks `idle | running | paused | completed` and computes remaining time from a **deadline** (`Time.get_ticks_msec()`), not frame accumulation — so delayed frames do not drift.

The UI reads the engine; animations never drive it.

### Animation props contract

Every animation receives an `AnimationProps` object:

| Field | Meaning |
| ----- | ------- |
| `total_time_sec` | Selected duration (seconds) |
| `time_remaining_sec` | Time left (seconds) |
| `progress` | Elapsed fraction `0.0` – `1.0` |
| `status` | `idle`, `running`, `paused`, or `completed` |

Derive visuals from **`progress`**, not elapsed seconds, so a 24-hour countdown behaves like a 1-minute one. Reconcile toward the target each frame so switching animations mid-countdown renders correctly immediately.

### Animation host

`AnimationHost` loads the scene from `AnimationRegistry`, instantiates it, and calls `apply_animation_props(props)` every frame. Switching animations unmounts one scene and mounts another without touching the timer.

## Included animations

| ID | Name | Style |
| -- | ---- | ----- |
| `plain-progress` | Plain Progress | Simple fill bar — reduced-motion / debug reference |
| `snake-trail` | Neon Snake | 2D serpentine path that fills the grid as time elapses |
| `falling-gems` | Falling Gems | Physics gems drop and stack until the bin is full |

## Adding a new animation

You do **not** need to edit the timer core.

1. **Create a scene** under `scenes/animations/your_animation.tscn` with a script that implements:

   ```gdscript
   extends AnimationBase

   func apply_animation_props(props: AnimationProps) -> void:
       # Draw from props.progress and props.status
       pass
   ```

   Keep animation-specific nodes, physics, and helpers inside your scene folder/script. Clean up in `_exit_tree()` if you spawn runtime nodes.

2. **Register it** in `scripts/animations/animation_registry.gd`:

   ```gdscript
   {
       "id": "your-animation",          # stable — never rename once shipped
       "name": "Your Animation",
       "description": "Short blurb for the selector.",
       "scene_path": "res://scenes/animations/your_animation.tscn",
       "reduced_motion_safe": false,
   }
   ```

3. **Run** — the OptionButton in the main UI picks up registry entries automatically.

### Authoring tips

- **`idle`**: show an empty stage.
- **`running`**: advance/spawn from `progress`.
- **`paused`**: stop advancing progress-driven spawns; keep rendering (physics may continue settling).
- **`completed`**: show the finished visual.
- On reset the host remounts animations when status returns to `idle`.

See the [Cool Timer animation guide](https://github.com/vonkanehoffen/Cool-timer/blob/main/src/animations/README.md) for the original Expo contract and design rationale.

## Layout

Portrait phones stack the animation stage above controls. Wider windows place stage and controls side-by-side. The dark game-style theme lives in `assets/theme/game_theme.tres`.

## License

See repository license. Cool Timer Expo app: [vonkanehoffen/Cool-timer](https://github.com/vonkanehoffen/Cool-timer).

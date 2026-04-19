# M5M-Carbomb-Killswitch - Install Guide

## Requirements
- oxmysql
- ox_lib
- qb-core or qbx_core
- ox_inventory or qb-inventory
- ox_target or qb-target (optional but recommended)

## Supported Compatibility
- Framework: `qbcore`, `qbox`
- Inventory: `ox_inventory`, `qb-inventory`
- Target: `ox_target`, `qb-target`

## Quick Start
1. Place the folder in your resources directory as `M5M-Carbomb-Killswitch`.
2. Import `database.sql` once, or let the resource auto-create its tables on startup.
3. Add the item definitions from `items.lua` or `qb-items.lua`.
4. Review `config/config.lua` first, then the other `config/*.lua` files.
5. Add the resource to your server start order after framework/inventory/target resources.

## Example Start Order
```cfg
ensure oxmysql
ensure ox_lib
ensure qb-core # or qbx_core
ensure ox_inventory # or qb-inventory
ensure ox_target # or qb-target
ensure M5M-Carbomb-Killswitch
```

## ox_inventory item usage
For ox_inventory, keep the `client.export` values from `items.lua` so the items call the resource exports directly.

## qb-inventory / QBCore item usage
Copy the entries from `qb-items.lua` into `qb-core/shared/items.lua`. The resource registers usable items on startup.

## Admin ACE Example
```cfg
add_ace group.admin matrixkillswitch.admin allow
```

## Included working systems in this build
- installable hidden device
- remote menu with tracker, activate/deactivate, and rename actions
- tracker persistence and ping blips
- staged vehicle failure runtime states
- scanner-based detection
- removal flow with detection gating
- server-side action validation
- startup DB creation and migration support

## Recommended Config Edits
- Set `Config.Framework`, `Config.Inventory`, and `Config.Target` explicitly on production servers.
- Review install, trigger, detect, and remove permissions in `config/permissions.lua`.
- Review blacklist and emergency/service vehicle restrictions in `config/blacklist.lua`.
- Review staged malfunction damage/failure mode and EMP timing in `config/effects.lua`.

## Notes
- The resource uses plate-based persistence for linked devices.
- Tracker updates only persist when a vehicle with an installed device is actively being driven and reporting position.
- Target support is optional. Core install/remote/scanner/removal flows are item-driven.


## Updated install items

This version uses separate install items for each device type:

- `killswitch_instant`
- `killswitch_delayed`
- `car_bomb` (icon: `car_bomb.png`)
- `killswitch_emp`

The `killswitch_remote` is now only used for:
- tracker ping
- activating the installed device
- deactivating or clearing the active state

Legacy note:
- `killswitch_device` is still accepted as a backward-compatible fallback and defaults to the instant device behavior.


## Staged malfunction failure modes

The staged device can now run in two modes from `config/effects.lua`:
- `shutdown`: smoke, degradation, and final hard shutdown
- `catastrophic`: heavier engine damage with an optional final fire state

The default in this build is `catastrophic`.


## v0.1.8 note

Staged catastrophic mode now supports continuous fire damage until the game destroys the vehicle. Tune this in `config/effects.lua` under `Config.Effects.staged.catastrophicDamage`.

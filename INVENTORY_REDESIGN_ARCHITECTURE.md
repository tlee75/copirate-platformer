# Inventory System Redesign Architecture
**Project:** Copirate Platformer (Godot 4.5)  
**Date:** October 16, 2025  
**Status:** Phase 1 - Foundation Implementation (In Progress)

## Executive Summary

Redesigning the inventory system from a slot-based drag-and-drop interface to a controller/touch-friendly scroll list system while maintaining full mouse/keyboard compatibility. The new architecture removes artificial slot limitations and implements context-aware item actions.

## Design Goals

### Primary Objectives
- **Controller Focus**: Optimized for gamepad navigation with D-pad/analog stick
- **Touch Friendly**: Large touch targets, swipe gestures, tap interactions
- **Mouse/Keyboard Compatible**: Maintains current functionality for PC users
- **Unified Experience**: Single interface works across all input methods

### Secondary Objectives
- Remove artificial slot limitations
- Eliminate drag-and-drop complexity for non-mouse inputs
- Context-aware item actions (equip, use, drop based on item type)
- Category-based organization with filtering
- Backward compatibility during transition

## Current System Analysis

### Existing Architecture
```
InventoryManager (Autoload) → scripts/systems/inventory_manager_old.gd
├── InventorySlotData class (slot-based storage)
├── Hotbar slots (fixed array)
├── Equipment slots (separate arrays)
└── Signal-based UI updates

InventorySystem → scripts/ui/inventory_system.gd  
├── Drag-and-drop coordinator
├── Slot-to-slot transfers
└── Grid-based UI management

UI Components:
├── Hotbar (bottom bar with item slots)
├── WeaponBar (equipment display)
├── InventorySlot (individual slot UI)
└── Various slot-based interfaces
```

### Current Input Actions
- `interact` (E) - General interaction
- `mouse_left` - Drag initiation, clicking
- Movement keys (WASD) - Character control

### Identified Issues
1. **Controller Navigation**: No D-pad support for inventory
2. **Touch Interface**: Drag-drop requires precise touch control
3. **Slot Limitations**: Artificial constraints from grid system
4. **Equipment Complexity**: Items move between inventory/equipment slots
5. **Action Ambiguity**: Unclear what clicking/tapping will do

## New Architecture Design

### Core Concept: ItemStack-Based Storage
Replace slot-based system with dynamic item stacks that track:
- Item reference + quantity
- Equipment status (equipped_as field)
- Hotbar assignment (hotbar_slot field)
- Lock status (prevent accidental actions)
- Metadata (acquisition date, etc.)

### New Input System
```
inventory_toggle (Tab/L1) - Open/close inventory
inventory_use (E/A) - Context action (use consumable, equip armor, etc.)
inventory_equip (R/X) - Force equip/unequip
inventory_quick_move (Q/L3) - Move to hotbar
inventory_drop (X/Y) - Drop item
inventory_lock (L/R3) - Lock/unlock item
```

### New InventoryManager Architecture
```
InventoryManager (Autoload) → scripts/systems/inventory_manager.gd
├── Core Storage
│   ├── inventory_items: Array[ItemStack]
│   ├── hotbar_assignments: Array[ItemStack] (references)
│   └── equipped_items: Dictionary[String, ItemStack] (references)
│
├── ItemStack Class
│   ├── item: GameItem
│   ├── quantity: int
│   ├── equipped_as: String
│   ├── hotbar_slot: int
│   ├── is_locked: bool
│   └── date_acquired: float
│
├── Core Operations
│   ├── add_item(item, amount)
│   ├── remove_items_by_name(name, amount)
│   ├── remove_stack(stack, amount)
│   └── find_item_stack(name)
│
├── Equipment System
│   ├── equip_item_stack(stack, slot)
│   ├── unequip_item(slot)
│   ├── toggle_equip_item_stack(stack)
│   └── get_equipped_item(slot)
│
├── Hotbar System
│   ├── assign_to_hotbar(stack, slot)
│   ├── remove_from_hotbar(slot)
│   ├── get_hotbar_stack(slot)
│   └── quick_move_to_hotbar(stack)
│
├── Category & Search
│   ├── get_items_by_category(category)
│   ├── get_available_categories()
│   └── search_items(text)
│
├── Item Operations
│   ├── use_item_stack(stack)
│   ├── lock_item_stack(stack)
│   ├── unlock_item_stack(stack)
│   ├── toggle_lock_item_stack(stack)
│   ├── can_drop_stack(stack)
│   └── drop_item_stack(stack, amount)
│
├── Signals
│   ├── inventory_changed
│   ├── hotbar_changed
│   ├── equipment_changed
│   ├── weapon_changed
│   ├── item_equipped(item, slot_type)
│   └── item_unequipped(item, slot_type)
│
└── Backward Compatibility
	├── get_hotbar_slot(index) → CompatibilitySlotData
	├── get_inventory_slot(index) → CompatibilitySlotData
	└── CompatibilitySlotData class
```

### Full System Architecture
```
PlayerMenuManager → scripts/ui/player_menu_manager.gd
├── Input routing (controller/keyboard/touch)
├── Menu state management
├── Navigation between inventory/crafting/etc.
└── Unified action handling

ScrollListInventoryUI → scenes/ui/scroll_list_inventory.tscn
├── Category tabs (All, Tools, Weapons, etc.)
├── Scrollable item list
├── Item details panel
├── Action button context menu
└── Search/filter functionality
```

## Implementation Phases

### Phase 1: Foundation (In Progress)
**Goal**: Replace core inventory system while maintaining backward compatibility

#### ✅ Step 1.1: Input Action Mapping
- Added 6 new input actions with keyboard + controller bindings
- **Status**: COMPLETED

#### ✅ Step 1.2: New Inventory Manager
- Created slot-free ItemStack-based inventory_manager.gd
- Added @tool annotation for editor compatibility
- **Status**: COMPLETED

#### 🔄 Step 1.3: Core System Testing
- Test ItemStack creation and manipulation
- Verify equipment and hotbar systems
- Debug any integration issues
- **Status**: IN PROGRESS

#### ⏳ Step 1.4: Autoload Switch
- Update project.godot autoload from old to new inventory manager
- Test existing game functionality
- **Status**: PENDING

### Phase 2: Action System
**Goal**: Implement context-aware item actions

#### ⏳ Step 2.1: Action Context System
- Create action resolver (determines available actions per item)
- Implement use/equip/drop logic
- Add item interaction feedback
- **Status**: PENDING

#### ⏳ Step 2.2: Input Handling
- Create unified input processor for all device types
- Map input actions to item operations
- Add input method detection and UI adaptation
- **Status**: PENDING

### Phase 3: UI Implementation
**Goal**: Create new scroll list interface

#### ⏳ Step 3.1: PlayerMenuManager
- Create centralized menu management system
- Handle input routing and state management
- **Status**: PENDING

#### ⏳ Step 3.2: Scroll List UI
- Design responsive layout (works on mobile + desktop)
- Implement category filtering
- Add item detail panels
- **Status**: PENDING

#### ⏳ Step 3.3: Touch + Controller Navigation
- Add swipe gestures for touch
- Implement D-pad navigation for controller
- Create focus management system
- **Status**: PENDING

### Phase 4: Enhanced Features
**Goal**: Add advanced functionality

#### ⏳ Step 4.1: Search and Sorting
- Item name search
- Sort by category, name, quantity, date acquired
- Saved filter preferences
- **Status**: PENDING

#### ⏳ Step 4.2: Object Integration
- Update firepit and other object inventories to use new system
- Convert crafting interfaces
- **Status**: PENDING

### Phase 5: Cleanup and Polish
**Goal**: Remove old system and optimize

#### ⏳ Step 5.1: Legacy System Removal
- Remove old inventory_system.gd
- Clean up slot-based UI components
- Remove backward compatibility layer
- **Status**: PENDING

#### ⏳ Step 5.2: Performance and Polish
- Optimize for large inventories
- Add animations and feedback
- Test across all input devices
- **Status**: PENDING

## Technical Implementation Details

### ItemStack Class Structure
```gdscript
class ItemStack:
	var item: GameItem              # Reference to game item
	var quantity: int               # Stack size
	var equipped_as: String = ""    # Equipment slot ("helmet", "main_hand", etc.)
	var is_locked: bool = false     # Prevent accidental operations
	var hotbar_slot: int = -1       # Hotbar position (-1 = not on hotbar)
	var date_acquired: float = 0.0  # For sorting by recent
	
	func is_equipped() -> bool
	func is_on_hotbar() -> bool
	func get_display_name() -> String  # "Iron Sword [Main Hand] 🔒"
```

### Equipment System
- Items remain in main inventory when equipped
- `equipped_as` field tracks which slot they occupy
- Equipment dictionary provides quick lookup: `equipped_items["main_hand"]`
- No item movement between inventory/equipment

### Hotbar System
- Array of ItemStack references: `hotbar_assignments[0..7]`
- Items stay in main inventory, hotbar just references them
- Hotbar updates automatically when items are consumed/dropped

### Input Action Mappings
| Action | Keyboard | Controller | Purpose |
|--------|----------|------------|---------|
| inventory_toggle | Tab | L1 (L) | Open/close inventory |
| inventory_use | E | A | Context action |
| inventory_equip | R | X | Force equip/unequip |
| inventory_quick_move | Q | L3 (L Stick) | Move to hotbar |
| inventory_drop | X | Y | Drop item |
| inventory_lock | L | R3 (R Stick) | Lock/unlock |

### UI Layout Concept
```
┌─────────────────────────────────────────────────────────┐
│ INVENTORY                                        [X]    │
├─────────────────────────────────────────────────────────┤
│ [All] [Tools] [Weapons] [Armor] [Materials] [Food]     │
├─────────────────────────────────────┬───────────────────┤
│ ◀ Iron Sword x1 [Main Hand]         │ IRON SWORD        │
│   Wooden Pickaxe x1                 │ ┌─────────────┐   │
│   Stone x64                          │ │    [IMG]    │   │
│   Stick x32 🔒                       │ └─────────────┘   │
│   Raspberry x8                       │ Damage: 25        │
│   ...                                │ Durability: 95%   │
│                                      │                   │
│                                      │ [USE] [EQUIP]     │
│                                      │ [HOTBAR] [DROP]   │
└─────────────────────────────────────┴───────────────────┘
```

### Context-Aware Actions
Based on item type and current state:

| Item Type | Equipped | Available Actions |
|-----------|----------|-------------------|
| Weapon | No | Use(equip), Equip, Hotbar, Drop |
| Weapon | Yes | Use(unequip), Unequip, Hotbar, Drop |
| Consumable | N/A | Use(consume), Hotbar, Drop |
| Material | N/A | Hotbar, Drop, Craft(if applicable) |
| Tool | No | Use(equip), Equip, Hotbar, Drop |
| Tool | Yes | Use(unequip), Unequip, Hotbar, Drop |

## File Structure Changes

### New Files to Create
```
scenes/ui/
├── player_menu_manager.tscn      # Main menu coordinator
├── scroll_list_inventory.tscn    # New inventory interface
├── inventory_item_entry.tscn     # Individual item row
├── item_detail_panel.tscn        # Item information display
└── category_filter_tabs.tscn     # Filter tab bar

scripts/ui/
├── player_menu_manager.gd        # Menu management logic
├── scroll_list_inventory.gd      # Inventory UI controller
├── inventory_item_entry.gd       # Item row behavior
├── item_detail_panel.gd          # Detail panel controller
├── category_filter_tabs.gd       # Tab management
└── input_handler.gd              # Unified input processing

scripts/systems/
├── inventory_manager.gd          # New slot-free system ✅
├── item_action_resolver.gd       # Context-aware actions
└── inventory_manager_old.gd      # Backup of old system ✅
```

### Files to Modify
```
project.godot                     # Update autoload reference
scripts/player.gd                 # Integrate new input actions
scripts/main_scene.gd            # Menu management integration
scripts/structures/firepit.gd    # Update to new system
scripts/ui/hotbar.gd             # Connect to new system
scripts/ui/weaponbar.gd          # Connect to new system
```

### Files to Eventually Remove
```
scripts/ui/inventory_system.gd   # Old drag-drop coordinator
scripts/ui/inventory_slot.gd     # Slot-based UI component
(Various slot-based UI scenes)   # Grid-based interfaces
```

## Backward Compatibility Strategy

### During Transition
- Keep old system files as backups
- Provide compatibility layer in new InventoryManager
- Maintain existing signal names and interfaces
- Gradual migration of dependent systems

### Compatibility Methods
```gdscript
# In new inventory_manager.gd
func get_hotbar_slot(index: int):  # Returns compatibility object
func get_inventory_slot(index: int):  # Simulates old slot access
class CompatibilitySlotData:       # Mimics old InventorySlotData interface
```

## Risk Mitigation

### Potential Issues
1. **Performance**: Large inventories with many UI elements
2. **Touch Precision**: Small touch targets on mobile
3. **Controller Navigation**: Complex nested menus
4. **Existing Code Dependencies**: Breaking changes to slot-based systems

### Mitigation Strategies
1. **Lazy Loading**: Only render visible items in scroll list
2. **Responsive Design**: Adapt UI size based on screen/input method
3. **Clear Focus Indicators**: Visual feedback for controller navigation
4. **Gradual Migration**: Keep old systems working during transition

## Testing Strategy

### Test Cases by Input Method

#### Mouse & Keyboard
- Click to select items
- Context menus on right-click
- Keyboard shortcuts for common actions
- Scroll wheel navigation

#### Controller
- D-pad navigation through lists
- Face button actions (A=use, X=equip, etc.)
- Trigger shortcuts (L1=inventory, R3=lock)
- Analog stick for quick scrolling

#### Touch
- Tap to select items
- Swipe to scroll lists
- Long-press for context menu
- Pinch to zoom (if applicable)

### Integration Testing
- Equipment system with new storage
- Hotbar updates with item consumption
- Crafting system compatibility
- Object inventory integration
- Save/load game data

## Success Metrics

### User Experience
- Reduced time to find and use items
- Successful navigation with all input methods
- Positive feedback on inventory management
- No loss of existing functionality

### Technical
- Maintain 60 FPS with large inventories
- Memory usage within acceptable limits
- Clean architecture with separated concerns
- Comprehensive test coverage

## Current Status Summary

### ✅ Completed
- Input action definitions
- New inventory manager script structure
- ItemStack class implementation
- Equipment and hotbar reference system
- Backward compatibility layer
- @tool annotation added

### 🔄 In Progress
- Testing new inventory manager functionality
- Core system verification

### ⏳ Next Steps
1. Complete Phase 1 core system testing
2. Update project autoload reference
3. Begin Phase 2 action system implementation
4. Design UI layouts for Phase 3

### 📁 File Status
| File | Status | Notes |
|------|--------|-------|
| `inventory_manager.gd` | ✅ Created | @tool added, ready for testing |
| `inventory_manager_old.gd` | ✅ Backup | Original preserved |
| Input actions | ✅ Added | All 6 actions configured |
| Project autoload | ⏳ Pending | Still points to old system |
| Architecture doc | ✅ Created | This document |

---

*This document serves as the master reference for the inventory redesign project. Update status and add details as implementation progresses.*

import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../wardrobe.dart';

/// The rail of clothes down one side, plus the picture tabs that change slot.
///
/// Kid rules encoded here (CLAUDE.md §3):
///  * **No text.** Tabs are a hat, a face, a coat and a boot; items are pictures.
///  * **Tiles are 120x120** — well past the 80x80 minimum — with 16px gaps, so a
///    coarse finger cannot hit two things at once.
///  * **No scrolling.** Every item in a slot is visible at once; a five-year-old
///    should not have to discover that clothes exist off-screen. This caps a
///    slot at ~4 items, which is why the wardrobe is small on purpose.
///  * **Tapping the worn item takes it off**, so undo needs no separate control.
///  * **Drag is offered as well as tap, never instead of it.** Dragging is the
///    motion a child reaches for with a dressing toy, but it is a harder motor
///    skill — so every item can still be put on with a single tap. A child who
///    cannot yet manage a drag is never locked out of the game.
class WardrobeRail extends StatelessWidget {
  const WardrobeRail({
    super.key,
    required this.slot,
    required this.outfit,
    required this.onSlotChanged,
    required this.onItemTapped,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  final Slot slot;
  final Outfit outfit;
  final ValueChanged<Slot> onSlotChanged;
  final ValueChanged<WardrobeItem> onItemTapped;

  /// So the dog can show it is ready to catch what is coming.
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  static const tileSize = 120.0;

  static const _slotIcons = {
    Slot.head: Icons.emoji_people_rounded,
    Slot.face: Icons.face_rounded,
    Slot.body: Icons.checkroom_rounded,
    Slot.feet: Icons.ice_skating_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final items = Wardrobe.forSlot(slot);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Slot tabs.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in Slot.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _SlotTab(
                  icon: _slotIcons[s]!,
                  selected: s == slot,
                  onTap: () => onSlotChanged(s),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        // The clothes in this slot.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _ItemTile(
                  item: item,
                  worn: outfit[item.slot]?.id == item.id,
                  onTap: () => onItemTapped(item),
                  onDragStarted: onDragStarted,
                  onDragEnded: onDragEnded,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SlotTab extends StatelessWidget {
  const _SlotTab({required this.icon, required this.selected, required this.onTap});

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tap-DOWN everywhere in this game: a five-year-old's finger slides
      // between down and up, and an ignored tap reads as a broken screen.
      onTapDown: (_) => onTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? KidPalette.ink : Colors.transparent,
            width: 4,
          ),
        ),
        child: Icon(icon, size: 44, color: KidPalette.ink),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.worn,
    required this.onTap,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  final WardrobeItem item;
  final bool worn;
  final VoidCallback onTap;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  @override
  Widget build(BuildContext context) {
    final tile = GestureDetector(
      onTapDown: (_) => onTap(),
      child: AnimatedScale(
        // The worn item sits slightly larger and outlined, so "this is on the
        // dog" is visible without a tick, a label or a colour that means right.
        scale: worn ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 160),
        child: Container(
          width: WardrobeRail.tileSize,
          height: WardrobeRail.tileSize,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: worn ? KidPalette.ink : Colors.white.withValues(alpha: 0.8),
              width: worn ? 6 : 4,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Icon(item.icon, size: 60, color: Colors.white),
        ),
      ),
    );

    return Draggable<WardrobeItem>(
      data: item,
      // A plain Draggable, which starts on MOVEMENT. Deliberately not
      // LongPressDraggable: making a child hold still before dragging is a
      // timing skill they do not have, and the wait reads as the tile ignoring
      // them. A tap that slides a little still lands as a tap, because the tap
      // fires on tap-down before any drag begins.
      onDragStarted: onDragStarted,
      // Both end paths, so a missed drop can never leave the dog stuck in its
      // "ready to catch" state.
      onDraggableCanceled: (_, _) => onDragEnded(),
      onDragCompleted: onDragEnded,
      feedback: _DragGhost(item: item),
      // The tile STAYS in the rail while dragging rather than leaving a hole:
      // a vanishing tile reads to a child as having broken something.
      childWhenDragging: Opacity(opacity: 0.45, child: tile),
      child: tile,
    );
  }
}

/// What follows the finger. Deliberately bigger than the tile and slightly
/// rotated, so it reads as "held" and stays visible around a small hand.
class _DragGhost extends StatelessWidget {
  const _DragGhost({required this.item});

  final WardrobeItem item;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        width: WardrobeRail.tileSize * 1.12,
        height: WardrobeRail.tileSize * 1.12,
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white, width: 5),
          boxShadow: const [
            BoxShadow(color: Color(0x44000000), blurRadius: 14, offset: Offset(0, 8)),
          ],
        ),
        child: Icon(item.icon, size: 68, color: Colors.white),
      ),
    );
  }
}

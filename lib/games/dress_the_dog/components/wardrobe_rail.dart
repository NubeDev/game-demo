import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../wardrobe.dart';

/// The rail of clothes down one side, plus the picture tabs that change slot.
///
/// Kid rules encoded here (CLAUDE.md §3):
///  * **No text.** Tabs are a hat, a face, a coat and a boot; items are pictures.
///  * **Tiles are 120x120 where the screen allows**, shrinking with [scale] on a
///    short screen but never below the 80x80 minimum (see [tileSizeFor]) — with
///    proportional gaps, so a coarse finger cannot hit two things at once.
///  * **No scrolling.** Every item in a slot is visible at once; a five-year-old
///    should not have to discover that clothes exist off-screen. This caps a
///    slot at ~4 items, which is why the wardrobe is small on purpose. On a
///    short screen, where one tall column of items will not fit, they wrap into
///    two columns rather than shrinking past a hittable size or scrolling.
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
    this.scale = 1.0,
    this.columns,
  });

  /// How many columns the items wrap into, when the screen wants to fix it.
  /// Left null, the rail works it out from the height it is actually given —
  /// which is what keeps the drawn layout and the screen's reservation for it
  /// from ever disagreeing.
  final int? columns;

  /// Shrinks the whole rail to fit a short screen. 1.0 is the full-size rail;
  /// the screen decides this, not the game (see [DressTheDogScreen]).
  final double scale;

  final Slot slot;
  final Outfit outfit;
  final ValueChanged<Slot> onSlotChanged;
  final ValueChanged<WardrobeItem> onItemTapped;

  /// So the dog can show it is ready to catch what is coming.
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  /// Full-size tile, on a screen with room for it.
  static const tileSize = 120.0;

  /// The 80x80 floor from CLAUDE.md §3. A tile never shrinks past this, however
  /// short the screen — a target a coarse finger cannot hit is not a target.
  static const minTileSize = 84.0;

  static const _tabSize = 84.0;

  /// The 80x80 floor again, for the tabs (CLAUDE.md §3).
  static const _minTabSize = 84.0;
  static const _tileGap = 16.0;
  static const _tabGap = 12.0;

  /// The tab size — always at the kid-rule minimum or above, never smaller.
  static double tabSizeFor(double scale) =>
      (_tabSize * scale).clamp(_minTabSize, _tabSize);

  /// The smallest gap the tabs will close to before they give up on stacking.
  /// The tabs themselves never shrink — only the space between them.
  static const _minTabGap = 4.0;

  /// The gap between stacked tabs in a column [height] tall: the designed gap
  /// where it fits, closing to [_minTabGap] rather than moving the tabs.
  static double stackedTabGapFor(double scale, double height) {
    final spare = height - 4 * tabSizeFor(scale);
    return (spare / 3).clamp(_minTabGap, _tabGap * scale);
  }

  /// The height four stacked tabs need at [scale], with their gaps closed up
  /// as far as they will go.
  static double _tabColumnHeight(double scale) =>
      4 * tabSizeFor(scale) + 3 * _minTabGap;

  /// Whether the slot tabs stack down the side (the designed shape) or sit in
  /// a row above the items.
  ///
  /// Four 84px tabs need ~360px of height, which a landscape phone does not
  /// have once the home button is out of the way. Rather than shrink them
  /// below a size a coarse finger can hit (CLAUDE.md §3), they move to a row
  /// across the top, where there is width to spare. They stay the same size,
  /// the same order and the same pictures — only their direction changes.
  static bool tabsOnTopFor(double scale, double height) =>
      height < _tabColumnHeight(scale);

  /// The tile size at a given [scale], clamped to the kid-rule floor.
  static double tileSizeFor(double scale) =>
      (tileSize * scale).clamp(minTileSize, tileSize);

  /// The most items any one slot holds — the rail is sized for its fullest
  /// slot, so tapping a tab never changes the layout under the child's hands.
  static int get maxItemsInASlot => Slot.values
      .map((s) => Wardrobe.forSlot(s).length)
      .reduce((a, b) => a > b ? a : b);

  /// How many item columns are needed to show [count] items in [height].
  ///
  /// One column is the shape this was designed in. More is the fallback for a
  /// short screen: wrapping is what keeps tiles at a hittable size instead of
  /// shrinking them away, and it stays a no-scroll rail either way.
  ///
  /// [height] is the space left for the TILES — on a short screen the tab row
  /// has already taken its share (see [tilesHeightFor]).
  static int columnsFor(double scale, double height, int count) {
    final tile = tileSizeFor(scale);
    final gap = _tileGap * scale;
    final perColumn = (height + gap) ~/ (tile + gap);
    if (perColumn < 1) return count;
    if (perColumn >= count) return 1;
    return (count / perColumn).ceil();
  }

  /// The height left for the tiles once the tabs have taken theirs.
  static double tilesHeightFor(double scale, double height) {
    if (!tabsOnTopFor(scale, height)) return height;
    return height - tabSizeFor(scale) - _tileGap * scale;
  }

  /// How many items go in each column, given [columns] — the taller column
  /// first, so a 3-item slot reads as 2 then 1 rather than a ragged top.
  static int _rowsPerColumn(int count, int columns) => (count / columns).ceil();

  /// How wide the rail is at [scale] — the screen keeps the dog clear of it.
  static double widthFor(double scale, int columns, bool tabsOnTop) {
    final tiles = columns * tileSizeFor(scale) +
        (columns - 1) * (_tileGap * scale);
    if (tabsOnTop) {
      // A row of four tabs is wider than the tiles below it.
      final tabs = 4 * tabSizeFor(scale) + 3 * (_tabGap * scale);
      return tabs > tiles ? tabs : tiles;
    }
    return tabSizeFor(scale) + 14 * scale + tiles;
  }

  static const _slotIcons = {
    Slot.head: Icons.emoji_people_rounded,
    Slot.face: Icons.face_rounded,
    Slot.body: Icons.checkroom_rounded,
    Slot.feet: Icons.ice_skating_rounded,
  };

  /// The items belonging in column [c], filling each column top to bottom.
  List<WardrobeItem> _columnItems(
    List<WardrobeItem> items,
    int c,
    int columns,
  ) {
    final rows = _rowsPerColumn(maxItemsInASlot, columns);
    final start = c * rows;
    if (start >= items.length) return const [];
    final end = start + rows;
    return items.sublist(start, end > items.length ? items.length : end);
  }

  @override
  Widget build(BuildContext context) {
    final items = Wardrobe.forSlot(slot);
    final tile = tileSizeFor(scale);
    final tabSize = tabSizeFor(scale);

    final tabs = <Widget>[
      for (final s in Slot.values)
        _SlotTab(
          icon: _slotIcons[s]!,
          selected: s == slot,
          size: tabSize,
          onTap: () => onSlotChanged(s),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : _tabColumnHeight(scale);

        final tabsOnTop = tabsOnTopFor(scale, height);
        final stackedGap = stackedTabGapFor(scale, height);

        // Worked out from the height actually given, so what is drawn can
        // never disagree with the space reserved for it.
        final cols = columns ??
            columnsFor(scale, tilesHeightFor(scale, height), maxItemsInASlot);

        // The clothes in this slot, in one column where there is room and more
        // where there is not. Every slot is laid out over the same number of
        // rows as the fullest one, so the rail does not change shape when the
        // child taps a different tab.
        final tileRow = Row(
          mainAxisSize: MainAxisSize.min,
          // TOP-aligned, so a slot with an odd number of items reads as a
          // block with a gap at the end rather than a stair-step.
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _tileGap * scale,
          children: [
            for (var c = 0; c < cols; c++)
              Column(
                mainAxisSize: MainAxisSize.min,
                // `spacing`, not padding on each child: padding would add half
                // a gap above the first tile and below the last, and that
                // spare gap is enough to push the rail off a short screen.
                spacing: _tileGap * scale,
                children: [
                  for (final item in _columnItems(items, c, cols))
                    _ItemTile(
                      item: item,
                      size: tile,
                      worn: outfit[item.slot]?.id == item.id,
                      onTap: () => onItemTapped(item),
                      onDragStarted: onDragStarted,
                      onDragEnded: onDragEnded,
                    ),
                ],
              ),
          ],
        );

        if (tabsOnTop) {
          // Short screen: tabs across the top, still full size.
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: _tileGap * scale,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: _tabGap * scale,
                children: tabs,
              ),
              tileRow,
            ],
          );
        }

        // The designed shape: tabs down the side.
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: stackedGap,
              children: tabs,
            ),
            SizedBox(width: 14 * scale),
            tileRow,
          ],
        );
      },
    );
  }
}

class _SlotTab extends StatelessWidget {
  const _SlotTab({
    required this.icon,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tap-DOWN everywhere in this game: a five-year-old's finger slides
      // between down and up, and an ignored tap reads as a broken screen.
      onTapDown: (_) => onTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(size * 0.26),
          border: Border.all(
            color: selected ? KidPalette.ink : Colors.transparent,
            width: 4,
          ),
        ),
        child: Icon(icon, size: size * 0.52, color: KidPalette.ink),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.size,
    required this.worn,
    required this.onTap,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  final WardrobeItem item;
  final double size;
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
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(size * 0.23),
            border: Border.all(
              color: worn ? KidPalette.ink : Colors.white.withValues(alpha: 0.8),
              width: worn ? 6 : 4,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Icon(item.icon, size: size * 0.5, color: Colors.white),
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
      feedback: _DragGhost(item: item, size: size * 1.12),
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
  const _DragGhost({required this.item, required this.size});

  final WardrobeItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(size * 0.23),
          border: Border.all(color: Colors.white, width: 5),
          boxShadow: const [
            BoxShadow(color: Color(0x44000000), blurRadius: 14, offset: Offset(0, 8)),
          ],
        ),
        child: Icon(item.icon, size: size * 0.5, color: Colors.white),
      ),
    );
  }
}

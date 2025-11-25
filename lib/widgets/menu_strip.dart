import 'package:flutter/material.dart';

class MenuStrip extends StatelessWidget {
  const MenuStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 40,
                color: Colors.grey[900],
                child: Row(
                  children: [
                    _menuButton(context, "File", [
                      "New File",
                      "Open File",
                      "Save",
                      "Exit",
                    ]),
                    _menuButton(context, "Edit", [
                      "Undo",
                      "Redo",
                      "Copy",
                      "Paste",
                    ]),
                    _menuButton(context, "View", [
                      "Zoom In",
                      "Zoom Out",
                      "Full Screen",
                    ]),
                  ],
                ),
              ),
            ],
          ),

          /// CLICK OUTSIDE TO CLOSE
          ValueListenableBuilder<bool>(
            valueListenable: MenuController.menuOpen,
            builder: (_, open, __) {
              if (!open) return SizedBox.shrink();

              return Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => MenuController.closeMenu(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _menuButton(BuildContext context, String title, List<String> items) {
    return _DesktopMenuButton(title: title, items: items);
  }
}

class _DesktopMenuButton extends StatefulWidget {
  final String title;
  final List<String> items;

  const _DesktopMenuButton({required this.title, required this.items});

  @override
  State<_DesktopMenuButton> createState() => _DesktopMenuButtonState();
}

class _DesktopMenuButtonState extends State<_DesktopMenuButton> {
  OverlayEntry? overlay;

  void showMenu() {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    MenuController.closeMenu();
    MenuController.activeTitle = widget.title;

    overlay = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx,
        top: offset.dy + renderBox.size.height,
        child: Material(
          color: Colors.black,
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.items
                .map(
                  (e) => InkWell(
                    onTap: () {
                      MenuController.closeMenu();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(e, style: TextStyle(color: Colors.white)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay!);
    MenuController.currentOverlay = overlay;
    MenuController.menuOpen.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        /// Hover should switch ONLY if already open
        if (MenuController.menuOpen.value &&
            MenuController.activeTitle != widget.title) {
          showMenu();
        }
      },
      child: GestureDetector(
        onTap: () {
          /// Click toggles the menu
          if (!MenuController.menuOpen.value) {
            showMenu();
          } else if (MenuController.activeTitle == widget.title) {
            MenuController.closeMenu();
          } else {
            showMenu();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(widget.title, style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class MenuController {
  static OverlayEntry? currentOverlay;
  static String activeTitle = "";
  static ValueNotifier<bool> menuOpen = ValueNotifier(false);

  static void closeMenu() {
    currentOverlay?.remove();
    currentOverlay = null;
    activeTitle = "";
    menuOpen.value = false;
  }
}

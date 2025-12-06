import 'package:flutter/material.dart';
import 'package:laravelide/GetProvider/new_project_getx_provider.dart';
import 'package:laravelide/screens/home_screen.dart';

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
                    _menuButton(
                      context,
                      "File",
                      ["New File", "Open File", "Save", "Close Project"],
                      (item) {
                        if (item == "Close Project") {
                          var newProjectController = NewProjectGetxProvider();

                          newProjectController.reset();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(),
                            ),
                            (Route<dynamic> route) => route.isFirst,
                          );
                        }
                      },
                    ),

                    _menuButton(
                      context,
                      "Edit",
                      ["Undo", "Redo", "Copy", "Paste"],
                      (item) {
                        print("Edit → $item clicked");
                      },
                    ),

                    _menuButton(
                      context,
                      "View",
                      ["Zoom In", "Zoom Out", "Full Screen"],
                      (item) {
                        print("View → $item clicked");
                      },
                    ),
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

  Widget _menuButton(
    BuildContext context,
    String title,
    List<String> items,
    Function(String item) onTap,
  ) {
    return _DesktopMenuButton(title: title, items: items, onItemTap: onTap);
  }
}

class _DesktopMenuButton extends StatefulWidget {
  final String title;
  final List<String> items;
  final Function(String) onItemTap;

  const _DesktopMenuButton({
    required this.title,
    required this.items,
    required this.onItemTap,
  });

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
                      widget.onItemTap(e); // 🔥 CLICK EVENT HERE
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
        if (MenuController.menuOpen.value &&
            MenuController.activeTitle != widget.title) {
          showMenu();
        }
      },
      child: GestureDetector(
        onTap: () {
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

import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool hasBackButton;
  final Color? backgroundColor;
  final VoidCallback? onBackPressed;
  
  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.bottom,
    this.hasBackButton = true,
    this.backgroundColor,
    this.onBackPressed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: backgroundColor ?? AppColors.background,
      elevation: 0,
      leading: hasBackButton && Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : Builder(
              builder: (context) => IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white,
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
      actions: actions,
      bottom: bottom,
    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0.0)
  );
} 
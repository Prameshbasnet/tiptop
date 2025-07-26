import 'package:flutter/material.dart';
import 'package:tiptop/styles/styles.dart';
import 'package:tiptop/widgets/widgets.dart';

class FilledListTile
    extends
        StatelessWidget {
  final String title;
  final String description;
  final void Function()? onPressed;
  final IconData? icon;
  final EdgeInsets? margin;
  final String? imageUrl;
  final Widget? midWidget;
  final Widget? trailing;
  final Color? subtitleTextColor;
  final Color? iconColor;
  final double horizontalMargin;
  final double bottomMargin;

  const FilledListTile({
    super.key,
    required this.title,
    required this.description,
    this.onPressed,
    this.icon,
    this.margin,
    this.imageUrl,
    this.midWidget,
    this.trailing,
    this.subtitleTextColor,
    this.iconColor,
    this.horizontalMargin = 0,
    this.bottomMargin = 10,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    // final theme = Theme.of(context);
    //  final textTheme = theme.textTheme;
    var media = MediaQuery.of(
      context,
    ).size;

    return Container(
      margin:
          margin ??
          EdgeInsets.only(
            bottom: bottomMargin,
            left: horizontalMargin,
            right: horizontalMargin,
          ),
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            30,
          ),
          side: BorderSide(
            color: backgroundColor,
          ),
        ),
        color: backgroundColor.withOpacity(
          0.1,
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            30,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 20,
            ),
            child: Row(
              children: [
                if (icon !=
                    null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        100,
                      ),
                    ),
                    padding: const EdgeInsets.all(
                      6,
                    ),
                    margin: const EdgeInsets.only(
                      right: 12,
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                if (imageUrl !=
                    null)
                  Container(
                    padding: const EdgeInsets.all(
                      6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        100,
                      ),
                    ),
                    margin: const EdgeInsets.only(
                      right: 12,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        40,
                      ),
                      child: Image.asset(
                        imageUrl.toString(),
                        height: 25,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        MyText(
                          text: title,
                          overflow: TextOverflow.ellipsis,
                          size:
                              media.width *
                              sixteen,
                          color: textColor.withOpacity(
                            0.8,
                          ),
                        ),
                      // Text(
                      //   title,
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: textTheme.titleLarge!.copyWith(
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                      if (title.isNotEmpty)
                        const SizedBox(
                          height: 4,
                        ),
                      if (description.isNotEmpty)
                        MyText(
                          text: description,
                          overflow: TextOverflow.ellipsis,
                          size:
                              media.width *
                              fourteen,
                          color: textColor.withOpacity(
                            0.8,
                          ),
                        ),
                      // Text(
                      //   description,
                      //   maxLines: 2,
                      //   overflow: TextOverflow.ellipsis,
                      //   // style: textTheme.bodyLarge!.copyWith(
                      //   //   fontWeight: FontWeight.w400,
                      //   //   height: 1.35,
                      //   //   color: subtitleTextColor,
                      //   // ),
                      // ),
                    ],
                  ),
                ),
                if (midWidget !=
                    null)
                  midWidget!,
                trailing ??
                    const Icon(
                      Icons.arrow_forward_ios,
                      //   color: CustomTheme.darkerBlack,
                      size: 20,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

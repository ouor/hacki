import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/utils/utils.dart';

class ItemText extends StatelessWidget {
  const ItemText({
    required this.item,
    required this.textScaler,
    required this.selectable,
    super.key,
    this.onTap,
  });

  final Item item;
  final TextScaler textScaler;
  final bool selectable;

  /// Reserved for collapsing a comment tile when
  /// [CollapseModePreference] is enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final PreferenceState prefState = context.read<PreferenceCubit>().state;
    final TextStyle style = TextStyle(
      fontSize: prefState.fontSize.fontSize,
    );
    final TextStyle linkStyle = TextStyle(
      fontSize: prefState.fontSize.fontSize,
      decoration: TextDecoration.underline,
      color: Theme.of(context).colorScheme.primary,
    );

    void onSelectionChanged(
      TextSelection selection,
      SelectionChangedCause? cause,
    ) {
      if (cause == SelectionChangedCause.longPress &&
          selection.baseOffset != selection.extentOffset &&
          item is Comment) {
        context.tryRead<CommentsCubit>()?.lock(item as Comment);
      }
    }

    final Widget content;

    if (selectable && item is Buildable) {
      content = SelectableText.rich(
        buildTextSpan(
          (item as Buildable).elements,
          primaryColor: Theme.of(context).colorScheme.primaryContainer,
          style: style,
          linkStyle: linkStyle,
          onOpen: (LinkableElement link) => LinkUtils.launch(
            link.url,
            context,
          ),
        ),
        scrollPhysics: const NeverScrollableScrollPhysics(),
        selectionColor:
            Theme.of(context).colorScheme.primaryContainer.withAlpha(180),
        onTap: onTap,
        textScaler: textScaler,
        onSelectionChanged: onSelectionChanged,
        contextMenuBuilder: (
          BuildContext context,
          EditableTextState editableTextState,
        ) =>
            contextMenuBuilder(
          context,
          editableTextState,
          item: item,
        ),
        semanticsLabel: item.text,
      );
    } else if (item is Buildable) {
      content = InkWell(
        child: Text.rich(
          buildTextSpan(
            (item as Buildable).elements,
            primaryColor: Theme.of(context).colorScheme.primaryContainer,
            style: style,
            linkStyle: linkStyle,
            onOpen: (LinkableElement link) => LinkUtils.launch(
              link.url,
              context,
            ),
          ),
          textScaler: textScaler,
          semanticsLabel: item.text,
        ),
      );
    } else if (selectable) {
      content = InkWell(
        child: SelectableLinkify(
          text: item.text,
          textScaler: textScaler,
          style: style,
          linkStyle: linkStyle,
          onOpen: (LinkableElement link) => LinkUtils.launch(
            link.url,
            context,
          ),
          contextMenuBuilder: (
            BuildContext context,
            EditableTextState editableTextState,
          ) =>
              contextMenuBuilder(
            context,
            editableTextState,
            item: item,
          ),
        ),
      );
    } else {
      content = InkWell(
        child: Linkify(
          text: item.text,
          textScaler: textScaler,
          style: style,
          linkStyle: linkStyle,
          onOpen: (LinkableElement link) => LinkUtils.launch(
            link.url,
            context,
          ),
        ),
      );
    }

    if (item.text.trim().isEmpty) {
      return content;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        content,
        _TranslationSection(
          item: item,
          style: style,
          textScaler: textScaler,
        ),
      ],
    );
  }
}

class _TranslationSection extends StatelessWidget {
  const _TranslationSection({
    required this.item,
    required this.style,
    required this.textScaler,
  });

  final Item item;
  final TextStyle style;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TranslationCubit>(
      create: (_) => TranslationCubit(),
      child: BlocConsumer<TranslationCubit, TranslationState>(
        listenWhen: (
          TranslationState previous,
          TranslationState current,
        ) =>
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null,
        listener: (BuildContext context, TranslationState state) {
          context.showErrorSnackBar(state.errorMessage);
        },
        builder: (BuildContext context, TranslationState state) {
          final String buttonLabel = switch (state.status) {
            Status.inProgress => 'Translating...',
            _ when state.translatedText != null && state.isVisible =>
              'Hide translation',
            _ when state.translatedText != null => 'Show translation',
            _ => 'Translate',
          };

          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextButton.icon(
                  onPressed: state.status == Status.inProgress
                      ? null
                      : () => context.read<TranslationCubit>().toggle(
                            text: item.text,
                          ),
                  icon: state.status == Status.inProgress
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.translate, size: 18),
                  label: Text(buttonLabel),
                ),
                if (state.translatedText != null && state.isVisible)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      state.translatedText!,
                      style: style,
                      textScaler: textScaler,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

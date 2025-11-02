import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';
import 'package:syntax_highlight/syntax_highlight.dart' as syntax;

/// Metadata key that stores the language identifier for a code block.
const String kCodeBlockLanguageKey = 'codeLanguage';

/// Default language used when a [CodeBlockNode] does not provide one explicitly.
const String kDefaultCodeLanguage = 'plaintext';

/// Pattern used to detect three backticks followed by an optional language identifier.
final RegExp codeBlockShortcutPattern = RegExp(r'^```([A-Za-z0-9_+\-]*)$');

/// Default set of languages presented in the code block language picker, in the
/// order they should be displayed.
const List<String> kCodeBlockDefaultLanguageOrder = <String>[
  kDefaultCodeLanguage,
  'dart',
  'yaml',
  'json',
  'xml',
  'html',
  'javascript',
  'typescript',
  'css',
  'java',
  'kotlin',
  'swift',
  'go',
  'python',
  'rust',
  'sql',
];

/// Maps a code block language identifier to the syntax highlight grammar that
/// should be used. A `null` value means that the language should not be
/// syntax highlighted (i.e., plain text).
const Map<String, String?> kCodeBlockLanguageHighlightGrammars =
    <String, String?>{
  kDefaultCodeLanguage: null,
  'text': null,
  'txt': null,
  'dart': 'dart',
  'yaml': 'yaml',
  'yml': 'yaml',
  'json': 'json',
  'javascript': 'javascript',
  'js': 'javascript',
  'typescript': 'typescript',
  'ts': 'typescript',
  'css': 'css',
  'html': 'html',
  'xml': 'html',
  'java': 'java',
  'kotlin': 'kotlin',
  'swift': 'swift',
  'go': 'go',
  'golang': 'go',
  'python': 'python',
  'py': 'python',
  'rust': 'rust',
  'sql': 'sql',
  'serverpod_protocol': 'serverpod_protocol',
};

/// Maps canonical language identifiers to user-friendly display names.
const Map<String, String> kCodeBlockLanguageDisplayNames = <String, String>{
  kDefaultCodeLanguage: 'Plain text',
  'text': 'Plain text',
  'txt': 'Plain text',
  'dart': 'Dart',
  'yaml': 'YAML',
  'yml': 'YAML',
  'json': 'JSON',
  'javascript': 'JavaScript',
  'js': 'JavaScript',
  'typescript': 'TypeScript',
  'ts': 'TypeScript',
  'css': 'CSS',
  'html': 'HTML',
  'xml': 'XML',
  'java': 'Java',
  'kotlin': 'Kotlin',
  'swift': 'Swift',
  'go': 'Go',
  'golang': 'Go',
  'python': 'Python',
  'py': 'Python',
  'rust': 'Rust',
  'sql': 'SQL',
  'serverpod_protocol': 'Serverpod Protocol',
};

String _canonicalizeLanguageKey(String language) =>
    language.trim().toLowerCase();

String _languageDisplayName(String language) {
  final canonical = _canonicalizeLanguageKey(language);
  return kCodeBlockLanguageDisplayNames[canonical] ??
      _titleCaseLanguage(language);
}

String _titleCaseLanguage(String language) {
  final sanitized = language.trim();
  if (sanitized.isEmpty) {
    return kCodeBlockLanguageDisplayNames[kDefaultCodeLanguage]!;
  }

  return sanitized
      .split(RegExp(r'[\s_\-]+'))
      .where((segment) => segment.isNotEmpty)
      .map((segment) => segment[0].toUpperCase() + segment.substring(1))
      .join(' ');
}

String? _resolveHighlightLanguage(String language) {
  final canonical = _canonicalizeLanguageKey(language);
  if (canonical.isEmpty) {
    return kCodeBlockLanguageHighlightGrammars[kDefaultCodeLanguage];
  }
  return kCodeBlockLanguageHighlightGrammars[canonical];
}

/// [DocumentNode] that represents an editable code block with syntax highlighting.
///
/// A code block maintains a language identifier so that syntax highlighting and
/// language-aware editing behaviors can be applied.
class CodeBlockNode extends TextNode {
  CodeBlockNode({
    required super.id,
    required super.text,
    String? language,
    Map<String, dynamic>? metadata,
  })  : language = language ??
            metadata?[kCodeBlockLanguageKey] as String? ??
            kDefaultCodeLanguage,
        super(metadata: metadata) {
    initAddToMetadata({
      NodeMetadata.blockType: codeAttribution,
      kCodeBlockLanguageKey: this.language,
    });
  }

  /// Language identifier used for syntax highlighting (e.g., `dart`, `yaml`).
  final String language;

  /// Returns `true` when the given [other] node contains the same content and
  /// semantic properties as this node.
  @override
  bool hasEquivalentContent(DocumentNode other) {
    return other is CodeBlockNode &&
        super.hasEquivalentContent(other) &&
        language == other.language;
  }

  /// Creates a copy of this node, overriding any provided properties.
  CodeBlockNode copyCodeBlockWith({
    String? id,
    AttributedText? text,
    Map<String, dynamic>? metadata,
    String? language,
  }) {
    final updatedLanguage = language ?? this.language;
    final updatedMetadata =
        metadata != null ? Map<String, dynamic>.from(metadata) : copyMetadata();
    updatedMetadata[kCodeBlockLanguageKey] = updatedLanguage;
    updatedMetadata[NodeMetadata.blockType] ??= codeAttribution;

    return CodeBlockNode(
      id: id ?? this.id,
      text: text ?? this.text,
      metadata: updatedMetadata,
      language: updatedLanguage,
    );
  }

  @override
  CodeBlockNode copyTextNodeWith({
    String? id,
    AttributedText? text,
    Map<String, dynamic>? metadata,
  }) {
    return copyCodeBlockWith(
      id: id,
      text: text,
      metadata: metadata,
    );
  }

  @override
  CodeBlockNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) {
    return copyCodeBlockWith(
      metadata: newMetadata,
      language: newMetadata[kCodeBlockLanguageKey] as String? ?? language,
    );
  }

  @override
  CodeBlockNode copyWithAddedMetadata(Map<String, dynamic> newProperties) {
    final combinedMetadata = {
      ...copyMetadata(),
      ...newProperties,
    };

    return copyCodeBlockWith(
      metadata: combinedMetadata,
      language: combinedMetadata[kCodeBlockLanguageKey] as String? ?? language,
    );
  }

  @override
  CodeBlockNode copy() {
    return CodeBlockNode(
      id: id,
      text: text.copyText(0),
      metadata: copyMetadata(),
      language: language,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is CodeBlockNode &&
          runtimeType == other.runtimeType &&
          language == other.language;

  @override
  int get hashCode => super.hashCode ^ language.hashCode;
}

extension CodeBlockNodeType on DocumentNode {
  CodeBlockNode get asCodeBlock => this as CodeBlockNode;
}

/// Styles all code block components with vertical spacing.
final codeBlockStyles = StyleRule(
  const BlockSelector('code'),
  (document, node) {
    if (node is! CodeBlockNode) {
      return {};
    }

    return {
      Styles.padding: const CascadingPadding.symmetric(vertical: 12),
    };
  },
);

/// Builds [CodeBlockComponentViewModel]s and [CodeBlockComponent]s for every code block in a document.
class CodeBlockComponentBuilder implements ComponentBuilder {
  const CodeBlockComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
      Document document, DocumentNode node) {
    if (node is! CodeBlockNode) {
      return null;
    }

    final textDirection = getParagraphDirection(node.text.toPlainText());

    return CodeBlockComponentViewModel(
      nodeId: node.id,
      createdAt: node.metadata[NodeMetadata.createdAt],
      padding: EdgeInsets.zero,
      language: node.language,
      text: node.text,
      textStyleBuilder: noStyleBuilder,
      textDirection: textDirection,
      textAlignment: TextAlign.left,
      selectionColor: const Color(0x00000000),
    );
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! CodeBlockComponentViewModel) {
      return null;
    }

    return CodeBlockComponent(
      key: componentContext.componentKey,
      viewModel: componentViewModel,
    );
  }
}

/// Style phase that wires code block components to language change behavior.
class CodeBlockLanguageStyler extends SingleColumnLayoutStylePhase {
  CodeBlockLanguageStyler({required RequestDispatcher requestDispatcher})
      : _requestDispatcher = requestDispatcher;

  final RequestDispatcher _requestDispatcher;

  @override
  SingleColumnLayoutViewModel style(
    Document document,
    SingleColumnLayoutViewModel viewModel,
  ) {
    return SingleColumnLayoutViewModel(
      padding: viewModel.padding,
      componentViewModels: [
        for (final previous in viewModel.componentViewModels)
          _configureLanguageCallback(previous),
      ],
    );
  }

  SingleColumnLayoutComponentViewModel _configureLanguageCallback(
      SingleColumnLayoutComponentViewModel previous) {
    final copy = previous.copy();
    if (copy is CodeBlockComponentViewModel) {
      final nodeId = copy.nodeId;
      copy.onLanguageSelected = (language) {
        final normalized = _canonicalizeLanguageKey(language);
        _requestDispatcher.execute([
          ChangeCodeBlockLanguageRequest(
            nodeId: nodeId,
            language: normalized,
          ),
        ]);
      };
    }
    return copy;
  }
}

/// View model that configures the appearance of a [CodeBlockComponent].
class CodeBlockComponentViewModel extends SingleColumnLayoutComponentViewModel
    with TextComponentViewModel {
  CodeBlockComponentViewModel({
    required super.nodeId,
    super.createdAt,
    super.maxWidth,
    super.padding = EdgeInsets.zero,
    super.opacity = 1.0,
    required this.language,
    required this.text,
    required this.textStyleBuilder,
    this.inlineWidgetBuilders = const [],
    this.textDirection = TextDirection.ltr,
    this.textAlignment = TextAlign.left,
    this.selection,
    required this.selectionColor,
    this.highlightWhenEmpty = false,
    this.backgroundColor = Colors.transparent,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.innerPadding = const EdgeInsets.all(12),
    this.onLanguageSelected,
    TextRange? composingRegion,
    bool showComposingRegionUnderline = false,
    UnderlineStyle spellingErrorUnderlineStyle =
        const SquiggleUnderlineStyle(color: Colors.red),
    List<TextRange> spellingErrors = const <TextRange>[],
    UnderlineStyle grammarErrorUnderlineStyle =
        const SquiggleUnderlineStyle(color: Colors.blue),
    List<TextRange> grammarErrors = const <TextRange>[],
  }) {
    this.composingRegion = composingRegion;
    this.showComposingRegionUnderline = showComposingRegionUnderline;

    this.spellingErrorUnderlineStyle = spellingErrorUnderlineStyle;
    this.spellingErrors = spellingErrors;

    this.grammarErrorUnderlineStyle = grammarErrorUnderlineStyle;
    this.grammarErrors = grammarErrors;
  }

  /// Language identifier used by this code block.
  String language;

  /// Background color applied behind the code block content.
  Color backgroundColor;

  /// Border radius used for the containing decoration.
  BorderRadius borderRadius;

  /// Padding applied inside the decorated container before the text is rendered.
  EdgeInsets innerPadding;

  /// Callback invoked when the user selects a new language for this code block.
  void Function(String language)? onLanguageSelected;

  @override
  AttributedText text;
  @override
  AttributionStyleBuilder textStyleBuilder;
  @override
  InlineWidgetBuilderChain inlineWidgetBuilders;
  @override
  TextDirection textDirection;
  @override
  TextAlign textAlignment;
  @override
  TextSelection? selection;
  @override
  Color selectionColor;
  @override
  bool highlightWhenEmpty;

  @override
  CodeBlockComponentViewModel copy() {
    return internalCopy(
      CodeBlockComponentViewModel(
        nodeId: nodeId,
        createdAt: createdAt,
        text: text.copy(),
        textStyleBuilder: textStyleBuilder,
        opacity: opacity,
        selectionColor: selectionColor,
        language: language,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        innerPadding: innerPadding,
        onLanguageSelected: onLanguageSelected,
      ),
    );
  }

  @override
  CodeBlockComponentViewModel internalCopy(
      CodeBlockComponentViewModel viewModel) {
    final copy = super.internalCopy(viewModel) as CodeBlockComponentViewModel;
    copy
      ..language = language
      ..backgroundColor = backgroundColor
      ..borderRadius = borderRadius
      ..innerPadding = innerPadding
      ..onLanguageSelected = onLanguageSelected;
    return copy;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is CodeBlockComponentViewModel &&
          runtimeType == other.runtimeType &&
          textViewModelEquals(other) &&
          language == other.language &&
          backgroundColor == other.backgroundColor &&
          borderRadius == other.borderRadius &&
          innerPadding == other.innerPadding;

  @override
  int get hashCode =>
      super.hashCode ^
      textViewModelHashCode ^
      language.hashCode ^
      backgroundColor.hashCode ^
      borderRadius.hashCode ^
      innerPadding.hashCode;
}

/// A [DocumentComponent] that renders a syntax highlighted code block.
class CodeBlockComponent extends StatefulWidget {
  const CodeBlockComponent({
    super.key,
    required this.viewModel,
    this.showDebugPaint = false,
  });

  final CodeBlockComponentViewModel viewModel;
  final bool showDebugPaint;

  @override
  State<CodeBlockComponent> createState() => _CodeBlockComponentState();
}

class _CodeBlockComponentState extends State<CodeBlockComponent>
    with ProxyDocumentComponent<CodeBlockComponent>, ProxyTextComposable {
  final _textKey = GlobalKey<TextComponentState>();
  final ScrollController _horizontalScrollController = ScrollController();

  static const double _kLanguageSelectorMargin = 12;

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  GlobalKey<State<StatefulWidget>> get childDocumentComponentKey => _textKey;

  @override
  TextComposable get childTextComposable =>
      _textKey.currentState as TextComposable;

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;

    final backgroundColor = viewModel.backgroundColor == Colors.transparent
        ? _defaultCodeBlockBackgroundColor(colorScheme, brightness)
        : viewModel.backgroundColor;

    final textStyleBuilder = _createCodeBlockTextStyleBuilder(
      baseBuilder: viewModel.textStyleBuilder,
      baseTextStyle: _defaultCodeBlockTextStyle(theme, brightness),
      brightness: brightness,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              width: double.infinity,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: viewModel.borderRadius,
              ),
            ),
          ),
        ),
        Padding(
          padding: viewModel.innerPadding,
          child: TextComponent(
            key: _textKey,
            text: viewModel.text,
            textDirection: viewModel.textDirection,
            textAlign: viewModel.textAlignment,
            textStyleBuilder: textStyleBuilder,
            inlineWidgetBuilders: viewModel.inlineWidgetBuilders,
            textSelection: viewModel.selection,
            selectionColor: viewModel.selectionColor,
            highlightWhenEmpty: viewModel.highlightWhenEmpty,
            underlines: viewModel.createUnderlines(),
            showDebugPaint: widget.showDebugPaint,
          ),
        ),
        Positioned(
          top: _kLanguageSelectorMargin,
          right: _kLanguageSelectorMargin,
          child: _CodeBlockLanguageSelector(
            currentLanguage: viewModel.language,
            onLanguageSelected: _handleLanguageSelected,
          ),
        ),
      ],
    );
  }

  void _handleLanguageSelected(String language) {
    final normalizedSelection = _canonicalizeLanguageKey(language);
    final currentLanguage = _canonicalizeLanguageKey(widget.viewModel.language);
    if (normalizedSelection == currentLanguage) {
      return;
    }

    widget.viewModel.onLanguageSelected?.call(normalizedSelection);
  }
}

class _CodeBlockLanguageSelector extends StatelessWidget {
  const _CodeBlockLanguageSelector({
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  final String currentLanguage;
  final ValueChanged<String> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    final normalizedCurrent = _canonicalizeLanguageKey(
        currentLanguage.isEmpty ? kDefaultCodeLanguage : currentLanguage);
    final menuEntries = _buildMenuEntries(normalizedCurrent);
    final hasCurrentOption = menuEntries.any(
      (entry) =>
          entry is CheckedPopupMenuItem<String> &&
          entry.value == normalizedCurrent,
    );

    final displayText = _languageDisplayName(
      currentLanguage.isEmpty ? kDefaultCodeLanguage : currentLanguage,
    );

    return PopupMenuButton<String>(
      tooltip: 'Code language',
      elevation: 2,
      padding: EdgeInsets.zero,
      initialValue: hasCurrentOption ? normalizedCurrent : null,
      onSelected: (value) =>
          onLanguageSelected(_canonicalizeLanguageKey(value)),
      itemBuilder: (context) => menuEntries,
      child: _LanguageChip(label: displayText),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuEntries(String normalizedCurrent) {
    final entries = <PopupMenuEntry<String>>[];
    final seen = <String>{};

    void addLanguage(String language) {
      final canonical = _canonicalizeLanguageKey(language);
      if (canonical.isEmpty || !seen.add(canonical)) {
        return;
      }
      entries.add(
        CheckedPopupMenuItem<String>(
          value: canonical,
          checked: canonical == normalizedCurrent,
          child: Text(_languageDisplayName(canonical)),
        ),
      );
    }

    final bool hasCustomLanguage = normalizedCurrent.isNotEmpty &&
        !kCodeBlockDefaultLanguageOrder.contains(normalizedCurrent);
    if (hasCustomLanguage) {
      addLanguage(normalizedCurrent);
      entries.add(const PopupMenuDivider());
    }

    for (final language in kCodeBlockDefaultLanguageOrder) {
      addLanguage(language);
    }

    return entries;
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;

    final Color background = brightness == Brightness.dark
        ? Color.alphaBlend(
            colorScheme.surfaceVariant.withOpacity(0.6),
            colorScheme.surface,
          )
        : colorScheme.surfaceVariant.withOpacity(0.9);
    final Color foreground = colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: background,
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ) ??
                  TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: foreground,
            ),
          ],
        ),
      ),
    );
  }
}

/// Attribution applied to text spans that represent syntax highlight tokens.
class CodeSyntaxHighlightAttribution implements Attribution {
  factory CodeSyntaxHighlightAttribution({
    required String tokenType,
    required Map<Brightness, TextStyle> stylesByBrightness,
  }) {
    assert(stylesByBrightness.isNotEmpty,
        'stylesByBrightness must include at least one TextStyle.');

    final sanitized = Map<Brightness, TextStyle>.of(stylesByBrightness);
    final resolvedStyles = Map<Brightness, TextStyle>.unmodifiable(sanitized);
    final lightStyle = _resolveLightStyle(sanitized);
    final darkStyle = sanitized[Brightness.dark];

    return CodeSyntaxHighlightAttribution._(
      tokenType: tokenType,
      stylesByBrightness: resolvedStyles,
      lightStyle: lightStyle,
      darkStyle: darkStyle,
      id: _createId(tokenType, resolvedStyles),
      hashCodeValue: Object.hash(tokenType, _mapEquality.hash(resolvedStyles)),
    );
  }

  CodeSyntaxHighlightAttribution._({
    required this.tokenType,
    required this.stylesByBrightness,
    required TextStyle lightStyle,
    TextStyle? darkStyle,
    required String id,
    required int hashCodeValue,
  })  : _lightStyle = lightStyle,
        _darkStyle = darkStyle,
        _id = id,
        _hashCode = hashCodeValue;

  static const MapEquality<Brightness, TextStyle> _mapEquality =
      MapEquality<Brightness, TextStyle>();

  /// Token identifier supplied by the syntax highlighter (e.g., `keyword`, `string`).
  final String tokenType;

  /// Styles applied to this token for each [Brightness].
  final Map<Brightness, TextStyle> stylesByBrightness;

  final TextStyle _lightStyle;
  final TextStyle? _darkStyle;
  final String _id;
  final int _hashCode;

  /// Resolves the highlight style for the given [brightness].
  TextStyle resolve(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return _darkStyle ?? _lightStyle;
    }
    if (brightness == Brightness.light) {
      return _lightStyle;
    }
    return stylesByBrightness[brightness] ?? _lightStyle;
  }

  @override
  String get id => _id;

  @override
  bool canMergeWith(Attribution other) {
    return other is CodeSyntaxHighlightAttribution &&
        other.tokenType == tokenType &&
        _mapEquality.equals(other.stylesByBrightness, stylesByBrightness);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeSyntaxHighlightAttribution &&
          other.tokenType == tokenType &&
          _mapEquality.equals(other.stylesByBrightness, stylesByBrightness);

  @override
  int get hashCode => _hashCode;

  static TextStyle _resolveLightStyle(Map<Brightness, TextStyle> styles) {
    return styles[Brightness.light] ?? styles.values.first;
  }

  static String _createId(
    String tokenType,
    Map<Brightness, TextStyle> styles,
  ) {
    if (styles.isEmpty) {
      return 'code.syntax.$tokenType';
    }

    final signatureParts = <String>[];
    for (final brightness in const [Brightness.light, Brightness.dark]) {
      final style = styles[brightness];
      if (style != null) {
        signatureParts
            .add('${_describeBrightness(brightness)}:${style.hashCode}');
      }
    }

    if (styles.length > signatureParts.length) {
      final additionalEntries = styles.entries
          .where((entry) =>
              entry.key != Brightness.light && entry.key != Brightness.dark)
          .toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

      for (final entry in additionalEntries) {
        signatureParts.add('${entry.key.toString()}:${entry.value.hashCode}');
      }
    }

    if (signatureParts.isEmpty) {
      return 'code.syntax.$tokenType';
    }

    return 'code.syntax.$tokenType.${signatureParts.join('|')}';
  }

  static String _describeBrightness(Brightness brightness) {
    switch (brightness) {
      case Brightness.light:
        return 'light';
      case Brightness.dark:
        return 'dark';
    }
  }
}

/// Builds a [TextStyle] for code block content, merging any syntax highlight styles provided by attributions.
AttributionStyleBuilder _createCodeBlockTextStyleBuilder({
  required AttributionStyleBuilder baseBuilder,
  required TextStyle baseTextStyle,
  required Brightness brightness,
}) {
  return (Set<Attribution> attributions) {
    final sanitizedAttributions = attributions
        .where((attribution) => attribution is! CodeSyntaxHighlightAttribution)
        .toSet();

    final isDefaultBuilder = identical(baseBuilder, noStyleBuilder);
    final builderStyle = baseBuilder(sanitizedAttributions);

    TextStyle style =
        isDefaultBuilder ? baseTextStyle : baseTextStyle.merge(builderStyle);

    for (final attribution in attributions) {
      if (attribution is CodeSyntaxHighlightAttribution) {
        style = style.merge(attribution.resolve(brightness));
      }
    }

    return style;
  };
}

/// Result of syntax highlighting, expressed as ranges within a code block text.
class CodeSyntaxHighlightSpan {
  CodeSyntaxHighlightSpan({
    required this.start,
    required this.end,
    required this.attribution,
  });

  /// Inclusive start offset of the highlighted range.
  final int start;

  /// Inclusive end offset of the highlighted range.
  final int end;

  /// Attribution applied to this range.
  final CodeSyntaxHighlightAttribution attribution;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeSyntaxHighlightSpan &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          attribution == other.attribution;

  @override
  int get hashCode => Object.hash(start, end, attribution);
}

/// Provides syntax highlight spans for code blocks using the `syntax_highlight` package.
class CodeSyntaxHighlighter {
  CodeSyntaxHighlighter._();

  static final CodeSyntaxHighlighter instance = CodeSyntaxHighlighter._();

  final Map<String, Future<syntax.Highlighter>> _highlighters = {};

  /// Returns syntax highlight spans for the given [source] and [language].
  Future<List<CodeSyntaxHighlightSpan>> highlight({
    required String source,
    required String language,
  }) async {
    final stopwatch = Stopwatch()..start();
    if (source.isEmpty) {
      return const <CodeSyntaxHighlightSpan>[];
    }

    final grammarLanguage = _resolveHighlightLanguage(language);
    if (grammarLanguage == null) {
      return const <CodeSyntaxHighlightSpan>[];
    }

    try {
      final lightSpans = await _highlightRaw(
        source: source,
        grammarLanguage: grammarLanguage,
        brightness: Brightness.light,
      );
      final darkSpans = await _highlightRaw(
        source: source,
        grammarLanguage: grammarLanguage,
        brightness: Brightness.dark,
      );

      final combined = _combineRawHighlightSpans(lightSpans, darkSpans);
      combined.sort((a, b) => a.start.compareTo(b.start));
      return combined;
    } on FlutterError catch (_) {
      return const <CodeSyntaxHighlightSpan>[];
    } on PlatformException catch (_) {
      return const <CodeSyntaxHighlightSpan>[];
    } finally {
      print('CodeSyntaxHighlighter.highlight took ${stopwatch.elapsed}');
    }
  }

  Future<List<_RawHighlightSpan>> _highlightRaw({
    required String source,
    required String grammarLanguage,
    required Brightness brightness,
  }) async {
    final highlighter = await _getHighlighter(grammarLanguage, brightness);
    final textSpan = highlighter.highlight(source);
    final spans = <_RawHighlightSpan>[];
    _collectHighlightSpans(textSpan, spans, 0);
    return spans;
  }

  Future<syntax.Highlighter> _getHighlighter(
      String grammarLanguage, Brightness brightness) {
    final key =
        '$grammarLanguage-${brightness == Brightness.dark ? 'dark' : 'light'}';
    return _highlighters.putIfAbsent(key, () async {
      await syntax.Highlighter.initialize([grammarLanguage]);
      final theme = brightness == Brightness.dark
          ? await syntax.HighlighterTheme.loadDarkTheme()
          : await syntax.HighlighterTheme.loadLightTheme();
      return syntax.Highlighter(language: grammarLanguage, theme: theme);
    });
  }

  int _collectHighlightSpans(
    TextSpan span,
    List<_RawHighlightSpan> output,
    int offset,
  ) {
    var currentOffset = offset;
    final String? text = span.text;

    if (text != null && text.isNotEmpty) {
      final length = text.length;
      if (span.style != null) {
        final tokenType = _scopeFromSpan(span);
        output.add(
          _RawHighlightSpan(
            start: currentOffset,
            end: currentOffset + length - 1,
            tokenType: tokenType,
            style: span.style!,
          ),
        );
      }
      currentOffset += length;
    }

    if (span.children != null && span.children!.isNotEmpty) {
      for (final child in span.children!) {
        if (child is TextSpan) {
          currentOffset = _collectHighlightSpans(child, output, currentOffset);
        }
      }
    }

    return currentOffset;
  }

  List<CodeSyntaxHighlightSpan> _combineRawHighlightSpans(
    List<_RawHighlightSpan> lightSpans,
    List<_RawHighlightSpan> darkSpans,
  ) {
    final Map<_HighlightSpanKey, Map<Brightness, TextStyle>> combined = {};

    void addSpans(Brightness brightness, List<_RawHighlightSpan> spans) {
      for (final span in spans) {
        final key = _HighlightSpanKey(span.start, span.end, span.tokenType);
        final styles = combined.putIfAbsent(key, () => {});
        styles[brightness] = span.style;
      }
    }

    addSpans(Brightness.light, lightSpans);
    addSpans(Brightness.dark, darkSpans);

    return combined.entries.map((entry) {
      return CodeSyntaxHighlightSpan(
        start: entry.key.start,
        end: entry.key.end,
        attribution: CodeSyntaxHighlightAttribution(
          tokenType: entry.key.tokenType,
          stylesByBrightness: entry.value,
        ),
      );
    }).toList();
  }

  String _scopeFromSpan(TextSpan span) {
    final semanticsLabel = span.semanticsLabel;
    if (semanticsLabel != null && semanticsLabel.isNotEmpty) {
      return semanticsLabel;
    }
    return span.runtimeType.toString();
  }
}

/// Request to convert a [ParagraphNode] to a [CodeBlockNode].
class ConvertParagraphToCodeBlockRequest implements EditRequest {
  const ConvertParagraphToCodeBlockRequest({
    required this.nodeId,
    this.language,
  });

  final String nodeId;
  final String? language;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConvertParagraphToCodeBlockRequest &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId &&
          language == other.language;

  @override
  int get hashCode => Object.hash(nodeId, language);
}

class ConvertParagraphToCodeBlockCommand extends EditCommand {
  const ConvertParagraphToCodeBlockCommand({
    required this.nodeId,
    this.language,
  });

  final String nodeId;
  final String? language;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final paragraph = context.document.getNodeById(nodeId);
    if (paragraph is! ParagraphNode) {
      return;
    }

    final targetLanguage = _normalizeLanguage(language);
    final preservedMetadata = <String, dynamic>{};
    if (paragraph.metadata.containsKey(NodeMetadata.createdAt)) {
      preservedMetadata[NodeMetadata.createdAt] =
          paragraph.metadata[NodeMetadata.createdAt];
    }

    final codeBlock = CodeBlockNode(
      id: paragraph.id,
      text: AttributedText(),
      language: targetLanguage,
      metadata: preservedMetadata,
    );

    executor
      ..executeCommand(
        ReplaceNodeCommand(
          existingNodeId: paragraph.id,
          newNode: codeBlock,
        ),
      )
      ..executeCommand(
        ChangeSelectionCommand(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: codeBlock.id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
          SelectionChangeType.placeCaret,
          SelectionReason.userInteraction,
        ),
      );
  }
}

/// Request to convert a [CodeBlockNode] back to a [ParagraphNode].
class ConvertCodeBlockToParagraphRequest implements EditRequest {
  const ConvertCodeBlockToParagraphRequest({
    required this.nodeId,
  });

  final String nodeId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConvertCodeBlockToParagraphRequest &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId;

  @override
  int get hashCode => nodeId.hashCode;
}

class ConvertCodeBlockToParagraphCommand extends EditCommand {
  const ConvertCodeBlockToParagraphCommand({
    required this.nodeId,
  });

  final String nodeId;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId);
    if (node is! TextNode) {
      return;
    }

    final blockType = node.getMetadataValue(NodeMetadata.blockType);
    final isCodeBlockNode = node is CodeBlockNode;
    final isParagraphStyledAsCodeBlock =
        !isCodeBlockNode && blockType == codeAttribution;

    if (!isCodeBlockNode && !isParagraphStyledAsCodeBlock) {
      return;
    }

    final paragraphText = _stripCodeSyntaxHighlights(node.text);
    final metadata = node.copyMetadata();
    metadata.remove(kCodeBlockLanguageKey);
    metadata[NodeMetadata.blockType] = paragraphAttribution;

    final paragraph = ParagraphNode(
      id: node.id,
      text: paragraphText,
      indent: node is ParagraphNode ? node.indent : 0,
      metadata: metadata,
    );

    executor
      ..executeCommand(
        ReplaceNodeCommand(
          existingNodeId: node.id,
          newNode: paragraph,
        ),
      )
      ..executeCommand(
        ChangeSelectionCommand(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: paragraph.id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
          SelectionChangeType.placeCaret,
          SelectionReason.userInteraction,
        ),
      );
  }
}

/// Request to change the language of a [CodeBlockNode].
class ChangeCodeBlockLanguageRequest implements EditRequest {
  const ChangeCodeBlockLanguageRequest({
    required this.nodeId,
    required this.language,
  });

  final String nodeId;
  final String language;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeCodeBlockLanguageRequest &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId &&
          language == other.language;

  @override
  int get hashCode => Object.hash(nodeId, language);
}

class ChangeCodeBlockLanguageCommand extends EditCommand {
  ChangeCodeBlockLanguageCommand({
    required this.nodeId,
    required this.language,
  });

  final String nodeId;
  final String language;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId);
    if (node is! CodeBlockNode) {
      return;
    }

    final normalized = _normalizeLanguage(language);
    if (node.language == normalized) {
      return;
    }

    context.document.replaceNodeById(
      node.id,
      node.copyCodeBlockWith(language: normalized),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}

/// Request used by [CodeSyntaxHighlightReaction] to apply highlight spans to a code block.
class ApplyCodeBlockHighlightRequest implements EditRequest {
  ApplyCodeBlockHighlightRequest({
    required this.nodeId,
    required this.language,
    required this.plainText,
    required List<CodeSyntaxHighlightSpan> spans,
  }) : spans = List.unmodifiable(spans);

  final String nodeId;
  final String language;
  final String plainText;
  final List<CodeSyntaxHighlightSpan> spans;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplyCodeBlockHighlightRequest &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId &&
          language == other.language &&
          plainText == other.plainText &&
          const ListEquality<CodeSyntaxHighlightSpan>()
              .equals(spans, other.spans);

  @override
  int get hashCode =>
      Object.hash(nodeId, language, plainText, Object.hashAll(spans));
}

class ApplyCodeBlockHighlightCommand extends EditCommand {
  ApplyCodeBlockHighlightCommand({
    required this.nodeId,
    required this.language,
    required this.plainText,
    required List<CodeSyntaxHighlightSpan> spans,
  }) : spans = List.unmodifiable(spans);

  final String nodeId;
  final String language;
  final String plainText;
  final List<CodeSyntaxHighlightSpan> spans;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.nonHistorical;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId);
    if (node is! CodeBlockNode &&
        !(node is ParagraphNode &&
            node.getMetadataValue(NodeMetadata.blockType) == codeAttribution)) {
      return;
    }

    final attributedText =
        (node is CodeBlockNode ? node.text : (node as ParagraphNode).text);
    final currentPlainText =
        attributedText.toPlainText(includePlaceholders: false);
    if (currentPlainText != plainText) {
      // The text changed since this highlight was computed. Skip.
      return;
    }
    if (_codeBlockHighlightEquals(attributedText, spans)) {
      return;
    }
    final baseMarkers = attributedText.spans.markers
        .where(
            (marker) => marker.attribution is! CodeSyntaxHighlightAttribution)
        .map((marker) => marker.copyWith())
        .toList(growable: true);
    for (final span in spans) {
      baseMarkers
        ..add(
          SpanMarker(
            attribution: span.attribution,
            offset: span.start,
            markerType: SpanMarkerType.start,
          ),
        )
        ..add(
          SpanMarker(
            attribution: span.attribution,
            offset: span.end,
            markerType: SpanMarkerType.end,
          ),
        );
    }

    final updatedText = attributedText.replaceAttributions(
      AttributedSpans(attributions: baseMarkers),
    );

    if (node is CodeBlockNode) {
      context.document.replaceNodeById(
        node.id,
        node.copyCodeBlockWith(
          text: updatedText,
          language: _normalizeLanguage(language),
        ),
      );
    } else if (node is ParagraphNode) {
      context.document.replaceNodeById(
        node.id,
        node.copyTextNodeWith(text: updatedText),
      );
    }

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(nodeId),
      ),
    ]);
  }
}

/// Converts a backspace at the beginning of a code block into a paragraph conversion.
ExecutionInstruction backspaceToConvertCodeBlockToParagraph({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent.logicalKey != LogicalKeyboardKey.backspace) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null || !selection.isCollapsed) {
    return ExecutionInstruction.continueExecution;
  }

  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is! TextNode) {
    return ExecutionInstruction.continueExecution;
  }

  final nodePosition = selection.extent.nodePosition;
  if (nodePosition is! TextNodePosition || nodePosition.offset > 0) {
    return ExecutionInstruction.continueExecution;
  }

  final blockType = node.getMetadataValue(NodeMetadata.blockType);
  final isCodeBlockNode = node is CodeBlockNode;
  final isParagraphStyledAsCodeBlock =
      !isCodeBlockNode && blockType == codeAttribution;

  if (!isCodeBlockNode && !isParagraphStyledAsCodeBlock) {
    return ExecutionInstruction.continueExecution;
  }

  editContext.editor.execute([
    ConvertCodeBlockToParagraphRequest(nodeId: node.id),
  ]);

  return ExecutionInstruction.haltExecution;
}

ExecutionInstruction tabToIndentCodeBlock({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent.logicalKey != LogicalKeyboardKey.tab) {
    return ExecutionInstruction.continueExecution;
  }
  if (HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final didIndent = editContext.commonOps.indentCodeBlockSelection();

  return didIndent
      ? ExecutionInstruction.haltExecution
      : ExecutionInstruction.continueExecution;
}

ExecutionInstruction shiftTabToUnindentCodeBlock({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent.logicalKey != LogicalKeyboardKey.tab) {
    return ExecutionInstruction.continueExecution;
  }
  if (!HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final didUnindent = editContext.commonOps.unindentCodeBlockSelection();

  return didUnindent
      ? ExecutionInstruction.haltExecution
      : ExecutionInstruction.continueExecution;
}

bool _isCodeBlockFullySelected(
  TextNodePosition basePosition,
  TextNodePosition extentPosition,
  int nodeLength,
) {
  return (basePosition.offset == 0 && extentPosition.offset == nodeLength) ||
      (basePosition.offset == nodeLength && extentPosition.offset == 0);
}

ExecutionInstruction selectAllInCodeBlockWhenCmdAIsPressed({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (!keyEvent.isPrimaryShortcutKeyPressed ||
      keyEvent.logicalKey != LogicalKeyboardKey.keyA) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null) {
    return ExecutionInstruction.continueExecution;
  }

  // Check if cursor is in a code block
  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is! TextNode) {
    return ExecutionInstruction.continueExecution;
  }

  final blockType = node.getMetadataValue(NodeMetadata.blockType);
  final isCodeBlockNode = node is CodeBlockNode;
  final isParagraphStyledAsCodeBlock =
      !isCodeBlockNode && blockType == codeAttribution;

  if (!isCodeBlockNode && !isParagraphStyledAsCodeBlock) {
    return ExecutionInstruction.continueExecution;
  }

  // Check if the code block is already fully selected
  // Handle both selection directions (base/extent could be swapped)
  final isCodeBlockFullySelected = selection.base.nodeId == node.id &&
      selection.extent.nodeId == node.id &&
      selection.base.nodePosition is TextNodePosition &&
      selection.extent.nodePosition is TextNodePosition &&
      _isCodeBlockFullySelected(
        selection.base.nodePosition as TextNodePosition,
        selection.extent.nodePosition as TextNodePosition,
        node.text.length,
      );

  if (isCodeBlockFullySelected) {
    // Code block is already fully selected, let the default handler select the whole document
    return ExecutionInstruction.continueExecution;
  }

  // Select all content within the code block
  editContext.editor.execute([
    ChangeSelectionRequest(
      DocumentSelection(
        base: DocumentPosition(
          nodeId: node.id,
          nodePosition: node.beginningPosition,
        ),
        extent: DocumentPosition(
          nodeId: node.id,
          nodePosition: node.endPosition,
        ),
      ),
      SelectionChangeType.expandSelection,
      SelectionReason.userInteraction,
    ),
  ]);

  return ExecutionInstruction.haltExecution;
}

class CodeSyntaxHighlightReaction extends EditReaction {
  CodeSyntaxHighlightReaction({
    this.debounceDuration = const Duration(milliseconds: 50),
  });

  /// Duration to wait after a change before highlighting to batch rapid changes.
  final Duration debounceDuration;

  final Map<String, int> _pendingVersions = {};

  /// Tracks the last highlighted text and language for each node to avoid unnecessary re-highlighting.
  final Map<String, _HighlightedState> _lastHighlightedState = {};

  /// Timers for debounced highlighting per node.
  final Map<String, Timer> _debounceTimers = {};

  void scheduleHighlightForNode({
    required DocumentNode node,
    required RequestDispatcher requestDispatcher,
  }) {
    final highlightInput = _HighlightInput.fromNode(node);
    if (highlightInput == null) {
      return;
    }

    // Check if highlighting is already up-to-date
    final lastState = _lastHighlightedState[highlightInput.nodeId];
    if (lastState != null &&
        lastState.plainText == highlightInput.plainText &&
        lastState.language == highlightInput.language) {
      // Already highlighted with the same content and language, skip.
      return;
    }

    // Cancel any pending debounce timer for this node
    _debounceTimers[highlightInput.nodeId]?.cancel();

    // Schedule debounced highlighting
    final timer = Timer(debounceDuration, () {
      _debounceTimers.remove(highlightInput.nodeId);
      _performHighlight(
        highlightInput: highlightInput,
        requestDispatcher: requestDispatcher,
      );
    });
    _debounceTimers[highlightInput.nodeId] = timer;
  }

  void _performHighlight({
    required _HighlightInput highlightInput,
    required RequestDispatcher requestDispatcher,
  }) {
    final nextVersion = (_pendingVersions[highlightInput.nodeId] ?? 0) + 1;
    _pendingVersions[highlightInput.nodeId] = nextVersion;

    unawaited(
      CodeSyntaxHighlighter.instance
          .highlight(
        source: highlightInput.plainText,
        language: highlightInput.language,
      )
          .then((spans) {
        if (_pendingVersions[highlightInput.nodeId] != nextVersion) {
          return;
        }

        // Update cached state before dispatching the command.
        // Note: If the text changes between now and when the command executes,
        // the command will reject the highlight, but the next change will trigger
        // a new highlight anyway, so the cache will be corrected.
        _lastHighlightedState[highlightInput.nodeId] = _HighlightedState(
          plainText: highlightInput.plainText,
          language: highlightInput.language,
        );

        requestDispatcher.execute([
          ApplyCodeBlockHighlightRequest(
            nodeId: highlightInput.nodeId,
            language: highlightInput.language,
            plainText: highlightInput.plainText,
            spans: spans,
          ),
        ]);
      }),
    );
  }

  @override
  void react(EditContext editContext, RequestDispatcher requestDispatcher,
      List<EditEvent> changeList) {
    final nodesToHighlight =
        _collectAffectedCodeBlockNodeIds(editContext, changeList);
    if (nodesToHighlight.isEmpty) {
      return;
    }

    final document = editContext.document;
    for (final nodeId in nodesToHighlight) {
      final node = document.getNodeById(nodeId);
      if (node == null) {
        continue;
      }

      scheduleHighlightForNode(
        node: node,
        requestDispatcher: requestDispatcher,
      );
    }
  }

  Set<String> _collectAffectedCodeBlockNodeIds(
      EditContext editContext, List<EditEvent> changeList) {
    final affected = <String>{};

    for (final event in changeList.whereType<DocumentEdit>()) {
      final change = event.change;
      if (change is NodeDocumentChange) {
        // Handle node removal by clearing cache
        if (change is NodeRemovedEvent) {
          clearCacheForNode(change.nodeId);
          continue;
        }

        // Skip NodeMovedEvent as it doesn't affect content
        if (change is NodeMovedEvent) {
          continue;
        }

        final node = editContext.document.getNodeById(change.nodeId);
        if (node is CodeBlockNode ||
            (node is ParagraphNode &&
                node.getMetadataValue(NodeMetadata.blockType) ==
                    codeAttribution)) {
          // Only highlight for content changes (NodeChangeEvent, NodeInsertedEvent)
          // NodeChangeEvent indicates content changed
          // NodeInsertedEvent indicates a new node was inserted
          if (change is NodeChangeEvent || change is NodeInsertedEvent) {
            affected.add(change.nodeId);
          }
        }
      }
    }

    return affected;
  }

  /// Clears cached state for a node (e.g., when it's removed).
  void clearCacheForNode(String nodeId) {
    _lastHighlightedState.remove(nodeId);
    _debounceTimers[nodeId]?.cancel();
    _debounceTimers.remove(nodeId);
    _pendingVersions.remove(nodeId);
  }

  /// Clears all cached state.
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _lastHighlightedState.clear();
    _pendingVersions.clear();
  }
}

/// Tracks the last highlighted state for a code block node.
class _HighlightedState {
  const _HighlightedState({
    required this.plainText,
    required this.language,
  });

  final String plainText;
  final String language;
}

class _HighlightInput {
  const _HighlightInput({
    required this.nodeId,
    required this.plainText,
    required this.language,
  });

  final String nodeId;
  final String plainText;
  final String language;

  static _HighlightInput? fromNode(DocumentNode node) {
    if (node is CodeBlockNode) {
      return _HighlightInput(
        nodeId: node.id,
        plainText: node.text.toPlainText(includePlaceholders: false),
        language: node.language,
      );
    }

    if (node is ParagraphNode &&
        node.getMetadataValue(NodeMetadata.blockType) == codeAttribution) {
      final metadataLanguage =
          (node.getMetadataValue(kCodeBlockLanguageKey) as String?)?.trim();
      final language = metadataLanguage == null || metadataLanguage.isEmpty
          ? kDefaultCodeLanguage
          : metadataLanguage;

      return _HighlightInput(
        nodeId: node.id,
        plainText: node.text.toPlainText(includePlaceholders: false),
        language: language,
      );
    }

    return null;
  }
}

String _normalizeLanguage(String? language) {
  final normalized = language?.trim() ?? '';
  if (normalized.isEmpty) {
    return kDefaultCodeLanguage;
  }
  return normalized;
}

AttributedText _stripCodeSyntaxHighlights(AttributedText text) {
  final preservedMarkers = text.spans.markers
      .where((marker) => marker.attribution is! CodeSyntaxHighlightAttribution)
      .map((marker) => marker.copyWith())
      .toList();

  return text.replaceAttributions(
    AttributedSpans(attributions: preservedMarkers),
  );
}

List<_HighlightSignature>? _collectExistingCodeSyntaxHighlights(
  AttributedText text,
) {
  final markers = text.spans.markers;
  if (markers.isEmpty) {
    return const <_HighlightSignature>[];
  }

  final pendingStarts =
      LinkedHashMap<CodeSyntaxHighlightAttribution, List<int>>.identity();
  final signatures = <_HighlightSignature>[];

  for (final marker in markers) {
    final attribution = marker.attribution;
    if (attribution is! CodeSyntaxHighlightAttribution) {
      continue;
    }

    if (marker.isStart) {
      (pendingStarts[attribution] ??= <int>[]).add(marker.offset);
      continue;
    }

    final starts = pendingStarts[attribution];
    if (starts == null || starts.isEmpty) {
      return null;
    }

    final start = starts.removeLast();
    signatures.add(
      _HighlightSignature(
        start: start,
        end: marker.offset,
        attribution: attribution,
      ),
    );

    if (starts.isEmpty) {
      pendingStarts.remove(attribution);
    }
  }

  if (pendingStarts.isNotEmpty) {
    return null;
  }

  signatures.sort();
  return signatures;
}

bool _codeBlockHighlightEquals(
    AttributedText text, List<CodeSyntaxHighlightSpan> spans) {
  if (spans.isEmpty) {
    return !text.spans.markers.any(
      (marker) => marker.attribution is CodeSyntaxHighlightAttribution,
    );
  }

  final existingSignatures = _collectExistingCodeSyntaxHighlights(text);
  if (existingSignatures == null) {
    return false;
  }

  if (existingSignatures.length != spans.length) {
    return false;
  }

  final desiredSignatures = spans
      .map((span) => _HighlightSignature(
            start: span.start,
            end: span.end,
            attribution: span.attribution,
          ))
      .toList()
    ..sort();

  for (var i = 0; i < desiredSignatures.length; i += 1) {
    if (existingSignatures[i] != desiredSignatures[i]) {
      return false;
    }
  }

  return true;
}

class _HighlightSignature implements Comparable<_HighlightSignature> {
  const _HighlightSignature({
    required this.start,
    required this.end,
    required this.attribution,
  });

  final int start;
  final int end;
  final CodeSyntaxHighlightAttribution attribution;

  @override
  int compareTo(_HighlightSignature other) {
    final startComparison = start.compareTo(other.start);
    if (startComparison != 0) {
      return startComparison;
    }
    final endComparison = end.compareTo(other.end);
    if (endComparison != 0) {
      return endComparison;
    }
    return attribution.hashCode.compareTo(other.attribution.hashCode);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HighlightSignature &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          attribution == other.attribution;

  @override
  int get hashCode => Object.hash(start, end, attribution);
}

TextStyle _defaultCodeBlockTextStyle(ThemeData theme, Brightness brightness) {
  final colorScheme = theme.colorScheme;
  final Color textColor;
  if (brightness == Brightness.dark) {
    textColor = colorScheme.onSurface;
  } else {
    textColor = colorScheme.onSurface;
  }

  return TextStyle(
    fontFamily: 'SourceCodePro',
    fontSize: 14,
    height: 1.45,
    color: textColor,
  );
}

Color _defaultCodeBlockBackgroundColor(
    ColorScheme colorScheme, Brightness brightness) {
  if (brightness == Brightness.dark) {
    return Color.alphaBlend(
      colorScheme.primaryFixedDim.withOpacity(0.15),
      colorScheme.surface,
    );
  }

  return Color.alphaBlend(
    colorScheme.primaryFixedDim.withOpacity(0.15),
    colorScheme.surface,
  );
}

class _RawHighlightSpan {
  _RawHighlightSpan({
    required this.start,
    required this.end,
    required this.tokenType,
    required this.style,
  });

  final int start;
  final int end;
  final String tokenType;
  final TextStyle style;
}

class _HighlightSpanKey {
  const _HighlightSpanKey(this.start, this.end, this.tokenType);

  final int start;
  final int end;
  final String tokenType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HighlightSpanKey &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          tokenType == other.tokenType;

  @override
  int get hashCode => Object.hash(start, end, tokenType);
}

import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_markdown/super_editor_markdown.dart';

extension RichTextCopy on Document {
  Future<void> copyAsRichTextWithPlainTextFallback({
    DocumentSelection? selection,
  }) async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      return; // Clipboard API is not supported on this platform.
    }

    final item = DataWriterItem();

    // Serialize to HTML as the most common representation of rich text
    // across apps.
    item.add(Formats.htmlText(toHtml(
      selection: selection,
      nodeSerializers: SuperEditorClipboardConfig.nodeHtmlSerializers,
      inlineSerializers: SuperEditorClipboardConfig.inlineHtmlSerializers,
    )));

    // Serialize a backup copy in plain text so that this clipboard content
    // can be pasted into plain-text apps, too.
    item.add(Formats.plainText(toPlainText(selection: selection)));

    // Write the document to the clipboard.
    await clipboard.write([item]);
  }

  Future<void> copyAsRichTextWithMarkdownFallback({
    DocumentSelection? selection,
  }) async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      return; // Clipboard API is not supported on this platform.
    }

    final item = DataWriterItem();

    // Serialize to HTML as the most common representation of rich text
    // across apps.
    item.add(Formats.htmlText(toHtml(
      selection: selection,
      nodeSerializers: SuperEditorClipboardConfig.nodeHtmlSerializers,
      inlineSerializers: SuperEditorClipboardConfig.inlineHtmlSerializers,
    )));

    // Serialize to Markdown as a plain text representation of rich text.
    item.add(Formats.plainText(
      serializeDocumentToMarkdown(this, selection: selection),
    ));

    // Write the document to the clipboard.
    await clipboard.write([item]);
  }
}

extension MarkdownCopy on Document {
  /// Copies the document (or selected portion) as markdown to the clipboard,
  /// with a plain text fallback.
  ///
  /// The markdown is stored as the primary plain text format. If markdown serialization
  /// fails for any reason, a plain text version (without markdown syntax) is provided
  /// as a fallback.
  ///
  /// When [selection] is provided, only the selected range of the document is copied.
  /// When [selection] is `null`, the entire document is copied.
  Future<void> copyAsMarkdown({
    DocumentSelection? selection,
    MarkdownSyntax syntax = MarkdownSyntax.superEditor,
    List<DocumentNodeMarkdownSerializer> customNodeSerializers = const [],
  }) async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      return; // Clipboard API is not supported on this platform.
    }

    final item = DataWriterItem();

    try {
      // Serialize the document to markdown as the primary format.
      final markdown = serializeDocumentToMarkdown(
        this,
        selection: selection,
        syntax: syntax,
        customNodeSerializers: customNodeSerializers,
      );
      item.add(Formats.plainText(markdown));
    } catch (e) {
      // If markdown serialization fails, fall back to plain text without markdown syntax.
      final plainText = toPlainText(selection: selection);
      item.add(Formats.plainText(plainText));
    }

    // Write the document to the clipboard.
    await clipboard.write([item]);
  }
}

/// A global configuration for rich text serializers, which can be globally customized
/// within an app to add or change the serializers used by [Document.copyAsRichText].
abstract class SuperEditorClipboardConfig {
  static NodeHtmlSerializerChain get nodeHtmlSerializers =>
      _nodeHtmlSerializers;
  static NodeHtmlSerializerChain _nodeHtmlSerializers =
      defaultNodeHtmlSerializerChain;
  static void setNodeHtmlSerializers(NodeHtmlSerializerChain nodeSerializers) =>
      _nodeHtmlSerializers = nodeSerializers;

  static InlineHtmlSerializerChain get inlineHtmlSerializers =>
      _inlineHtmlSerializers;
  static InlineHtmlSerializerChain _inlineHtmlSerializers =
      defaultInlineHtmlSerializers;
  static void setInlineHtmlSerializers(
          InlineHtmlSerializerChain inlineSerializers) =>
      _inlineHtmlSerializers = inlineSerializers;
}

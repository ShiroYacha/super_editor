import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import '../supereditor_test_tools.dart';

void main() {
  group('Code block keyboard', () {
    testWidgetsOnAllPlatforms('Tab indents current line from caret position', (tester) async {
      const codeNodeId = 'code-1';

      final context = await tester
          .createDocument()
          .withCustomContent(
            MutableDocument(
              nodes: [
                CodeBlockNode(
                  id: codeNodeId,
                  text: AttributedText('line'),
                ),
              ],
            ),
          )
          .pump();

      await tester.placeCaretInParagraph(codeNodeId, 2);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final codeNode = context.document.getNodeById(codeNodeId) as CodeBlockNode;
      expect(codeNode.text.toPlainText(), '  line');

      final selection = context.composer.selection!;
      final extentPosition = selection.extent.nodePosition as TextNodePosition;
      expect(extentPosition.offset, 4);
    });

    testWidgetsOnAllPlatforms('Shift+Tab removes indentation from current line', (tester) async {
      const codeNodeId = 'code-1';

      final context = await tester
          .createDocument()
          .withCustomContent(
            MutableDocument(
              nodes: [
                CodeBlockNode(
                  id: codeNodeId,
                  text: AttributedText('  line'),
                ),
              ],
            ),
          )
          .pump();

      await tester.placeCaretInParagraph(codeNodeId, 4);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      final codeNode = context.document.getNodeById(codeNodeId) as CodeBlockNode;
      expect(codeNode.text.toPlainText(), 'line');

      final selection = context.composer.selection!;
      final extentPosition = selection.extent.nodePosition as TextNodePosition;
      expect(extentPosition.offset, 2);
    });
  });
}


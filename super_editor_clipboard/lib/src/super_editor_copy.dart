import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_clipboard/src/document_copy.dart';

/// [SuperEditor] shortcut to copy the document as rich text when
/// `CMD + C` (Mac) or `CTRL + C` (Windows/Linux) is pressed.
ExecutionInstruction copyAsRichTextWhenCmdCOrCtrlCIsPressed({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (!keyEvent.isPrimaryShortcutKeyPressed ||
      keyEvent.logicalKey != LogicalKeyboardKey.keyC) {
    return ExecutionInstruction.continueExecution;
  }
  if (editContext.composer.selection == null) {
    return ExecutionInstruction.continueExecution;
  }
  if (editContext.composer.selection!.isCollapsed) {
    // Nothing to copy, but we technically handled the task.
    return ExecutionInstruction.haltExecution;
  }

  editContext.document.copyAsRichTextWithPlainTextFallback(
    selection: editContext.composer.selection!,
  );

  return ExecutionInstruction.haltExecution;
}

/// [SuperEditor] shortcut to cut the document as rich text when
/// `CMD + X` (Mac) or `CTRL + X` (Windows/Linux) is pressed.
ExecutionInstruction cutAsRichTextWhenCmdXOrCtrlXIsPressed({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (!keyEvent.isPrimaryShortcutKeyPressed ||
      keyEvent.logicalKey != LogicalKeyboardKey.keyX) {
    return ExecutionInstruction.continueExecution;
  }
  if (editContext.composer.selection == null) {
    return ExecutionInstruction.continueExecution;
  }
  if (editContext.composer.selection!.isCollapsed) {
    // Nothing to cut, but we technically handled the task.
    return ExecutionInstruction.haltExecution;
  }

  // Copy the selection as rich text to the clipboard
  editContext.document.copyAsRichTextWithPlainTextFallback(
    selection: editContext.composer.selection!,
  );

  // Delete the selected content
  editContext.commonOps.deleteSelection(TextAffinity.downstream);

  return ExecutionInstruction.haltExecution;
}

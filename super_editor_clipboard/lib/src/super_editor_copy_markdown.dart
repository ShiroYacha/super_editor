import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_clipboard/super_editor_clipboard.dart';

/// [SuperEditor] shortcut to copy the document as markdown when
/// `CMD + C` (Mac) or `CTRL + C` (Windows/Linux) is pressed.
ExecutionInstruction copyAsMarkdownWhenCmdCOrCtrlCIsPressed({
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

  editContext.document.copyAsMarkdown(
    selection: editContext.composer.selection!,
  );

  return ExecutionInstruction.haltExecution;
}

/// [SuperEditor] shortcut to cut the document as markdown when
/// `CMD + X` (Mac) or `CTRL + X` (Windows/Linux) is pressed.
ExecutionInstruction cutAsMarkdownWhenCmdXOrCtrlXIsPressed({
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

  // Copy the selection as markdown to the clipboard
  editContext.document.copyAsMarkdown(
    selection: editContext.composer.selection!,
  );

  // Delete the selected content
  editContext.commonOps.deleteSelection(TextAffinity.downstream);

  return ExecutionInstruction.haltExecution;
}

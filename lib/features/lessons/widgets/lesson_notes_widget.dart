import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// A widget that provides note-taking functionality for lessons.
/// 
/// This widget appears as an overlay with a glassmorphic design and
/// provides rich text editing capabilities with auto-save functionality.
class LessonNotesWidget extends StatefulWidget {
  /// The initial notes content
  final String initialNotes;
  
  /// Callback when notes are saved
  final Function(String) onSave;
  
  /// Callback when the notes widget is closed
  final VoidCallback onClose;
  
  const LessonNotesWidget({
    Key? key,
    this.initialNotes = '',
    required this.onSave,
    required this.onClose,
  }) : super(key: key);

  @override
  State<LessonNotesWidget> createState() => _LessonNotesWidgetState();
}

class _LessonNotesWidgetState extends State<LessonNotesWidget> {
  late quill.QuillController _controller;
  Timer? _autoSaveTimer;
  bool _isDirty = false;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the QuillController with the initial notes
    if (widget.initialNotes.isEmpty) {
      _controller = quill.QuillController.basic();
    } else {
      try {
        // Try to parse the notes as Delta JSON
        final document = quill.Document.fromJson(
          widget.initialNotes.isNotEmpty 
              ? widget.initialNotes.startsWith('[') 
                  ? widget.initialNotes 
                  : '[{"insert":"${widget.initialNotes}\\n"}]'
              : '[{"insert":"\\n"}]'
        );
        _controller = quill.QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // If parsing fails, create a new document with the text
        final document = quill.Document()
          ..insert(0, widget.initialNotes);
        _controller = quill.QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }
    
    // Listen for changes to mark as dirty
    _controller.document.changes.listen((event) {
      if (!_isDirty) {
        setState(() {
          _isDirty = true;
        });
      }
    });
    
    // Set up auto-save timer
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isDirty) {
        _saveNotes();
      }
    });
  }
  
  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _saveNotes() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Convert the document to JSON
      final json = _controller.document.toDelta().toJson();
      final jsonString = json.toString();
      
      // Save the notes
      widget.onSave(jsonString);
      
      setState(() {
        _isDirty = false;
      });
    } catch (e) {
      debugPrint('Error saving notes: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Center(
      child: Container(
        width: size.width * 0.9,
        height: size.height * 0.7,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Header with title and close button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Lesson Notes',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        _isDirty
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Unsaved',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Saved',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            if (_isDirty) {
                              _saveNotes().then((_) {
                                widget.onClose();
                              });
                            } else {
                              widget.onClose();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Toolbar
                  quill.QuillToolbar.basic(
                    controller: _controller,
                    showFontFamily: false,
                    showFontSize: true,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: true,
                    showColorButton: true,
                    showBackgroundColorButton: true,
                    showClearFormat: true,
                    showAlignmentButtons: true,
                    showLeftAlignment: true,
                    showCenterAlignment: true,
                    showRightAlignment: true,
                    showJustifyAlignment: true,
                    showHeaderStyle: true,
                    showListNumbers: true,
                    showListBullets: true,
                    showListCheck: true,
                    showCodeBlock: true,
                    showQuote: true,
                    showIndent: true,
                    showLink: true,
                    showUndo: true,
                    showRedo: true,
                    multiRowsDisplay: false,
                    toolbarIconSize: 20,
                    toolbarSectionSpacing: 4,
                    color: Colors.white,
                    backgroundColor: Colors.black45,
                  ),
                  
                  // Editor
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: quill.QuillEditor(
                          controller: _controller,
                          scrollController: ScrollController(),
                          scrollable: true,
                          focusNode: FocusNode(),
                          autoFocus: true,
                          readOnly: false,
                          placeholder: 'Take notes here...',
                          expands: false,
                          padding: EdgeInsets.zero,
                          customStyles: quill.DefaultStyles(
                            placeHolder: quill.DefaultTextBlockStyle(
                              TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 16,
                              ),
                              const VerticalSpacing(6, 0),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                            paragraph: quill.DefaultTextBlockStyle(
                              TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              const VerticalSpacing(6, 0),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                            h1: quill.DefaultTextBlockStyle(
                              TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              const VerticalSpacing(12, 0),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                            h2: quill.DefaultTextBlockStyle(
                              TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              const VerticalSpacing(10, 0),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                            h3: quill.DefaultTextBlockStyle(
                              TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              const VerticalSpacing(8, 0),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Auto-save every 30 seconds',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveNotes,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save, size: 16),
                          label: Text(_isSaving ? 'Saving...' : 'Save Notes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

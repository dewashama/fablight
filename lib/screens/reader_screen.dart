import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:epub_view/epub_view.dart';

class ReaderScreen extends StatefulWidget {
  final String filePath;
  final String title;
  final Map<String, int>? pdfChapters; // optional: chapter title -> page number

  const ReaderScreen({
    super.key,
    required this.filePath,
    required this.title,
    this.pdfChapters,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  PdfController? _pdfController;
  EpubController? _epubController;

  bool _isPdf = false;
  bool _isEpub = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initDoc();
  }

  Future<void> _initDoc() async {
    final path = widget.filePath;
    _isPdf = path.toLowerCase().endsWith('.pdf');
    _isEpub = path.toLowerCase().endsWith('.epub');

    if (_isPdf) {
      _pdfController = PdfController(
        document: PdfDocument.openFile(path),
      );
    } else if (_isEpub) {
      final bytes = await File(path).readAsBytes();
      _epubController = EpubController(
        document: EpubDocument.openData(bytes),
      );
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _epubController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: (_isEpub && _epubController != null) || (_isPdf && widget.pdfChapters != null)
          ? Drawer(
        child: _isEpub
        // Use built-in Table of Contents for EPUB
            ? EpubViewTableOfContents(controller: _epubController!)
        // Use custom chapter list for PDF
            : ListView(
          children: widget.pdfChapters!.entries.map((entry) {
            return ListTile(
              title: Text(entry.key),
              onTap: () {
                _pdfController!.animateToPage(
                  entry.value,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      )
          : null,
      body: _isPdf
          ? PdfView(controller: _pdfController!)
          : (_isEpub && _epubController != null)
          ? EpubView(controller: _epubController!)
          : const Center(child: Text("Unsupported format")),
    );
  }
}

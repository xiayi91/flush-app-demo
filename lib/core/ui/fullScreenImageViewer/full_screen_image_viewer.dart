import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final File? imageFile;
  final List<String>? galleryImagesList;
  final int? index;

  const FullScreenImageViewer({
    Key? key,
    required this.imageUrl,
    this.imageFile,
    this.galleryImagesList,
    this.index,
  }) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  PageController? controller;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.galleryImagesList != null) {
      currentIndex = widget.index!;
      controller = PageController(initialPage: widget.index!);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black26,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.black,
        child: Hero(
          tag: widget.imageUrl,
          child: widget.galleryImagesList != null
              ? Stack(
                  children: [
                    PhotoViewGallery.builder(
                      pageController: controller,
                      onPageChanged: (index) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                      scrollPhysics: const BouncingScrollPhysics(),
                      itemCount: widget.galleryImagesList!.length,
                      builder: (context, index) {
                        return PhotoViewGalleryPageOptions(
                          imageProvider:
                              NetworkImage(widget.galleryImagesList![index]),
                          initialScale: PhotoViewComputedScale.contained,
                          minScale: PhotoViewComputedScale.contained *
                              (0.5 + index / 10),
                          maxScale: PhotoViewComputedScale.covered * 4.1,
                        );
                      },
                      loadingBuilder: (context, event) => const Center(
                        child: SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: const BoxDecoration(
                            color: Colors.grey,
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                        child: Text(
                          '${currentIndex + 1} of ${widget.galleryImagesList!.length}',
                          style: const TextStyle(
                              fontSize: 17, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              : PhotoView(
                  loadingBuilder: (context, event) =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  imageProvider: widget.imageFile == null
                      ? NetworkImage(widget.imageUrl)
                      : Image.file(widget.imageFile!).image,
                ),
        ),
      ),
    );
  }
}

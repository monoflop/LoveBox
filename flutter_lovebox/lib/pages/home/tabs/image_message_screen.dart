import 'dart:typed_data';

import 'package:dither/dither.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lovebox/constants/constants.dart';
import 'package:lovebox/cropper/mobile_ui_helper.dart';
import 'package:lovebox/helper/image_encoder.dart';
import 'package:lovebox/helper/image_filter.dart';
import 'package:lovebox/helper/snackbar_helper.dart';
import 'package:lovebox/model/love_box_message.dart';
import 'package:lovebox/services/lovebox/lovebox_service.dart';
import 'package:lovebox/services/storage_service.dart';
import 'package:lovebox/wigets/divider.dart';
import 'package:lovebox/wigets/message_status_dialog.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

//TODO implement better way to handle image editing
//TODO so image is not encoded constantly
class ImageMessagePage extends StatefulWidget {
  final LoveBox loveBox;

  const ImageMessagePage({required this.loveBox, Key? key}) : super(key: key);

  @override
  State<ImageMessagePage> createState() => _ImageMessagePageState();
}

class _ImageMessagePageState extends State<ImageMessagePage> {
  final ExpandableController _expandableController = ExpandableController();

  Uint8List? _tempPreviewImage;
  Uint8List? _selectedImage;

  ImageFilter _imageFilter = ImageFilter();

  @override
  void dispose() {
    _expandableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(uiDefaultPadding), children: [
      Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.black,
        child: Material(
          color: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: InkWell(
            onTap: () {
              //Show bottomsheet
              showMaterialModalBottomSheet(
                context: context,
                builder: (context) => Material(
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text("Import"),
                          leading: const Icon(Icons.import_export),
                          onTap: () {
                            _importImage(ImageSource.gallery);
                            Navigator.of(context).pop();
                          },
                        ),
                        const HorizontalDivider(),
                        ListTile(
                          title: const Text("Pick from Camera"),
                          leading: const Icon(Icons.camera_alt),
                          onTap: () {
                            _selectImage(ImageSource.camera);
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          title: const Text("Pick from Gallery"),
                          leading: const Icon(Icons.image_search),
                          onTap: () {
                            _selectImage(ImageSource.gallery);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(15),
            child: AspectRatio(
              aspectRatio: 2 / 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Center(
                    child: Icon(
                      Icons.image_search,
                      color: Colors.white54,
                    ),
                  ),
                  if (_tempPreviewImage != null)
                    Image.memory(
                      _tempPreviewImage!,
                      fit: BoxFit.contain,
                      isAntiAlias: false,
                      filterQuality: FilterQuality.none,
                    ),
                  if (_tempPreviewImage != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.4),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _tempPreviewImage = null;
                                    _selectedImage = null;
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(
        height: 32.0,
      ),
      ListTile(
        title: const Text(
          "Filters",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        onTap: () {
          setState(() {
            _expandableController.toggle();
          });
        },
        trailing: const Icon(Icons.keyboard_arrow_down),
      ),
      Expandable(
          controller: _expandableController,
          collapsed: Container(),
          expanded: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HorizontalDivider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _imageFilter = ImageFilter();
                          _applyFilter();
                        });
                      },
                      child: const Text("RESET FILTER")),
                ],
              ),
              const HorizontalDivider(),
              ListTile(
                title: const Text("Dithering"),
                trailing: Text(
                  "${_imageFilter.threshold}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              Slider(
                value: _imageFilter.threshold.toDouble(),
                min: 0,
                max: 254,
                onChanged: (double value) {
                  setState(() {
                    _imageFilter.threshold = value.toInt();
                    _applyFilter();
                  });
                },
              ),
              const HorizontalDivider(),
              ListTile(
                title: const Text("Brightness"),
                trailing: Text(
                  "${_imageFilter.brightness}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              Slider(
                value: _imageFilter.brightness.toDouble(),
                min: -100,
                max: 100,
                onChanged: (double value) {
                  setState(() {
                    _imageFilter.brightness = value.toInt();
                    _applyFilter();
                  });
                },
              ),
              const HorizontalDivider(),
              ListTile(
                title: const Text("Contrast"),
                trailing: Text(
                  "${_imageFilter.contrast}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              Slider(
                value: _imageFilter.contrast.toDouble(),
                min: 0,
                max: 200,
                onChanged: (double value) {
                  setState(() {
                    _imageFilter.contrast = value.toInt();
                    _applyFilter();
                  });
                },
              ),
              const HorizontalDivider(),
              CheckboxListTile(
                  title: const Text("Invert Source"),
                  value: _imageFilter.inverted,
                  onChanged: (value) {
                    setState(() {
                      _imageFilter.inverted = value!;
                      _applyFilter();
                    });
                  }),
              CheckboxListTile(
                  title: const Text("Grayscale"),
                  value: _imageFilter.grayscale,
                  onChanged: (value) {
                    setState(() {
                      _imageFilter.grayscale = value!;
                      _applyFilter();
                    });
                  }),
              CheckboxListTile(
                  title: const Text("Sobel"),
                  value: _imageFilter.sobel,
                  onChanged: (value) {
                    setState(() {
                      _imageFilter.sobel = value!;
                      _applyFilter();
                    });
                  }),
              const HorizontalDivider(),
            ],
          )),
      const SizedBox(
        height: uiDefaultPadding,
      ),
      ElevatedButton(
          onPressed: () {
            if (_tempPreviewImage != null) {
              String imageBase64 = _base64EncodeImage(_tempPreviewImage!);
              MessageStatusDialog.showStatusDialog(
                  context, widget.loveBox, LoveBoxMessage.image(imageBase64));
            }
          },
          child: const Center(child: Text("SEND"))),
      OutlinedButton(
          onPressed: () async {
            if (_tempPreviewImage != null) {
              String imageBase64 = _base64EncodeImage(_tempPreviewImage!);
              await StorageService.instance
                  .add(LoveBoxMessage.image(imageBase64));

              if (!mounted) {
                return;
              }

              SnackBarHelper.showInfoMessage(context, "Message saved");
            }
          },
          child: const Text("SAVE"))
    ]);
  }

  _importImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showErrorMessage(context, "Invalid image file");
      return;
    }

    Uint8List tmpData = await image.readAsBytes();
    List<int> tmpDataInt = List<int>.from(tmpData);
    image_lib.Image? img = image_lib.decodeImage(tmpDataInt);
    if (img == null) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showErrorMessage(context, "Image loading failed");
      return;
    }

    //Check if image has right dimensions
    if (img.width != 128 || img.height != 64) {
      SnackBarHelper.showErrorMessage(
          context, "Image has invalid dimensions required 128x64");
      return;
    }

    image_lib.Image filterImg = img.clone();

    Uint8List filterData = Uint8List.fromList(image_lib.encodePng(filterImg));
    Uint8List originalData = Uint8List.fromList(image_lib.encodePng(img));
    setState(() {
      _tempPreviewImage = filterData;
      _selectedImage = originalData;
    });
  }

  _selectImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showErrorMessage(context, "Invalid image file");
      return;
    }

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 2, ratioY: 1),
      cropStyle: CropStyle.rectangle,
      compressFormat: ImageCompressFormat.png,
      compressQuality: 100,
      uiSettings: buildUiSettings(context),
    );

    if (croppedFile == null) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showGenericErrorMessage(context);
      return;
    }

    Uint8List tmpData = await croppedFile.readAsBytes();
    List<int> tmpDataInt = List<int>.from(tmpData);
    image_lib.Image? img = image_lib.decodeImage(tmpDataInt);
    if (img == null) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showErrorMessage(context, "Image loading failed");
      return;
    }
    img = image_lib.copyResize(img, width: 128, height: 64);
    if (img == null) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showErrorMessage(context, "Image resize failed");
      return;
    }

    image_lib.Image filterImg = img.clone();
    dither(filterImg, threshold: _imageFilter.threshold);
    _reduceColors(filterImg);

    Uint8List filterData = Uint8List.fromList(image_lib.encodePng(filterImg));

    Uint8List originalData = Uint8List.fromList(image_lib.encodePng(img));

    setState(() {
      _tempPreviewImage = filterData;
      _selectedImage = originalData;
    });
  }

  _applyFilter() {
    if (_selectedImage == null) {
      return;
    }

    List<int> tmpDataInt = List<int>.from(_selectedImage!);
    image_lib.Image? img = image_lib.decodeImage(tmpDataInt);

    if (img == null) {
      return;
    }

    if (_imageFilter.inverted) {
      img = image_lib.invert(img);
    }

    if (_imageFilter.grayscale) {
      img = image_lib.grayscale(img);
    }

    if (_imageFilter.brightness != 0) {
      image_lib.brightness(img, _imageFilter.brightness);
    }

    if (_imageFilter.sobel) {
      image_lib.sobel(img);
    }

    if (_imageFilter.contrast != 100) {
      image_lib.contrast(img, _imageFilter.contrast);
    }

    dither(img, threshold: _imageFilter.threshold);
    _reduceColors(img);

    setState(() {
      if (img != null) {
        _tempPreviewImage = Uint8List.fromList(image_lib.encodeBmp(img));
      }
    });
  }

  _reduceColors(image_lib.Image image) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (Color(image.getPixel(x, y)) != Colors.black) {
          image.setPixel(x, y, Colors.white.value);
        }
      }
    }
  }

  String _base64EncodeImage(Uint8List imageData) {
    List<int> tmpDataInt = List<int>.from(imageData);
    image_lib.Image? img = image_lib.decodeImage(tmpDataInt);
    String imageBase64 = ImageEncoder.encodeImage(img!);
    return imageBase64;
  }
}

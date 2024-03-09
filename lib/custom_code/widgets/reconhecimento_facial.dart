// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class ReconhecimentoFacial extends StatefulWidget {
  const ReconhecimentoFacial({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  _ReconhecimentoFacialState createState() => _ReconhecimentoFacialState();
}

class _ReconhecimentoFacialState extends State<ReconhecimentoFacial> {
  late final CameraController _cameraController;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      // Seleciona a câmera frontal
      cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front),
      ResolutionPreset.medium,
    );
    _cameraController.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Câmera
        _cameraController.value.isInitialized
            ? AspectRatio(
                aspectRatio: _cameraController.value.aspectRatio,
                child: CameraPreview(_cameraController),
              )
            : Container(),
      ],
    );
  }

  Widget _buildButtons() {
    return Positioned(
      bottom: 20.0,
      left: 20.0,
      right: 20.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão 1
          ElevatedButton(
            onPressed: () {},
            child: Text('Botão 1'),
          ),
          // Botão 2
          ElevatedButton(
            onPressed: () {},
            child: Text('Botão 2'),
          ),
        ],
      ),
    );
  }
}

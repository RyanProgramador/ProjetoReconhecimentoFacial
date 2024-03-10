// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:camera/camera.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class ReconhecimentoFacial extends StatefulWidget {
  final double? width;
  final double? height;

  const ReconhecimentoFacial({Key? key, this.width, this.height})
      : super(key: key);

  @override
  State<ReconhecimentoFacial> createState() => _ReconhecimentoFacialState();
}

class _ReconhecimentoFacialState extends State<ReconhecimentoFacial> {
  late CameraController _cameraController;
  Future<void>? _initializeCameraFuture;
  bool _treinado = false;
  final FaceDetector _faceDetector = GoogleVision.instance.faceDetector();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.length > 1 ? cameras[1] : cameras[0];

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
    _initializeCameraFuture = _cameraController.initialize().then((_) {
      setState(() {});
    }).catchError((e) {
      print('Error initializing camera: $e');
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> salvarRosto(Face face) async {
    final prefs = await SharedPreferences.getInstance();
    final faceRect = face.boundingBox;
    final faceDataAsList = [
      faceRect.left,
      faceRect.top,
      faceRect.right,
      faceRect.bottom
    ];
    await prefs.setStringList(
        'rostoTreinado', faceDataAsList.map((e) => e.toString()).toList());
    _treinado = true;
  }

  Future<bool> validarRosto(Face face) async {
    final prefs = await SharedPreferences.getInstance();
    final rostoTreinado = prefs.getStringList('rostoTreinado');

    if (rostoTreinado == null) return false;

    final faceRect = face.boundingBox;
    final newFaceData = [
      faceRect.left,
      faceRect.top,
      faceRect.right,
      faceRect.bottom
    ];

    double distancia = 0.0;
    for (int i = 0; i < 4; i++) {
      distancia += pow(double.parse(rostoTreinado[i]) - newFaceData[i], 2);
    }
    distancia = sqrt(distancia);

    const limiteDistancia = 50.0;
    return distancia <= limiteDistancia;
  }

  Widget _buildCameraPreview() {
    return FutureBuilder<void>(
      future: _initializeCameraFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text('Error initializing camera: ${snapshot.error}');
          }
          return CameraPreview(_cameraController);
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _buildCameraPreview(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _treinado
                    ? null
                    : () async {
                        try {
                          final image = await _cameraController.takePicture();
                          final visionImage =
                              GoogleVisionImage.fromFilePath(image.path);
                          final faces =
                              await _faceDetector.processImage(visionImage);

                          if (faces.isNotEmpty) {
                            await salvarRosto(faces.first);
                            showDialog(
                              context: context,
                              builder: (context) => const AlertDialog(
                                title: Text('Rosto treinado com sucesso!'),
                              ),
                            );
                          } else {
                            print("Nenhum rosto detectado!");
                          }
                        } catch (e) {
                          print('Erro ao capturar imagem: $e');
                        }
                      },
                child: const Text('Treinar'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final image = await _cameraController.takePicture();
                    final visionImage =
                        GoogleVisionImage.fromFilePath(image.path);
                    final faces = await _faceDetector.processImage(visionImage);

                    if (faces.isNotEmpty) {
                      final face = faces.first;
                      if (await validarRosto(face)) {
                        showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                            title: Text('Acesso autorizado!'),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                            title: Text('Acesso negado!'),
                          ),
                        );
                      }
                    } else {
                      print("Nenhum rosto detectado!");
                    }
                  } catch (e) {
                    print('Erro ao capturar imagem: $e');
                  }
                },
                child: const Text('Validar Acesso'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

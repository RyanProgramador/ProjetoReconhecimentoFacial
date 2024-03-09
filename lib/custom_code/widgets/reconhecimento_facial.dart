// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ReconhecimentoFacial extends StatefulWidget {
  const ReconhecimentoFacial({Key? key}) : super(key: key);

  @override
  _ReconhecimentoFacialState createState() => _ReconhecimentoFacialState();
}

class _ReconhecimentoFacialState extends State<ReconhecimentoFacial> {
  CameraController? _cameraController;
  bool _isDetectingFaces = false;
  List<Face>? _faces;
  String? _nomePessoa;
  List<dynamic>? _embeddings;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadFaceNetModel();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController?.initialize();
    _cameraController?.startImageStream((image) => _onImageAvailable(image));
  }

  Future _loadFaceNetModel() async {
    final model = await TfliteModel.load('assets/facenet.tflite');
    await Tflite.initialize(model: model);
  }

  void _onImageAvailable(CameraImage image) async {
    if (_isDetectingFaces) return;

    _isDetectingFaces = true;

    final img.Image convertedImage = _convertCameraImage(image);
    final faces = await _predictFaces(convertedImage);

    if (mounted) {
      setState(() {
        _faces = faces;
      });
    }

    _isDetectingFaces = false;
  }

  img.Image _convertCameraImage(CameraImage image) {
    final img.Image convertedImage = img.Image.fromBytes(
      image.planes[0].bytes,
      width: image.width,
      height: image.height,
    );
    return convertedImage;
  }

  Future<List<Face>> _predictFaces(img.Image image) async {
    final recognitions = await Tflite.detectFaces(
      image,
      threshold: 0.5,
      model: 'facenet',
    );
    return recognitions.map((r) => Face(r)).toList();
  }

  void _salvarPessoa() async {
    if (_faces == null || _faces!.isEmpty) return;

    final face = _faces![0];
    final img.Image croppedImage = _cropFace(face, image);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$_nomePessoa.jpg';
    await croppedImage.writeJpeg(path);

    final embeddings = await _predictEmbedding(croppedImage);
    _embeddings!.add(embeddings);
  }

  img.Image _cropFace(Face face, img.Image image) {
    final x = face.boundingBox.left.toInt();
    final y = face.boundingBox.top.toInt();
    final w = face.boundingBox.width.toInt();
    final h = face.boundingBox.height.toInt();
    return img.copyCrop(image, x, y, w, h);
  }

  Future<dynamic> _predictEmbedding(img.Image image) async {
    final embeddings = await Tflite.runModelOnBinary(
      image.getBytes(),
      numResults: 1,
      model: 'facenet',
    );
    return embeddings[0];
  }

  void _reconhecerPessoa() async {
    if (_faces == null || _faces!.isEmpty) return;

    final face = _faces![0];
    final img.Image croppedImage = _cropFace(face, image);

    final embeddings = await _predictEmbedding(croppedImage);

    final distances = _calculateDistances(embeddings);
    final closestPerson = _findClosestPerson(distances);

    if (closestPerson != null) {
      // Reconhecimento bem-sucedido
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reconhecido: $closestPerson'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Reconhecimento falhou
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pessoa não reconhecida'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<double> _calculateDistances(dynamic embeddings) {
    // Calcula a distância euclidiana entre o embedding da face capturada e os embeddings salvos
    final distances = [];
    for (var savedEmbedding in _embeddings!) {
      final distance = _euclideanDistance(embeddings, savedEmbedding);
      distances.add(distance);
    }
    return distances;
  }

  double _euclideanDistance(dynamic a, dynamic b) {
    // Calcula a distância euclidiana entre dois vetores
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = (a[i] - b[i]);
      sum += diff * diff;
    }
    return math.sqrt(sum);
  }

  String? _findClosestPerson(List<double> distances) {
    // Encontra a pessoa com a menor distância (mais parecida)
    int bestIndex = 0;
    double bestDistance = double.infinity;
    for (int i = 0; i < distances.length; i++) {
      if (distances[i] < bestDistance) {
        bestDistance = distances[i];
        bestIndex = i;
      }
    }
    if (bestDistance < 1.0) {
      // Ajuste o valor limite para maior precisão
      return _nomePessoaList?[bestIndex];
    }
    return null;
  }

  // Variáveis adicionais para salvar nomes e embeddings
  List<String>? _nomePessoaList;

  // Função para abrir modal para salvar pessoa
  void _openSalvarPessoaModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Nome da Pessoa'),
              onChanged: (value) => _nomePessoa = value,
            ),
            ElevatedButton(
              onPressed: _salvarPessoa,
              child: Text('Salvar Pessoa'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reconhecimento Facial'),
      ),
      body: Stack(
        children: [
          // Exibir a visualização da câmera
          _cameraController!.view,
          // Desenhar retângulos nas faces detectadas
          _faces != null
              ? CustomPaint(
                  painter: FacePainter(_faces!),
                  child: Container(),
                )
              : Container(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _openSalvarPessoaModal,
            child: Icon(Icons.add),
          ),
          SizedBox(width: 10.0),
          FloatingActionButton(
            onPressed: _reconhecerPessoa,
            child: Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;

  FacePainter(this.faces);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var face in faces) {
      final rect = face.boundingBox;
      canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height), paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) => oldDelegate.faces != faces;
}

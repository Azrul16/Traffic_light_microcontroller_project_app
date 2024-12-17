import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(LiveStreamingApp());

class LiveStreamingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamPage(),
    );
  }
}

class StreamPage extends StatefulWidget {
  @override
  _StreamPageState createState() => _StreamPageState();
}

class _StreamPageState extends State<StreamPage> {
  RTCVideoRenderer _renderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  bool isStreaming = false;
  String streamId = "streamId_ZpDgIl6TG";
  String serverUrl =
      "http://192.168.1.105:5080/WebRTCApp"; // Replace with your server URL

  @override
  void initState() {
    super.initState();
    _renderer.initialize();
  }

  @override
  void dispose() {
    _renderer.dispose();
    _localStream?.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  Future<void> _startStream() async {
    // Step 1: Create a live stream on Ant Media Server
    final response = await http.post(
      Uri.parse("$serverUrl/rest/v2/broadcasts/create"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": "Test Stream", "type": "liveStream"}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      streamId = data['streamId'];
      print("Stream Created: $streamId");

      // Step 2: Initialize the WebRTC stream
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });
      _renderer.srcObject = _localStream;

      // Step 3: Connect to Ant Media Server using WebRTC
      await _connectToServer();

      setState(() {
        isStreaming = true;
      });
    } else {
      print("Failed to create stream: ${response.body}");
    }
  }

  Future<void> _connectToServer() async {
    // Step 1: Create PeerConnection
    final configuration = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"}
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    // Add local stream to PeerConnection
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    }

    // Step 2: Create offer
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Step 3: Send offer to Ant Media Server
    final signalingResponse = await http.post(
      Uri.parse("$serverUrl/webRTCAdaptor/offer"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "streamId": streamId,
        "sdp": offer.sdp,
        "type": offer.type,
      }),
    );

    if (signalingResponse.statusCode == 200) {
      final data = jsonDecode(signalingResponse.body);
      String? answerSdp = data["sdp"];

      if (answerSdp != null) {
        RTCSessionDescription answer =
            RTCSessionDescription(answerSdp, "answer");
        await _peerConnection!.setRemoteDescription(answer);
      }
    } else {
      print("Failed to connect to signaling server: ${signalingResponse.body}");
    }

    // Step 4: Handle ICE candidates
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null) {
        http.post(
          Uri.parse("$serverUrl/webRTCAdaptor/iceCandidate"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "streamId": streamId,
            "candidate": candidate.toMap(),
          }),
        );
      }
    };
  }

  void _stopStream() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _peerConnection?.close();
    setState(() {
      isStreaming = false;
      _localStream = null;
      _peerConnection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Streaming'),
      ),
      body: Column(
        children: [
          Expanded(
            child: RTCVideoView(_renderer),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: isStreaming ? _stopStream : _startStream,
              child: Text(isStreaming ? 'Stop Streaming' : 'Start Streaming'),
            ),
          ),
        ],
      ),
    );
  }
}

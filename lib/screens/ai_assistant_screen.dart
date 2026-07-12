import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/gemini_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  final List<Map<String, String>> _history = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _loading = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _ttsEnabled = true;

  final List<String> _suggestions = [
    'মিরপুর-১০ থেকে মতিঝিল কত টাকা?',
    'উত্তরা থেকে ফার্মগেট কোন বাসে যাবো?',
    'অতিরিক্ত ভাড়া নিলে কী করবো?',
    'রাতে বাস ভাড়া বেশি নিতে পারে?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
    _initTts();
    _messages.add({
      'role': 'bot',
      'text': 'আসসালামু আলাইকুম! আমি ট্র্যাকি 🚌\nঢাকার বাসের ভাড়া ও রুট নিয়ে যেকোনো প্রশ্ন করুন।\n\nচ্যাটে লিখুন বা মাইক্রোফোন বাটন ধরে বাংলায় বলুন 🎤',
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech.stop();
    _tts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isListening) {
      _stopListening();
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("bn-BD");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    if (!_ttsEnabled) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (status == 'notListening' && _isListening && mounted) {
          _onSpeechEnd();
        }
      },
    );
    if (mounted) {
      setState(() => _speechAvailable = available);
    }
    if (available && mounted) {
      final locales = await _speech.locales();
      final hasBn = locales.any((l) => l.localeId == 'bn_BD');
      if (!hasBn) {
        _showSnackBar('বাংলা (বাংলাদেশ) স্পিচ রিকগনিশন এই ডিভাইসে নেই। ইংরেজিতে বললে বাংলায় লিখবে।');
      }
    }
  }

  void _onSpeechEnd() {
    setState(() => _isListening = false);
    if (_controller.text.trim().isNotEmpty) {
      _send(_controller.text);
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
      return;
    }
    await _startListening();
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showSnackBar('মাইক্রোফোন সাপোর্ট করে না এই ডিভাইসে');
      return;
    }
    final started = await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() => _controller.text = result.recognizedWords);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 2),
        localeId: 'bn_BD',
      ),
    );
    if (started && mounted) {
      setState(() => _isListening = true);
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    HapticFeedback.selectionClick();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
    });
    _scrollToBottom();

    try {
      final result = await GeminiService.chat(
        userMessage: text,
        history: _history,
      );

      if (!result.isError) {
        _history.add({'role': 'user', 'text': text});
        _history.add({'role': 'model', 'text': result.text});
        if (_history.length > 20) {
          _history.removeRange(0, 2);
        }
      }

      setState(() {
        _messages.add({'role': 'bot', 'text': result.text});
        _loading = false;
      });
      _speak(result.text);
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'text': 'দুঃখিত, এখন সংযোগ সমস্যা হচ্ছে। একটু পরে চেষ্টা করুন।'
        });
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF1D9E75),
              child: Text('ট্র',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ট্র্যাকি AI',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text('Powered by Gemini',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: Colors.white12),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return _buildTypingIndicator();
                final msg = _messages[i];
                return _buildBubble(msg['role']!, msg['text']!);
              },
            ),
          ),
          if (_messages.length <= 1)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _send(_suggestions[i]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white12, width: 0.5),
                    ),
                    child: Text(_suggestions[i],
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ),
                ),
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'রুট বা ভাড়া জিজ্ঞেস করুন...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              onSubmitted: _send,
            ),
          ),
          const SizedBox(width: 6),
          _buildTtsButton(),
          const SizedBox(width: 6),
          _buildMicButton(),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _loading ? null : () => _send(_controller.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _loading
                    ? const Color(0xFF1D9E75).withValues(alpha: 0.5)
                    : const Color(0xFF1D9E75),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isListening
              ? Colors.redAccent.withValues(alpha: 0.9)
              : const Color(0xFF2A2A2A),
          boxShadow: _isListening
              ? [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: _isListening
            ? const Icon(Icons.mic, color: Colors.white, size: 22)
            : Icon(Icons.mic_none_rounded,
                color: _speechAvailable
                    ? Colors.white70
                    : Colors.grey.shade600,
                size: 22),
      ),
    );
  }

  Widget _buildTtsButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _ttsEnabled = !_ttsEnabled);
        if (!_ttsEnabled) _tts.stop();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _ttsEnabled ? const Color(0xFF1D9E75) : const Color(0xFF2A2A2A),
        ),
        child: Icon(
          _ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          color: _ttsEnabled ? Colors.white : Colors.grey,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBubble(String role, String text) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF1D9E75)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.grey[300],
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => _dot(i)),
        ),
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (_, val, child) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withValues(alpha: 0.3 + val * 0.7),
        ),
      ),
    );
  }
}

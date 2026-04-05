import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const LibrasApp());
}

class LibrasApp extends StatelessWidget {
  const LibrasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voz para Libras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5276),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const TelaInicial(),
    );
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial>
    with TickerProviderStateMixin {

  final SpeechToText _speech = SpeechToText();
  bool _estaOuvindo = false;
  bool _speechDisponivel = false;
  String _textoTranscrito = '';
  String _textoTemporario = '';
  final List<String> _historicoMensagens = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _inicializarSpeech();
    _configurarAnimacao();
  }

  void _configurarAnimacao() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _inicializarSpeech() async {
    var status = await Permission.microphone.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() => _speechDisponivel = false);
      return;
    }

    bool disponivel = await _speech.initialize(
      onError: (erro) {
        setState(() => _estaOuvindo = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _estaOuvindo = false);
          _pulseController.stop();
          _pulseController.reset();
        }
      },
    );

    setState(() {
      _speechDisponivel = disponivel;
    });
  }

  void _alternarGravacao() {
    if (_estaOuvindo) {
      _pararGravacao();
    } else {
      _iniciarGravacao();
    }
  }

  Future<void> _iniciarGravacao() async {
    if (!_speechDisponivel) return;

    setState(() {
      _estaOuvindo = true;
      _textoTemporario = '';
    });

    _pulseController.repeat(reverse: true);

    await _speech.listen(
      onResult: _aoReceberResultado,
      localeId: 'pt_BR',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  void _pararGravacao() {
    _speech.stop();
    _pulseController.stop();
    _pulseController.reset();
    setState(() => _estaOuvindo = false);
  }

  void _aoReceberResultado(SpeechRecognitionResult resultado) {
    setState(() {
      _textoTemporario = resultado.recognizedWords;
      if (resultado.finalResult) {
        _textoTranscrito = resultado.recognizedWords;
      }
    });
  }

  void _confirmarMensagem() {
    String texto = _textoTranscrito.isNotEmpty
        ? _textoTranscrito
        : _textoTemporario;

    if (texto.trim().isEmpty) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _historicoMensagens.insert(0, texto);
      _textoTranscrito = '';
      _textoTemporario = '';
    });
  }

  void _limparTexto() {
    setState(() {
      _textoTranscrito = '';
      _textoTemporario = '';
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String textoVisivel = _textoTemporario.isNotEmpty
        ? _textoTemporario
        : _textoTranscrito;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sign_language, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voz para Libras',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Fase 1 — Transcrição de voz',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _speechDisponivel
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _speechDisponivel ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _speechDisponivel ? Icons.check_circle : Icons.error,
                  size: 12,
                  color: _speechDisponivel ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _speechDisponivel ? 'Pronto' : 'Sem suporte',
                  style: TextStyle(
                    fontSize: 11,
                    color: _speechDisponivel ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _construirAreaGravacao(textoVisivel),
          _construirDivisoria(),
          Expanded(child: _construirHistorico()),
        ],
      ),
    );
  }

  Widget _construirAreaGravacao(String textoVisivel) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A5276),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _estaOuvindo
                        ? 'Gravando... fale agora!'
                        : 'Toque no microfone e fale',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                if (_estaOuvindo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '● AO VIVO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: textoVisivel.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 36, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        'O texto transcrito\naparece aqui',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.accessibility_new,
                              size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'Para o colaborador surdo:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        textoVisivel,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A252F),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (textoVisivel.isNotEmpty) ...[
                _botaoSecundario(
                  icone: Icons.delete_outline,
                  label: 'Limpar',
                  onTap: _limparTexto,
                  cor: Colors.red.shade300,
                ),
                const SizedBox(width: 16),
              ],
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _estaOuvindo ? _pulseAnimation.value : 1.0,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: _alternarGravacao,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _estaOuvindo ? Colors.red : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: (_estaOuvindo ? Colors.red : Colors.white)
                              .withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _estaOuvindo ? Icons.stop : Icons.mic,
                      size: 32,
                      color: _estaOuvindo
                          ? Colors.white
                          : const Color(0xFF1A5276),
                    ),
                  ),
                ),
              ),
              if (textoVisivel.isNotEmpty) ...[
                const SizedBox(width: 16),
                _botaoSecundario(
                  icone: Icons.check,
                  label: 'Salvar',
                  onTap: _confirmarMensagem,
                  cor: Colors.green.shade300,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _estaOuvindo
                ? 'Toque no botão vermelho para parar'
                : 'Toque no microfone para gravar',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _botaoSecundario({
    required IconData icone,
    required String label,
    required VoidCallback onTap,
    required Color cor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cor.withOpacity(0.2),
              border: Border.all(color: cor, width: 1.5),
            ),
            child: Icon(icone, color: cor, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: cor, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _construirDivisoria() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.history, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  'Histórico de mensagens',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _construirHistorico() {
    if (_historicoMensagens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Nenhuma mensagem salva ainda.\nGrave e toque em "Salvar".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _historicoMensagens.length,
      itemBuilder: (context, indice) {
        return _cartaoMensagem(_historicoMensagens[indice], indice);
      },
    );
  }

  Widget _cartaoMensagem(String texto, int indice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1A5276).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${_historicoMensagens.length - indice}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5276),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A252F),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mensagem salva',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _historicoMensagens.removeAt(indice);
              });
            },
            child: Icon(Icons.close, size: 16, color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }
}

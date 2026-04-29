import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CORES DO SISTEMA
// ─────────────────────────────────────────────────────────────────────────────
const kAzulEscuro = Color(0xFF1A3A6B);
const kAzulMedio = Color(0xFF2563B0);
const kAzulClaro = Color(0xFF3B82F6);
const kAzulPale = Color(0xFFE8F0FE);
const kVermelho = Color(0xFFDC2626);
const kFundo = Color(0xFFF8FAFC);
const kBranco = Colors.white;

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────────────────────
class Usuario {
  String nome;
  String senha;
  String email;
  Usuario({required this.nome, required this.senha, this.email = ''});
}

class MensagemChat {
  final String texto;
  final DateTime hora;
  MensagemChat({required this.texto, required this.hora});
}

class MensagemUrgente {
  final String supervisor;
  final String texto;
  final String tempo;
  MensagemUrgente(
      {required this.supervisor, required this.texto, required this.tempo});
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  runApp(const SidaApp());
}

class SidaApp extends StatelessWidget {
  const SidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIDA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAzulEscuro,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: kFundo,
      ),
      home: const TelaLogin(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TELA DE LOGIN
// ─────────────────────────────────────────────────────────────────────────────
class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin>
    with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _erro = false;
  bool _verSenha = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Lista de usuários do sistema (estado local simples)
  static final List<Usuario> _usuarios = [
    Usuario(nome: 'Admin', senha: '123456'),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _fazerLogin() {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text;
    final found = _usuarios.firstWhere(
      (x) => x.nome.toLowerCase() == u.toLowerCase() && x.senha == p,
      orElse: () => Usuario(nome: '', senha: ''),
    );
    if (found.nome.isNotEmpty) {
      setState(() => _erro = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TelaApp(
            usuarioAtual: found,
            todosUsuarios: _usuarios,
          ),
        ),
      );
    } else {
      setState(() => _erro = true);
      if (!kIsWeb) HapticFeedback.heavyImpact();
    }
  }

  void _abrirResetSenha() {
    showDialog(
      context: context,
      builder: (_) => DialogResetSenha(usuarios: _usuarios),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: kFundo,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isWide ? _layoutDesktop() : _layoutMobile(),
      ),
    );
  }

  // ── Layout desktop: dois painéis lado a lado ──────────────────────────────
  Widget _layoutDesktop() {
    return Row(
      children: [
        // Painel esquerdo azul
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kAzulEscuro, kAzulMedio],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _logoIcone(size: 80),
                const SizedBox(height: 24),
                const Text(
                  'SIDA',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: kBranco,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sistema Integrado de Atendimento',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),
                _ilustracao(),
              ],
            ),
          ),
        ),
        // Painel direito branco — formulário
        Container(
          width: 400,
          color: kBranco,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
          child: _formularioLogin(),
        ),
      ],
    );
  }

  // ── Layout mobile: apenas formulário com header compacto ─────────────────
  Widget _layoutMobile() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 36),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kAzulEscuro, kAzulMedio],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: Column(
              children: [
                _logoIcone(size: 60),
                const SizedBox(height: 16),
                const Text(
                  'SIDA',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: kBranco,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sistema Integrado de Atendimento',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _formularioLogin(),
          ),
        ],
      ),
    );
  }

  Widget _logoIcone({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Colors.white30, width: 1.5),
      ),
      child: Icon(
        Icons.chat_rounded,
        color: kBranco,
        size: size * 0.52,
      ),
    );
  }

  Widget _ilustracao() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 48),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _linhaIlustracao(0.9),
          const SizedBox(height: 10),
          _linhaIlustracao(0.7),
          const SizedBox(height: 10),
          _linhaIlustracao(0.55),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kVermelho.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: kBranco, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linhaIlustracao(double frac) {
    return FractionallySizedBox(
      widthFactor: frac,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  Widget _formularioLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Bem-vindo',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: kAzulEscuro,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Faça login para acessar o sistema',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 32),

        _campoTexto(
          label: 'USUÁRIO',
          controller: _userCtrl,
          hint: 'Digite seu usuário',
          icone: Icons.person_outline,
          onSubmit: (_) => _fazerLogin(),
        ),
        const SizedBox(height: 16),
        _campoTexto(
          label: 'SENHA',
          controller: _passCtrl,
          hint: 'Digite sua senha',
          icone: Icons.lock_outline,
          obscure: !_verSenha,
          sufixo: IconButton(
            icon: Icon(
              _verSenha ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: Colors.grey.shade400,
            ),
            onPressed: () => setState(() => _verSenha = !_verSenha),
          ),
          onSubmit: (_) => _fazerLogin(),
        ),

        if (_erro) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: kVermelho),
              const SizedBox(width: 6),
              Text(
                'Usuário ou senha incorretos.',
                style: TextStyle(color: kVermelho, fontSize: 13),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _fazerLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: kAzulEscuro,
              foregroundColor: kBranco,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Entrar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _abrirResetSenha,
            child: const Text(
              'Esqueci minha senha / Resetar Senha',
              style: TextStyle(color: kAzulMedio, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _campoTexto({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    bool obscure = false,
    Widget? sufixo,
    void Function(String)? onSubmit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          onSubmitted: onSubmit,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icone, size: 18, color: Colors.grey.shade400),
            suffixIcon: sufixo,
            filled: true,
            fillColor: kFundo,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kAzulClaro, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG: RESET DE SENHA
// ─────────────────────────────────────────────────────────────────────────────
class DialogResetSenha extends StatefulWidget {
  final List<Usuario> usuarios;
  const DialogResetSenha({super.key, required this.usuarios});

  @override
  State<DialogResetSenha> createState() => _DialogResetSenhaState();
}

class _DialogResetSenhaState extends State<DialogResetSenha> {
  final _userCtrl = TextEditingController();
  final _novaCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _erro;
  bool _sucesso = false;

  void _confirmar() {
    final u = _userCtrl.text.trim();
    final nova = _novaCtrl.text;
    final conf = _confirmCtrl.text;
    final user = widget.usuarios.firstWhere(
      (x) => x.nome.toLowerCase() == u.toLowerCase(),
      orElse: () => Usuario(nome: '', senha: ''),
    );
    if (user.nome.isEmpty) {
      setState(() => _erro = 'Usuário não encontrado.');
      return;
    }
    if (nova.length < 4) {
      setState(() => _erro = 'Senha muito curta (mínimo 4 caracteres).');
      return;
    }
    if (nova != conf) {
      setState(() => _erro = 'As senhas não coincidem.');
      return;
    }
    user.senha = nova;
    setState(() {
      _erro = null;
      _sucesso = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Resetar Senha',
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: kAzulEscuro),
      ),
      content: _sucesso
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 12),
                Text('Senha alterada com sucesso!',
                    style: TextStyle(color: Colors.green)),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo('Usuário', _userCtrl, Icons.person_outline),
                const SizedBox(height: 12),
                _campo('Nova Senha', _novaCtrl, Icons.lock_outline,
                    obscure: true),
                const SizedBox(height: 12),
                _campo('Confirmar Senha', _confirmCtrl, Icons.lock_reset,
                    obscure: true),
                if (_erro != null) ...[
                  const SizedBox(height: 10),
                  Text(_erro!,
                      style: const TextStyle(color: kVermelho, fontSize: 13)),
                ],
              ],
            ),
      actions: _sucesso
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              )
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                onPressed: _confirmar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAzulEscuro,
                  foregroundColor: kBranco,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Confirmar'),
              ),
            ],
    );
  }

  Widget _campo(String label, TextEditingController ctrl, IconData icone,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icone, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TELA PRINCIPAL DO APP (com sidebar)
// ─────────────────────────────────────────────────────────────────────────────
enum SecaoApp { chat, urgentes }

class TelaApp extends StatefulWidget {
  final Usuario usuarioAtual;
  final List<Usuario> todosUsuarios;

  const TelaApp({
    super.key,
    required this.usuarioAtual,
    required this.todosUsuarios,
  });

  @override
  State<TelaApp> createState() => _TelaAppState();
}

class _TelaAppState extends State<TelaApp> {
  SecaoApp _secaoAtual = SecaoApp.chat;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: kBranco,
      body: isWide ? _layoutDesktop() : _layoutMobile(),
    );
  }

  Widget _layoutDesktop() {
    return Row(
      children: [
        _Sidebar(
          secaoAtual: _secaoAtual,
          onMudarSecao: (s) => setState(() => _secaoAtual = s),
          usuario: widget.usuarioAtual,
          todosUsuarios: widget.todosUsuarios,
          isDesktop: true,
        ),
        Expanded(child: _conteudo()),
      ],
    );
  }

  Widget _layoutMobile() {
    return Column(
      children: [
        Expanded(child: _conteudo()),
        _BottomNav(
          secaoAtual: _secaoAtual,
          onMudarSecao: (s) => setState(() => _secaoAtual = s),
          usuario: widget.usuarioAtual,
          todosUsuarios: widget.todosUsuarios,
        ),
      ],
    );
  }

  Widget _conteudo() {
    return switch (_secaoAtual) {
      SecaoApp.chat => TelaChat(usuario: widget.usuarioAtual),
      SecaoApp.urgentes => const TelaUrgentes(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR (desktop)
// ─────────────────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final SecaoApp secaoAtual;
  final void Function(SecaoApp) onMudarSecao;
  final Usuario usuario;
  final List<Usuario> todosUsuarios;
  final bool isDesktop;

  const _Sidebar({
    required this.secaoAtual,
    required this.onMudarSecao,
    required this.usuario,
    required this.todosUsuarios,
    this.isDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: kAzulEscuro,
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Label SIDA
          const Text(
            'SIDA',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Colors.white10, thickness: 1),
          const SizedBox(height: 8),

          // Ícone do usuário logado com menu
          _MenuUsuario(
            usuario: usuario,
            todosUsuarios: todosUsuarios,
          ),

          const SizedBox(height: 8),

          // Chat
          _SidebarItem(
            icone: Icons.chat_bubble_outline_rounded,
            iconeAtivo: Icons.chat_bubble_rounded,
            label: 'Chat',
            ativo: secaoAtual == SecaoApp.chat,
            onTap: () => onMudarSecao(SecaoApp.chat),
          ),

          // Urgentes
          _SidebarItem(
            icone: Icons.warning_amber_outlined,
            iconeAtivo: Icons.warning_amber_rounded,
            label: 'Urgentes',
            ativo: secaoAtual == SecaoApp.urgentes,
            onTap: () => onMudarSecao(SecaoApp.urgentes),
          ),

          const Spacer(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MENU DO USUÁRIO na sidebar
// ─────────────────────────────────────────────────────────────────────────────
class _MenuUsuario extends StatelessWidget {
  final Usuario usuario;
  final List<Usuario> todosUsuarios;

  const _MenuUsuario({required this.usuario, required this.todosUsuarios});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: usuario.nome,
      child: PopupMenuButton<String>(
        offset: const Offset(72, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: kAzulEscuro,
        onSelected: (value) {
          switch (value) {
            case 'editar':
              showDialog(
                context: context,
                builder: (_) => DialogEditarConfig(usuario: usuario),
              );
              break;
            case 'senha':
              showDialog(
                context: context,
                builder: (_) => DialogAlterarSenha(usuario: usuario),
              );
              break;
            case 'sair':
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const TelaLogin()),
                (_) => false,
              );
              break;
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'editar',
            child: _itemMenu(Icons.tune, 'Editar Configurações'),
          ),
          PopupMenuItem(
            value: 'senha',
            child: _itemMenu(Icons.lock_reset, 'Alterar Senha'),
          ),
          const PopupMenuDivider(height: 1),
          PopupMenuItem(
            value: 'sair',
            child: _itemMenu(Icons.logout, 'Deslogar', cor: Colors.red.shade300),
          ),
        ],
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, color: kBranco, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemMenu(IconData icone, String label, {Color? cor}) {
    final c = cor ?? Colors.white70;
    return Row(
      children: [
        Icon(icone, size: 16, color: c),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: c, fontSize: 13)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEM DA SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final IconData icone;
  final IconData iconeAtivo;
  final String label;
  final bool ativo;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icone,
    required this.iconeAtivo,
    required this.label,
    required this.ativo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 46,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: ativo
                ? Colors.white.withOpacity(0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            ativo ? iconeAtivo : icone,
            color: ativo ? kBranco : Colors.white54,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV (mobile)
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final SecaoApp secaoAtual;
  final void Function(SecaoApp) onMudarSecao;
  final Usuario usuario;
  final List<Usuario> todosUsuarios;

  const _BottomNav({
    required this.secaoAtual,
    required this.onMudarSecao,
    required this.usuario,
    required this.todosUsuarios,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: kAzulEscuro,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Usuário
          PopupMenuButton<String>(
            offset: const Offset(0, -160),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            color: kAzulEscuro,
            onSelected: (value) {
              switch (value) {
                case 'editar':
                  showDialog(
                    context: context,
                    builder: (_) => DialogEditarConfig(usuario: usuario),
                  );
                  break;
                case 'senha':
                  showDialog(
                    context: context,
                    builder: (_) => DialogAlterarSenha(usuario: usuario),
                  );
                  break;
                case 'sair':
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const TelaLogin()),
                    (_) => false,
                  );
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'editar',
                child: Row(children: [
                  const Icon(Icons.tune, size: 16, color: Colors.white70),
                  const SizedBox(width: 10),
                  const Text('Editar Configurações',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                value: 'senha',
                child: Row(children: [
                  const Icon(Icons.lock_reset,
                      size: 16, color: Colors.white70),
                  const SizedBox(width: 10),
                  const Text('Alterar Senha',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'sair',
                child: Row(children: [
                  Icon(Icons.logout, size: 16, color: Colors.red.shade300),
                  const SizedBox(width: 10),
                  Text('Deslogar',
                      style: TextStyle(
                          color: Colors.red.shade300, fontSize: 13)),
                ]),
              ),
            ],
            child: const Icon(Icons.person, color: Colors.white70, size: 26),
          ),
          // Chat
          GestureDetector(
            onTap: () => onMudarSecao(SecaoApp.chat),
            child: Icon(
              Icons.chat_bubble_rounded,
              color: secaoAtual == SecaoApp.chat
                  ? kBranco
                  : Colors.white38,
              size: 26,
            ),
          ),
          // Urgentes
          GestureDetector(
            onTap: () => onMudarSecao(SecaoApp.urgentes),
            child: Icon(
              Icons.warning_amber_rounded,
              color: secaoAtual == SecaoApp.urgentes
                  ? kBranco
                  : Colors.white38,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG: EDITAR CONFIGURAÇÕES
// ─────────────────────────────────────────────────────────────────────────────
class DialogEditarConfig extends StatefulWidget {
  final Usuario usuario;
  const DialogEditarConfig({super.key, required this.usuario});

  @override
  State<DialogEditarConfig> createState() => _DialogEditarConfigState();
}

class _DialogEditarConfigState extends State<DialogEditarConfig> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.usuario.nome);
    _emailCtrl = TextEditingController(text: widget.usuario.email);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Editar Configurações',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kAzulEscuro)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nomeCtrl,
            decoration: InputDecoration(
              labelText: 'Nome de Exibição',
              prefixIcon: const Icon(Icons.person_outline, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: InputDecoration(
              labelText: 'E-mail',
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:
              Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nomeCtrl.text.trim().isNotEmpty) {
              widget.usuario.nome = _nomeCtrl.text.trim();
              widget.usuario.email = _emailCtrl.text.trim();
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kAzulEscuro,
            foregroundColor: kBranco,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG: ALTERAR SENHA
// ─────────────────────────────────────────────────────────────────────────────
class DialogAlterarSenha extends StatefulWidget {
  final Usuario usuario;
  const DialogAlterarSenha({super.key, required this.usuario});

  @override
  State<DialogAlterarSenha> createState() => _DialogAlterarSenhaState();
}

class _DialogAlterarSenhaState extends State<DialogAlterarSenha> {
  final _atualCtrl = TextEditingController();
  final _novaCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _erro;
  bool _sucesso = false;

  void _salvar() {
    if (_atualCtrl.text != widget.usuario.senha) {
      setState(() => _erro = 'Senha atual incorreta.');
      return;
    }
    if (_novaCtrl.text.length < 4) {
      setState(() => _erro = 'Nova senha muito curta (mín. 4 caracteres).');
      return;
    }
    if (_novaCtrl.text != _confirmCtrl.text) {
      setState(() => _erro = 'As novas senhas não coincidem.');
      return;
    }
    widget.usuario.senha = _novaCtrl.text;
    setState(() {
      _erro = null;
      _sucesso = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Alterar Senha',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kAzulEscuro)),
      content: _sucesso
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 12),
                Text('Senha alterada com sucesso!',
                    style: TextStyle(color: Colors.green)),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo('Senha Atual', _atualCtrl, Icons.lock_outline,
                    obscure: true),
                const SizedBox(height: 12),
                _campo('Nova Senha', _novaCtrl, Icons.lock_open,
                    obscure: true),
                const SizedBox(height: 12),
                _campo('Confirmar Nova Senha', _confirmCtrl,
                    Icons.lock_reset,
                    obscure: true),
                if (_erro != null) ...[
                  const SizedBox(height: 10),
                  Text(_erro!,
                      style: const TextStyle(color: kVermelho, fontSize: 13)),
                ],
              ],
            ),
      actions: _sucesso
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              )
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAzulEscuro,
                  foregroundColor: kBranco,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Salvar'),
              ),
            ],
    );
  }

  Widget _campo(String label, TextEditingController ctrl, IconData icone,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icone, size: 18),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TELA DE CHAT — Transcrição de Voz
// ─────────────────────────────────────────────────────────────────────────────
class TelaChat extends StatefulWidget {
  final Usuario usuario;
  const TelaChat({super.key, required this.usuario});

  @override
  State<TelaChat> createState() => _TelaChatState();
}

class _TelaChatState extends State<TelaChat> with TickerProviderStateMixin {
  // Speech to Text
  final SpeechToText _speech = SpeechToText();
  bool _estaOuvindo = false;
  bool _speechDisponivel = false;
  String _textoTranscrito = '';
  String _textoTemporario = '';
  final List<MensagemChat> _mensagens = [];
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _textCtrl = TextEditingController();

  // Animação mic
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _inicializarSpeech();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _inicializarSpeech() async {
    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        setState(() => _speechDisponivel = false);
        return;
      }
    }
    final disponivel = await _speech.initialize(
      onError: (e) => setState(() => _estaOuvindo = false),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _estaOuvindo = false);
          _pulseCtrl.stop();
          _pulseCtrl.reset();
        }
      },
    );
    setState(() => _speechDisponivel = disponivel);
  }

  void _alternarGravacao() {
    _estaOuvindo ? _parar() : _iniciar();
  }

  Future<void> _iniciar() async {
    if (!_speechDisponivel) return;
    setState(() {
      _estaOuvindo = true;
      _textoTemporario = '';
    });
    _pulseCtrl.repeat(reverse: true);
    await _speech.listen(
      onResult: _aoReceberResultado,
      localeId: 'pt_BR',
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 8),
      partialResults: true,
    );
  }

  void _parar() {
    _speech.stop();
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    setState(() => _estaOuvindo = false);
  }

  void _aoReceberResultado(SpeechRecognitionResult res) {
    setState(() {
      _textoTemporario = res.recognizedWords;
      if (res.finalResult) {
        _textoTranscrito = res.recognizedWords;
        _textCtrl.text = _textoTranscrito;
      }
    });
  }

  void _enviarMensagem() {
    final texto =
        _textCtrl.text.trim().isNotEmpty ? _textCtrl.text.trim() : null;
    if (texto == null) return;
    if (!kIsWeb) HapticFeedback.mediumImpact();
    setState(() {
      _mensagens.add(MensagemChat(texto: texto, hora: DateTime.now()));
      _textoTranscrito = '';
      _textoTemporario = '';
      _textCtrl.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _limpar() {
    setState(() {
      _textoTranscrito = '';
      _textoTemporario = '';
      _textCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _topbar(),
        _areaMensagens(),
        _zonaEntrada(),
      ],
    );
  }

  // ── Topbar ────────────────────────────────────────────────────────────────
  Widget _topbar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: kBranco,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Text(
            'Chat — Tradução de Linguagem',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kAzulEscuro,
            ),
          ),
          const SizedBox(width: 10),
          _badge('Ativo', kAzulPale, kAzulMedio),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 1)
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.usuario.nome,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _badge(String texto, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto,
          style: TextStyle(
              fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }

  // ── Área de mensagens ─────────────────────────────────────────────────────
  Widget _areaMensagens() {
    return Expanded(
      child: _mensagens.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 52, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhuma mensagem ainda.\nFale no microfone ou digite abaixo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollCtrl,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _mensagens.length,
              itemBuilder: (_, i) => _cartaoMensagem(_mensagens[i]),
            ),
    );
  }

  Widget _cartaoMensagem(MensagemChat msg) {
    final hora =
        '${msg.hora.hour.toString().padLeft(2, '0')}:${msg.hora.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kFundo,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.usuario.nome} · $hora',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 6),
          Text(
            msg.texto,
            style: const TextStyle(
                fontSize: 15, color: kAzulEscuro, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Zona de entrada ───────────────────────────────────────────────────────
  Widget _zonaEntrada() {
    return Container(
      decoration: BoxDecoration(
        color: kBranco,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Campo de texto
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48, maxHeight: 120),
                  decoration: BoxDecoration(
                    color: kFundo,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _estaOuvindo
                          ? kAzulClaro.withOpacity(0.5)
                          : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _textCtrl,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: _estaOuvindo
                          ? 'Ouvindo...'
                          : 'Texto transcrito aparece aqui...',
                      hintStyle: TextStyle(
                          color: _estaOuvindo
                              ? kAzulClaro
                              : Colors.grey.shade400,
                          fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 14, color: kAzulEscuro),
                    onSubmitted: (_) => _enviarMensagem(),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Botão Mic
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _estaOuvindo ? _pulseAnim.value : 1.0,
                  child: child,
                ),
                child: GestureDetector(
                  onTap: _alternarGravacao,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _estaOuvindo ? kVermelho : kVermelho,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kVermelho.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _estaOuvindo ? Icons.stop : Icons.mic,
                      color: kBranco,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botão Enviar
              GestureDetector(
                onTap: _enviarMensagem,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: kAzulEscuro,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Enviar',
                      style: TextStyle(
                        color: kBranco,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _estaOuvindo
                    ? 'Ouvindo... toque para parar'
                    : 'Toque no microfone para transcrição por voz',
                style: TextStyle(
                    fontSize: 12,
                    color:
                        _estaOuvindo ? kVermelho : Colors.grey.shade400),
              ),
              if (_textCtrl.text.isNotEmpty)
                GestureDetector(
                  onTap: _limpar,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Limpar',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TELA DE URGENTES
// ─────────────────────────────────────────────────────────────────────────────
class TelaUrgentes extends StatelessWidget {
  const TelaUrgentes({super.key});

  static final List<MensagemUrgente> _msgs = [
    MensagemUrgente(
      supervisor: 'Supervisor · Carlos Mendes',
      texto:
          'Atenção: O sistema de backup será reiniciado às 18h. Por favor salve todos os atendimentos em andamento antes deste horário.',
      tempo: 'Hoje, 14:32',
    ),
    MensagemUrgente(
      supervisor: 'Supervisor · Ana Rodrigues',
      texto:
          'Novo protocolo de atendimento prioritário para usuários com deficiência auditiva entrará em vigor a partir de segunda-feira. Aguardem o manual na intranet.',
      tempo: 'Hoje, 11:05',
    ),
    MensagemUrgente(
      supervisor: 'Administração · TI',
      texto:
          'Manutenção programada neste sábado das 02h às 06h. O sistema ficará indisponível neste período.',
      tempo: 'Ontem, 17:20',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Topbar
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: kBranco,
            border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1.5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                'Urgentes — Informativos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kAzulEscuro,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: kVermelho.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Somente Leitura',
                  style: TextStyle(
                    fontSize: 11,
                    color: kVermelho,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lista
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _msgs.length,
            itemBuilder: (_, i) => _cartaoUrgente(_msgs[i]),
          ),
        ),

        // Rodapé
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: kVermelho.withOpacity(0.05),
          child: const Center(
            child: Text(
              'Área somente leitura — mensagens enviadas pela supervisão',
              style: TextStyle(fontSize: 12, color: kVermelho),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cartaoUrgente(MensagemUrgente msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kFundo,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        border: Border(
          left: const BorderSide(color: kVermelho, width: 4),
          top: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            msg.supervisor,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kVermelho,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            msg.texto,
            style: const TextStyle(
                fontSize: 14, color: kAzulEscuro, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            msg.tempo,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

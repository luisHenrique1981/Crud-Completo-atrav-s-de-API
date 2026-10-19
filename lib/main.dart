import 'package:flutter/material.dart';
import 'models/produto.dart';
import 'services/produto_service.dart';

void main() => runApp(const SupermercadoApp());

class SupermercadoApp extends StatelessWidget {
  const SupermercadoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Supermercado CRUD',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF168451)),
          useMaterial3: true,
        ),
        home: const TelaProdutos(),
      );
}

class TelaProdutos extends StatefulWidget {
  const TelaProdutos({super.key});

  @override
  State<TelaProdutos> createState() => _TelaProdutosState();
}

class _TelaProdutosState extends State<TelaProdutos> {
  final ProdutoService _api = ProdutoService();
  final List<Produto> _produtos = [];
  final Set<int> _locais = {};
  final Set<int> _alterados = {};
  final Set<int> _excluidos = {};
  int _proximoId = 1000; // IDs locais para não colidir com posts 1-100.
  bool _carregando = false;
  bool _ocupado = false;
  String _filtro = '';
  String? _erro;

  @override
  void initState() {
    super.initState();
    _listar();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  void _aviso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _listar() async {
    if (_ocupado) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resposta = await _api.listar();
      if (!mounted) return;
      // Mescla a lista remota com as alterações da sessão.
      final cache = {for (final p in _produtos) p.id: p};
      final combinado = <Produto>[
        for (final p in resposta)
          if (!_excluidos.contains(p.id))
            if (_alterados.contains(p.id) && cache.containsKey(p.id))
              cache[p.id]!
            else
              p,
        for (final p in _produtos)
          if (_locais.contains(p.id)) p,
      ];
      setState(() {
        _produtos..clear()..addAll(combinado);
      });
    } catch (e) {
      if (mounted) setState(() => _erro = 'Falha ao carregar produtos: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _executar(Future<void> Function() tarefa) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await tarefa();
    } catch (e) {
      _aviso('Não foi possível concluir: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  // Mostra o registro retornado pelo GET, sem sobrescrever alterações locais.
  Future<void> _consultar(Produto produto) async {
    await _executar(() async {
      final bool local = _locais.contains(produto.id);
      final Produto registro = local ? produto : await _api.consultar(produto.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(local ? 'Produto local' : 'GET — Produto da API'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${registro.id}'),
                const SizedBox(height: 8),
                Text('Nome: ${registro.nome}'),
                const SizedBox(height: 8),
                Text('Descrição: ${registro.descricao}'),
                if (_alterados.contains(produto.id)) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Observação: a API de testes retorna o registro original. '
                    'As mudanças feitas neste app continuam na lista local.',
                  ),
                ],
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
        ),
      );
    });
  }

  Future<Map<String, String>?> _formulario({Produto? produto, bool apenasNome = false}) async {
    final chave = GlobalKey<FormState>();
    final nome = TextEditingController(text: produto?.nome ?? '');
    final descricao = TextEditingController(text: produto?.descricao ?? '');
    try {
      return await showDialog<Map<String, String>>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(produto == null
              ? 'Cadastrar produto (POST)'
              : apenasNome
                  ? 'Alterar nome (PATCH)'
                  : 'Editar produto (PUT)'),
          content: Form(
            key: chave,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nome,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome do produto', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                ),
                if (!apenasNome) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descricao,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Informe a descrição' : null,
                  ),
                ],
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (chave.currentState!.validate()) {
                  Navigator.pop(ctx, {'nome': nome.text.trim(), 'descricao': descricao.text.trim()});
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      );
    } finally {
      // Aguarda desmontagem do diálogo antes de liberar os controladores.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nome.dispose();
        descricao.dispose();
      });
    }
  }

  Future<void> _criar() async {
    final dados = await _formulario();
    if (dados == null) return;
    await _executar(() async {
      final criado = await _api.criar(Produto(
        id: 0, nome: dados['nome']!, descricao: dados['descricao']!,
      ));
      if (!mounted) return;
      // A API sempre simula o mesmo ID 101 para POST: usamos ID único local.
      setState(() {
        final id = ++_proximoId;
        _locais.add(id);
        _produtos.insert(0, criado.copyWith(id: id));
      });
      _aviso('Produto cadastrado! POST 201 (registro mantido nesta sessão).');
    });
  }

  Future<void> _atualizar(Produto produto) async {
    final dados = await _formulario(produto: produto);
    if (dados == null) return;
    await _executar(() async {
      final novo = produto.copyWith(nome: dados['nome'], descricao: dados['descricao']);
      if (!_locais.contains(produto.id)) await _api.atualizar(novo);
      if (!mounted) return;
      setState(() {
        final i = _produtos.indexWhere((p) => p.id == produto.id);
        if (i >= 0) _produtos[i] = novo;
        _alterados.add(produto.id);
      });
      _aviso(_locais.contains(produto.id)
          ? 'Produto local atualizado (sem PUT remoto).'
          : 'Produto atualizado! PUT 200.');
    });
  }

  Future<void> _patch(Produto produto) async {
    final dados = await _formulario(produto: produto, apenasNome: true);
    if (dados == null) return;
    await _executar(() async {
      if (!_locais.contains(produto.id)) await _api.alterarNome(produto.id, dados['nome']!);
      if (!mounted) return;
      setState(() {
        final i = _produtos.indexWhere((p) => p.id == produto.id);
        if (i >= 0) _produtos[i] = produto.copyWith(nome: dados['nome']);
        _alterados.add(produto.id);
      });
      _aviso(_locais.contains(produto.id)
          ? 'Nome local alterado (sem PATCH remoto).'
          : 'Nome alterado! PATCH 200.');
    });
  }

  Future<void> _excluir(Produto produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: Text('Deseja excluir "${produto.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmar != true) return;
    await _executar(() async {
      if (!_locais.contains(produto.id)) await _api.excluir(produto.id);
      if (!mounted) return;
      setState(() {
        _produtos.removeWhere((p) => p.id == produto.id);
        if (!_locais.remove(produto.id)) _excluidos.add(produto.id);
        _alterados.remove(produto.id);
      });
      _aviso('Produto excluído da lista${_excluidos.contains(produto.id) ? ' (DELETE 200)' : ' localmente'}.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final visiveis = _produtos.where((p) =>
        p.nome.toLowerCase().contains(_filtro.toLowerCase()) ||
        p.descricao.toLowerCase().contains(_filtro.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 Supermercado CRUD'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(tooltip: 'LIST — Atualizar lista',
            onPressed: (_carregando || _ocupado) ? null : _listar,
            icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Gerencie seus produtos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('API JSONPlaceholder • Alterações simuladas e mantidas nesta sessão.'),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Pesquisar produtos', border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _filtro = v),
            ),
          ]),
        ),
        if (_carregando || _ocupado) const LinearProgressIndicator(),
        if (_erro != null)
          Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            TextButton(onPressed: _listar, child: const Text('Tentar novamente')),
          ])),
        Expanded(child: visiveis.isEmpty && !_carregando
            ? const Center(child: Text('Nenhum produto encontrado.'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                itemCount: visiveis.length,
                itemBuilder: (ctx, index) {
                  final p = visiveis[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${p.id}')),
                      title: Text(p.nome, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(p.descricao, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: _ocupado ? null : () => _consultar(p),
                      trailing: PopupMenuButton<String>(
                        enabled: !_ocupado,
                        tooltip: 'Ações do produto',
                        onSelected: (acao) {
                          switch (acao) {
                            case 'get': _consultar(p); break;
                            case 'put': _atualizar(p); break;
                            case 'patch': _patch(p); break;
                            case 'delete': _excluir(p); break;
                          }
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 'get', child: Text('GET • Consultar')),
                          PopupMenuItem(value: 'put', child: Text('PUT • Editar tudo')),
                          PopupMenuItem(value: 'patch', child: Text('PATCH • Alterar nome')),
                          PopupMenuItem(value: 'delete', child: Text('DELETE • Excluir')),
                        ],
                      ),
                    ),
                  );
                },
              )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ocupado ? null : _criar,
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
      ),
    );
  }
}

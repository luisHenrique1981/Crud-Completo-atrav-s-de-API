import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/produto.dart';

class ProdutoService {
  static const String _base = 'https://jsonplaceholder.typicode.com/posts';
  final http.Client _client;

  ProdutoService([http.Client? client]) : _client = client ?? http.Client();

  void dispose() => _client.close();

  void _verificar(http.Response response, Set<int> esperados) {
    if (!esperados.contains(response.statusCode)) {
      throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // LIST: GET /posts
  Future<List<Produto>> listar() async {
    final resposta = await _client.get(Uri.parse(_base));
    _verificar(resposta, {200});
    final lista = jsonDecode(utf8.decode(resposta.bodyBytes)) as List<dynamic>;
    return lista.map((e) => Produto.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET: GET /posts/{id}
  Future<Produto> consultar(int id) async {
    final resposta = await _client.get(Uri.parse('$_base/$id'));
    _verificar(resposta, {200});
    return Produto.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
  }

  // CREATE: POST /posts
  Future<Produto> criar(Produto produto) async {
    final resposta = await _client.post(
      Uri.parse(_base),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(produto.toCreateJson()),
    );
    _verificar(resposta, {201});
    return Produto.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
  }

  // UPDATE: PUT /posts/{id} (substitui os campos do registro)
  Future<Produto> atualizar(Produto produto) async {
    final resposta = await _client.put(
      Uri.parse('$_base/${produto.id}'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(produto.toJson()),
    );
    _verificar(resposta, {200});
    return Produto.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
  }

  // PATCH: PATCH /posts/{id} (altera somente o título)
  Future<Produto> alterarNome(int id, String nome) async {
    final resposta = await _client.patch(
      Uri.parse('$_base/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'title': nome}),
    );
    _verificar(resposta, {200});
    return Produto.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
  }

  // DELETE: DELETE /posts/{id}
  Future<void> excluir(int id) async {
    final resposta = await _client.delete(Uri.parse('$_base/$id'));
    _verificar(resposta, {200, 204});
  }
}

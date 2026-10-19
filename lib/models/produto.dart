class Produto {
  final int id;
  final int userId;
  final String nome;
  final String descricao;

  const Produto({
    required this.id,
    this.userId = 1,
    required this.nome,
    required this.descricao,
  });

  factory Produto.fromJson(Map<String, dynamic> json) => Produto(
        id: (json['id'] as num).toInt(),
        userId: ((json['userId'] ?? 1) as num).toInt(),
        nome: (json['title'] ?? '').toString(),
        descricao: (json['body'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': nome,
        'body': descricao,
      };

  Map<String, dynamic> toCreateJson() => {
        'userId': userId,
        'title': nome,
        'body': descricao,
      };

  Produto copyWith({int? id, String? nome, String? descricao}) => Produto(
        id: id ?? this.id,
        userId: userId,
        nome: nome ?? this.nome,
        descricao: descricao ?? this.descricao,
      );
}

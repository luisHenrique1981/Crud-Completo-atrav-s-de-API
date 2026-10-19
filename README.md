# CRUD Flutter — Supermercado / JSONPlaceholder

Projeto didático com LIST (`GET /posts`), GET (`GET /posts/{id}`), CREATE (`POST /posts`), UPDATE (`PUT /posts/{id}`), PATCH (`PATCH /posts/{id}`) e DELETE (`DELETE /posts/{id}`).

## Executar

1. Tenha Flutter instalado (Dart >= 3.4).
2. Crie um projeto para gerar as pastas das plataformas: `flutter create supermercado_crud`.
3. Copie `lib/` e `pubspec.yaml` deste pacote para a pasta `supermercado_crud/`. O nome do pacote é `flutter_supermercado_crud`, mas os imports são relativos, portanto não há conflito.
4. `flutter pub get`
5. `flutter run` (escolha Android, Chrome ou desktop).

Alternativa: extraia este pacote e execute `flutter create .` dentro da pasta extraída, depois `flutter pub get` e `flutter run`.

Android: confira se `android/app/src/main/AndroidManifest.xml` contém `<uses-permission android:name="android.permission.INTERNET"/>` antes da tag `<application>`.

## Adaptação de dados

A API **não possui produtos**. Foram usados os posts: `title` = nome, `body` = descrição, `userId` = 1, `id` = identificador.

A lista inicial mostra posts fictícios, não itens reais do supermercado. Para ver nomes de alimentos, cadastre produtos pelo botão +.

## Persistência simulada

JSONPlaceholder simula POST/PUT/PATCH/DELETE sem gravar alterações. Este aplicativo mantém inclusões, atualizações e exclusões na memória até ser fechado. Ao atualizar a lista pelo botão de recarga, mescla a resposta remota com as alterações da sessão. Ao reiniciar o app, as alterações desaparecem. O GET de um post da API mostra a versão original do servidor, não as alterações locais.

Para evitar ID duplicado (a API geralmente responde 101 a cada POST), produtos recém-criados recebem IDs locais a partir de 1001. PUT/PATCH/DELETE para novos produtos são feitos somente na memória, pois tais IDs não existem no servidor. As seis operações HTTP são realmente executadas nos registros originais da API.

## Arquivos

- `lib/models/produto.dart`: conversão entre produtos e posts da API.
- `lib/services/produto_service.dart`: chamadas HTTP e verificação de status.
- `lib/main.dart`: interface, formulário, listagem, consulta, atualização parcial e integral, exclusão e estados da sessão.

Fonte: https://jsonplaceholder.typicode.com/

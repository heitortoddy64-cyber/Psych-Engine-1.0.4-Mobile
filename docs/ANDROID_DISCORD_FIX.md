# Correção de Discord RPC no Android — V1

## Causa e correção

`Project.xml` habilitava `DISCORD_ALLOWED` em todas as plataformas, exceto
iOS. Isso incluía Android e fazia o Lime procurar `hxdiscord_rpc` antes de
compilar o Haxe. O setup mobile tentava instalar um fork de Discord por SSH.

- `DISCORD_ALLOWED` agora é definido apenas em `desktop`.
- A declaração de `hxdiscord_rpc` também exige `desktop` e `DISCORD_ALLOWED`.
- O setup mobile não instala nem acessa Discord RPC.
- Os setups desktop usam o upstream público por HTTPS, fixado no commit
  `bff4d27dcf1e02a06b84871cce9fe7d624ff517f`, cujo `haxelib.json` declara
  a versão 1.2.4. O suporte desktop continua habilitado.
- Os scripts Unix resolvem a raiz a partir do próprio arquivo e interrompem
  a instalação quando um comando falha. A criação do diretório de bibliotecas
  aceita um diretório já existente.

Todos os imports e usos de Discord no Haxe já estavam protegidos pelo
define. Não foi necessário modificar arquivos de `source/`. As otimizações
de FPS e processamento de notas da V1 permanecem idênticas, assim como Lua,
HScript, shaders, mods, controles mobile e os cálculos de sincronização.

## Workflows

`mainBuild.yml` mantém o build `haxelib run lime build android -release` e
passa a executar os testes de plataforma e da V1. Antes de compilar, verifica
que o HXML real do Android não contém `DISCORD_ALLOWED` nem `hxdiscord_rpc`.
Android/iOS deixam de depender da etapa de autenticação por SSH destinada
ao antigo fork de Discord.

O workflow adicional `android.yml` usava um template Gradle que chamava
`./gradlew`, inexistente na raiz desta engine. Ele agora configura Haxe,
Java 17 e Lime, instala as dependências mobile, executa os mesmos testes e
gera o APK release. Os gatilhos de push/PR para `main` foram preservados.

## Verificações locais

Com Haxe 4.3.7, Neko 2.4.1 e Lime 8.1.2 disponíveis:

```sh
python3 tests/discord_platforms.py
python3 tests/optimization_v1.py
sh -n setup/mobile.sh
sh -n setup/unix.sh
git diff --check
```

Os seis casos de plataforma passaram. O teste usa o parser real do Lime
com as duas declarações extraídas do `Project.xml`, sem as demais
dependências da engine. Android/iOS/HTML5 excluem Discord, e o compilador
Haxe carrega e verifica o módulo real `backend.Discord` com seu conteúdo
desabilitado. Linux/Windows/macOS continuam solicitando a biblioteca.
Isso verifica as condições de plataforma e o módulo protegido; não é uma
compilação completa da engine nem um teste de RPC desktop em execução.

As quatro configurações da V1 passaram com 87 asserções cada (348 no total).
O controle negativo com o `Project.xml` anterior reproduziu a exigência de
`hxdiscord_rpc` no Android. Testes dos scripts com um executável de haxelib
controlado confirmaram o diretório de execução, a ausência de Discord no
mobile, o endereço/commit desktop e a interrupção em falha de instalação.

## Limite da compilação local

Neko e Lime foram preparados em uma pasta de ferramentas local. O cliente
haxelib não conseguiu acessar diretamente `lib.haxe.org:443` neste
ambiente; o arquivo oficial de Lime foi obtido via HTTPS com curl.

Foi executado `haxelib run lime build android -release`. O build parou ao
resolver `grig.audio`, uma dependência obrigatória não instalada neste
ambiente. SDK/NDK Android também não estão configurados localmente. Isso
não justifica remover a biblioteca nem desabilitar recursos da engine.
O build completo e a geração do APK devem ser confirmados no job Android
do GitHub Actions; não se deve interpretar os testes isolados como esse
resultado.

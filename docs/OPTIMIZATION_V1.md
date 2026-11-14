# Psych Engine 1.0.4 Mobile — Optimization v1

## Base e aplicação

- Repositório: `heitortoddy64-cyber/Psych-Engine-1.0.4-Mobile`.
- Base: `main`, commit `01335eb4bab96d5ab0a8fb1eb89dd35d57ca2352`.
- Branch de trabalho: `optimization-v1`.
- Versão da engine: `1.0.4` em `source/states/MainMenuState.hx`.
  O `Project.xml` usa o nome `PsychMobile1.0.4` e a versão de pacote
  preexistente `1.0.0`; esses identificadores foram preservados.
- Estrutura: `source/backend`, `source/options`, `source/states`,
  `source/psychlua`, `source/mobile`, `assets`, `example_mods` e `templates`.
- Haxe do workflow: 4.3.7; Flixel 5.5.0; flixel-addons 3.2.1;
  OpenFL 9.3.3. O setup mobile utiliza um fork de Lime.

O ZIP fornecido contém `Psych_Engine_1.0.4_Mobile_Optimization_v1.patch`
e um arquivo de instruções. Foram executados, nesta ordem:

```sh
git switch -c optimization-v1
git apply --check /caminho/Psych_Engine_1.0.4_Mobile_Optimization_v1.patch
git apply /caminho/Psych_Engine_1.0.4_Mobile_Optimization_v1.patch
git diff --check
git apply --reverse --check /caminho/Psych_Engine_1.0.4_Mobile_Optimization_v1.patch
```

Todos passaram. Não houve conflitos nem ajustes manuais no patch.
Além dos três arquivos de produção, foram adicionados este relatório e
`tests/optimization_v1.py` para repetir as verificações isoladas.

## Alterações e compatibilidade

| Arquivo | Alteração |
| --- | --- |
| `source/backend/ClientPrefs.hx` | Padrão de FPS mobile passa de 90 para 60, tanto na inicialização quanto ao carregar um save sem FPS. Valores já salvos são mantidos. |
| `source/options/GraphicsSettingsSubState.hx` | Restaurar padrões usa 60 FPS no mobile. A faixa selecionável continua 60–90 no mobile e 60–240 no desktop; o padrão desktop continua 90. |
| `source/states/PlayState.hx` | Watches ficam sob `#if debug`; remoção da fila usa `shift()` quando a nota ainda está na cabeça, com `remove()` para alterações por scripts; o loop avança por entradas nulas e notas desativadas que permanecem no mesmo índice. |

Os callbacks `onSpawnNote` de Lua e HScript mantêm nomes, argumentos,
ordem e posição em relação à inserção/remoção da nota. Se um callback já
removeu a nota da fila, `remove()` não apaga outra nota; o código anterior
usava `splice(-1, 1)` nesse caso e podia apagar a última nota pendente.
Quando a invalidação contrai o array de notas, o loop continua no mesmo
índice para processar a nota que ocupou essa posição.

A revisão não encontrou novos problemas de sintaxe nos trechos alterados
nem caminhos sem avanço nos casos de loop cobertos pelos testes. Lua,
HScript, shaders, efeitos, Custom Events, Custom Notes, stages, sprites
animados, mods e controles touchscreen continuam habilitados. Não foram
alterados os cálculos de `Conductor.songPosition`, os tempos de notas, os
offsets, a velocidade de reprodução, os carregadores de assets nem as
opções de qualidade/cache.

Essa preservação foi verificada por revisão do diff e pelos testes
isolados descritos abaixo. A compatibilidade completa de mods e a
sincronização audiovisual ainda precisam de execução da engine em Android.

## Verificações executadas em 2026-11-14

Haxe 4.3.7 foi baixado para uma pasta temporária de ferramentas, sem alterar
as dependências do projeto. Para repetir os testes com Haxe no PATH:

```sh
python3 tests/optimization_v1.py
# Ou: python3 tests/optimization_v1.py --haxe /caminho/para/haxe
```

O teste extrai os trechos modificados dos arquivos reais e os compila e
executa no interpretador Haxe, usando substitutos pequenos para notas,
grupos, saves e callbacks. Não compila nem substitui as bibliotecas reais
da engine.

| Configuração dos defines | Resultado |
| --- | --- |
| Desktop, sem debug | 87 asserções passaram |
| Mobile, sem debug | 87 asserções passaram |
| Desktop, debug | 87 asserções passaram |
| Mobile, debug | 87 asserções passaram |

Cobertura: FPS inicial, FPS ausente/nulo no save, saves com 75/90 FPS,
restauração do padrão e limites da opção; watches por configuração;
fila normal e fila reordenada/esvaziada da nota atual por cada callback;
argumentos e ordem dos callbacks; arrays vazios e com entradas nulas;
nota desativada mantida no array; remoções consecutivas por atraso,
botplay e oponente; contagem de misses; permanência e clipping de sustains.

Controles negativos usaram os três arquivos originais obtidos com
`git show 01335eb4:<arquivo>`, via `--source-root <diretorio>` e
`--case prefs|spawn|nulls|killed`. Eles detectaram, respectivamente, a
ausência da guarda de debug, a remoção indevida da nota futura após um
callback, o loop nulo que excede o timeout de 10 segundos e o loop sobre
uma nota desativada que excede 100 visitas. Isso confirma que os testes
distinguem esses comportamentos do código corrigido.

Também passaram `git diff --check` e a checagem reversa do patch original.

### Compilação Android

Foi tentado o comando usado pelo workflow:

```sh
haxelib run lime build android -release
```

O comando terminou com código 127 antes de iniciar a compilação:

```text
haxelib: error while loading shared libraries: libneko.so.2:
cannot open shared object file: No such file or directory
```

O ambiente não dispõe do SDK/NDK Android nem da toolchain de bibliotecas
Haxe configurada. Não foi gerado APK, não houve build completo da engine
e não foram executados testes em dispositivo. A compilação Android não
está validada. Ganhos de FPS, consumo de RAM, bateria e tempo de frame
não foram medidos. `shift()` continua movendo elementos do array; a
mudança de remoção não torna a fila uma estrutura de custo constante.

## Validação pendente em Android

1. Preparar Neko, Haxe 4.3.7, as bibliotecas de `setup/mobile.sh`, hxcpp
   e o SDK/NDK/JDK conforme `.github/workflows/mainBuild.yml`.
2. Executar `haxelib run lime build android -release` nesta branch.
   O workflow existente, **Main Build**, também permite execução manual
   escolhendo a branch. Ele não expõe seleção de jobs e executa os jobs
   configurados; não é disparado automaticamente por um PR.
3. Instalar o APK e verificar instalação limpa a 60 FPS, save existente
   a 90 FPS, seleção de 90 FPS e restauração do padrão mobile a 60 FPS.
4. Exercitar mods com Lua/HScript, `onSpawnNote`, Custom Events/Notes,
   shaders personalizados, stages e sprites animados. Verificar sustains,
   misses, botplay, touchscreen, pausa/reinício e sincronização de áudio
   com notas em diferentes velocidades.
5. Comparar a base e esta branch no mesmo aparelho, mod/chart e FPS,
   medindo RAM e tempos de frame. Comparar separadamente os padrões de
   90 e 60 FPS para distinguir o efeito do limite de FPS.

## Publicação

A branch `optimization-v1` reúne as alterações dos três arquivos de
produção, os testes isolados e este relatório. A revisão deve ocorrer
em um Pull Request para `main`, sem merge automático.

A publicação no GitHub não substitui a validação Android pendente:
o build completo, os testes em dispositivo e as medições de desempenho
continuam necessários antes de uma release.

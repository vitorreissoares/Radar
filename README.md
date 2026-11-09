# Radar

Programa para monitorar as postagens de candidatos no Instagram. Cada pesquisa é um **projeto**, numa pasta escolhida por você, com três etapas:

| Etapa | O que faz |
|---|---|
| **1 · Categorização** | Cria o projeto, importa as planilhas de cada candidato (com nome, partido e foto), seleciona as postagens (mais curtidas, visualizadas, comentadas ou aleatórias), baixa a mídia na pasta de cada candidato e classifica com IA (legenda, imagens e vídeos) em Liderança (Autenticidade, Competência, Humanização), Partido e Políticas |
| **2 · Validação** | Confere a classificação da IA e os comentários de cada postagem (valência positiva, neutra ou negativa, margem de erro, coleta pelo Apify), sozinho ou com outros pesquisadores, ou aceita a classificação da IA de uma vez; mostra a acurácia da IA |
| **3 · Relatório** | Gera o relatório com os botões Semana, Mês, Ano e Tudo, incluindo a valência dos comentários e, se houver, pesquisas e desempenho |

## Baixar e instalar

Baixe o instalador do seu sistema na página de **[versões (Releases)](../../releases/latest)**:

| Sistema | Arquivo |
|---|---|
| **Windows** 10 ou 11 | `Radar-…-win-x64.exe` |
| **Mac com chip Apple** (M1, M2, M3, M4…) | `Radar-…-mac-arm64.dmg` |
| **Mac com Intel** | `Radar-…-mac-x64.dmg` |
| **Linux** | `Radar-…-linux-x86_64.AppImage` (qualquer distribuição) ou `….deb` (Ubuntu, Debian) |

O instalador já traz tudo o que o programa precisa, inclusive o R. Não é preciso instalar mais nada.

> **Por que aparece um aviso de segurança?** O programa não tem assinatura digital paga da Microsoft ou da Apple. Por isso, o sistema pede uma confirmação na primeira vez. É só seguir os passos abaixo.

### Windows

1. Dê dois cliques no arquivo `.exe`.
2. Se aparecer **"O Windows protegeu o computador"**, clique em **Mais informações → Executar assim mesmo**.
3. Siga o instalador. No fim, o atalho **Radar** fica na área de trabalho e no Menu Iniciar.

### Mac

1. Abra o arquivo `.dmg` e arraste o **Radar** para a pasta **Aplicativos**.
2. Na primeira vez, abra a pasta Aplicativos, clique no Radar com o **botão direito → Abrir** e confirme em **Abrir**.
3. Se o Mac não deixar abrir:
   - vá em **Ajustes do Sistema → Privacidade e Segurança**;
   - desça até a mensagem sobre o Radar e clique em **Abrir Mesmo Assim**.
4. Se aparecer **"está danificado"**, abra o **Terminal**, cole o comando abaixo e tente de novo:
   ```
   xattr -dr com.apple.quarantine /Applications/Radar.app
   ```

### Linux

- **AppImage:** clique com o botão direito no arquivo → **Propriedades → Permissões → Permitir executar como programa**. Depois, dê dois cliques. No Ubuntu 22.04 ou mais novo, talvez seja preciso instalar antes o pacote `libfuse2`:
  ```
  sudo apt install libfuse2
  ```
- **.deb:** dê dois cliques ou use `sudo apt install ./Radar-…-linux-amd64.deb`.

## Primeiro uso

1. Abra o **Radar**. A primeira abertura pode levar até um minuto.
2. Na aba **1 · Categorização**, informe a **sua chave do OpenRouter** no painel **Chave da IA** (crie uma em [openrouter.ai/keys](https://openrouter.ai/keys)).
3. Cada pessoa usa a **própria chave**. Ela fica guardada só no computador de quem a informou, e o botão **Apagar chave** a remove quando quiser.

O guia completo de uso está no [LEIA-ME](LEIA-ME.md). No programa, ele também está em **Ajuda → Guia de uso**.

## Onde ficam os dados

Rodadas, validações, imagens e vídeos baixados, relatórios e a chave ficam na pasta **Documentos/Radar** de cada usuário. Para abri-la, use o menu **Arquivo → Abrir pasta de dados**.

Instalar uma versão nova ou desinstalar o programa **não apaga** essa pasta.

## Para quem mantém o projeto

### Publicar uma versão nova

1. Faça as mudanças e mude o número em `desktop/package.json` (por exemplo, `"version": "1.1.0"`).
2. Envie para a branch `main`.
3. O GitHub monta o instalador do **Windows**, em cerca de 10 minutos (aba **Actions**), e o publica em **Releases** como `v1.1.0`.
4. Versão final, para todos os sistemas: na aba **Actions**, abra **Programa de computador**, clique em **Run workflow** e escolha `todos`. Os instaladores de Mac e Linux entram na mesma versão.

Enviar de novo sem mudar o número atualiza os instaladores dessa mesma versão. Mudanças só em arquivos `.md` (como este) não disparam a montagem.

### Rodar pelo R, sem instalar

Com o R instalado, abra `app.R` no RStudio e clique em **Run App**. No Windows, também dá para usar `Abrir Radar.bat`. Veja a seção "Preparação" do [LEIA-ME](LEIA-ME.md).

### Como o programa é montado

| Parte | Onde |
|---|---|
| App (R/Shiny) | `app.R`, `R/`, `prompts/`, `templates/`, `apps_script/` |
| Textos e configurações iniciais | `config/`, `padrao/`, `assets/img_cand/` (fotos dos candidatos e foto do rodapé) |
| Janela do programa (Electron) | `desktop/main.js`, `desktop/carregando.html` |
| Pacotes do R que vão no instalador | `desktop/build/pacotes_r.txt` |
| Montagem automática no GitHub | `.github/workflows/programa.yml` |

Fotos colocadas em `assets/img_cand/` no repositório vão junto no instalador e aparecem para todos.

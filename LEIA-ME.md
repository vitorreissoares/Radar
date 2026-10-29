# Radar

Um único app com as três etapas do monitoramento de postagens no Instagram:

| Aba | O que você faz | O que sai |
|---|---|---|
| **1 · Categorização** | Adiciona os `.xlsx` coletados, um por candidato | Postagens mais curtidas de cada candidato no período escolhido, com **legenda, imagens e vídeo** analisados pela IA; imagens e vídeos salvos em `midia/` |
| **2 · Validação** | Confere cada postagem e aponta a classificação final (sozinho ou com outros pesquisadores, pela Planilha Google) | Base validada e **acurácia da IA** |
| **3 · Comentários** | Coleta os comentários das postagens (Apify), a IA classifica a valência e você valida uma amostra | Comentários de cada postagem em `midia/comentarios/SHORTCODE.csv`, classificados como **positivos, neutros ou negativos** |
| **4 · Relatório** | Revisa o texto de cada botão, os candidatos e o "Sobre a pesquisa" | **Um único relatório**, com os botões **Semana, Mês, Ano e Tudo** no topo e as seções de valência dos comentários |

## Instalar o programa (recomendado)

Baixe o instalador do seu sistema (Windows, Mac ou Linux) na página **Releases** do repositório no GitHub e siga o passo a passo do README. O instalador já traz o R e todos os pacotes.

- **Chave da IA:** cada pessoa informa a **própria chave do OpenRouter** no painel **Chave da IA** da aba 1. Ela fica guardada só no computador de quem a informou.
- **Seus dados:** rodadas, validações, mídias, relatórios e a chave ficam em **Documentos/Radar**. Para abrir essa pasta, use o menu **Arquivo → Abrir pasta de dados**. Instalar uma versão nova não apaga nada.
- **Fotos dos candidatos e logo:** ficam em `Documentos/Radar/assets/img_cand/`. Também dá para trocar uma foto pelo app, na aba 4.

## Rodar pelo R, sem instalar (só na primeira vez)

1. Instale os pacotes no R:
   ```r
   install.packages(c("shiny", "bslib", "DT", "httr2", "tidyverse", "readxl", "jsonlite", "av"))
   ```
   O pacote `av` extrai o áudio dos vídeos para a transcrição. Não é preciso instalar o ffmpeg.
2. Informe a **chave do OpenRouter** na aba 1, no painel **Chave da IA** da barra lateral (ele abre sozinho enquanto não houver chave): cole a chave e clique em **Salvar chave**. Ela fica guardada só nesta pasta, em `config/chave_openrouter.txt`.
   - Para **compartilhar a pasta** com outra pessoa, clique antes em **Apagar chave**. A chave é removida da pasta e também do `.Renviron` do computador, se estiver lá.
   - A pessoa que receber a pasta informa a própria chave no mesmo quadro.
3. Coloque as fotos dos candidatos e o logo (`politica-logo.jpg`) em `assets/img_cand/`. O relatório busca as imagens nessa pasta. Também dá para trocar a foto de um candidato pelo app, na aba 4 (painel **Candidatos**).

### Abrir o app

- **Sem o RStudio:** dê dois cliques em **`Abrir Radar.bat`**. Para ter um ícone na área de trabalho, rode uma vez **`Criar atalho na area de trabalho.bat`**. Para fechar o app, feche a janela preta.
- **Pelo RStudio:** abra `app.R` e clique em **Run App**.

### Como a tela é organizada

- A **barra lateral** de cada aba é dividida em painéis que abrem e fecham com um clique (por exemplo: Chave da IA, Arquivos, Período, O que a IA analisa, Modelos). O botão principal da aba fica sempre visível no rodapé da barra.
- A seta no topo da barra lateral esconde a barra inteira, para dar mais espaço.
- Na aba 4, **Análises salvas**, **Candidatos** e **Sobre a pesquisa** ficam recolhidos embaixo do texto. Clique no título para abrir.

## Categorias e subcategorias

Cada postagem pode receber **quantas categorias forem necessárias** (ou nenhuma). A IA e a validação humana escolhem entre todas:

| Categoria | Quando | Subcategorias |
|---|---|---|
| **Liderança** | A postagem enfatiza características da liderança política | **Autenticidade** (genuinidade e coerência: sinceridade, consistência, valores, credibilidade e confiança) · **Competência** (capacidade de exercer as funções e cumprir compromissos: conhecimento, habilidades, experiência, liderança e desempenho) · **Humanização** (o líder como pessoa próxima e identificável: empatia, vida cotidiana, experiências pessoais, acessibilidade e identificação) |
| **Partido** | A postagem enfatiza características do partido ou da sigla partidária | — |
| **Políticas** | A postagem enfatiza características relacionadas a políticas públicas | — |

A Liderança é marcada pelas suas subcategorias: uma postagem é de Liderança quando recebe ao menos uma delas. As definições completas usadas pela IA estão em `prompts/definicoes.txt`.

## 1 · Categorização

1. **Arquivos:** adicione um `.xlsx` por vez. Escolha o arquivo, confira ou escreva o nome do candidato e clique em **Adicionar à lista**. Repita para todos os candidatos.
2. **Período e %:** escolha o início e o fim da coleta (alguns dias, uma semana, um mês, um ano…) e a porcentagem. A regra é **os X% mais curtidos de cada candidato em todo o período escolhido** (não é por semana). A tabela "Seleção por candidato" mostra quantas postagens entram.
3. **O que a IA analisa:** por padrão, as três fontes. Dá para desmarcar alguma.
   - **Legenda:** o texto da postagem.
   - **Imagens:** todas as imagens do carrossel. Nos vídeos, a capa.
   - **Vídeos:** o áudio é extraído e transcrito, e a transcrição é classificada.
4. Clique em **Categorizar postagens**. Para cada postagem, o app:
   - **baixa** as imagens e o vídeo para a pasta `midia/`;
   - **transcreve** o áudio do vídeo;
   - pede à IA que marque, **em cada fonte**, as subcategorias presentes.

**Nomes dos arquivos** (pelo shortcode da postagem):

| Tipo | Onde fica |
|---|---|
| Imagem única | `midia/postagens/SHORTCODE.jpg` |
| Carrossel | `midia/postagens/SHORTCODE_1.jpg`, `SHORTCODE_2.jpg`, … |
| Vídeo | `midia/videos/SHORTCODE.mp4`, com a capa em `midia/postagens/SHORTCODE.jpg` e o áudio em `midia/audios/SHORTCODE.mp3` |

O registro de cada download fica em `midia/log_downloads.csv`.

> **Baixe as postagens logo depois da coleta.** Os links de imagem e vídeo do Instagram expiram em poucos dias.

Se a categorização parar no meio (por falta de internet ou limite da API), basta clicar de novo. O que já foi feito fica em `saidas/cache_classificacoes_multimodal.csv` e não é cobrado outra vez.

**Sugestão da IA:** as subcategorias marcadas por **pelo menos metade das fontes** que a postagem tem. É o que já aparece ligado na validação.

## 2 · Validação

### Validar (no próprio app)

Cada postagem aparece com:

- **à esquerda**, a imagem (com as miniaturas do carrossel) ou o vídeo, que toca no próprio app;
- **à direita**, a legenda, a transcrição do vídeo e a **tabela de classificação**.

Na tabela, cada linha é uma subcategoria:

| Coluna | O que mostra |
|---|---|
| Legenda · Imagem · Vídeo | **●** = a IA marcou nesta fonte · — = a postagem não tem esta fonte |
| Final | Interruptor que você liga ou desliga. Já vem ligado com a sugestão da IA. |

Botões que ajudam:

| Botão | O que faz |
|---|---|
| **Sugestão da IA** | Volta para o que a IA sugeriu |
| **Nenhuma se aplica** | Desliga todos os interruptores |
| **Formato** | Marca a postagem como "Produzido por IA", se for o caso |
| **Confirmar e próxima** | Salva e mostra a próxima pendente |
| **Anterior** / **Pular** | Servem para revisar |

Não há limite: ligue todas as subcategorias que a postagem tiver. Ao terminar, aparece o botão **Ir para o relatório**.

### Acurácia da IA

Fica na subaba **Acurácia da IA** e é calculada sobre as postagens já validadas:

| Medida | O que significa |
|---|---|
| **Acurácia** | De tudo o que a IA marcou, **quanto a validação humana manteve** |
| **Cobertura** | Das subcategorias finais, quantas a IA já tinha marcado |
| **Postagens 100% certas** | A IA acertou exatamente o conjunto final |

Os números aparecem para a IA combinada e para cada fonte (legenda, imagem, vídeo), e há uma tabela por subcategoria. O botão **Baixar acurácia (.csv)** salva tudo.

### Validação compartilhada (vários pesquisadores ao mesmo tempo)

Na subaba **Validação compartilhada**, o app guia você em 4 passos:

1. **Preparar a planilha (uma vez só, cerca de 5 minutos).** Crie uma Planilha Google e abra **Extensões → Apps Script**. Cole os dois arquivos que o app oferece para baixar: o `Codigo.gs` e o `Validador.html`, este num arquivo HTML chamado `Validador`. Depois clique em **Implantar → Nova implantação → App da Web**, com "Executar como: Eu" e "Quem pode acessar: Qualquer pessoa". Cole o link `/exec` no app e clique em **Conectar e testar**. O primeiro computador que se conecta fica autorizado na planilha.
   - **Outro computador** (ou outra instalação do programa) vai usar a mesma planilha? No Apps Script, escolha a função `autorizarOutroComputador` no topo do editor e clique em **Executar**. Em até 30 minutos, clique em **Conectar e testar** no outro computador.
   - Se aparecer **"Token inválido"**, é isso: o computador ainda não foi autorizado. Faça o passo acima.
2. **Enviar a rodada.** O que você já validou no app vai junto.
3. **Convidar.** O botão **Copiar link** copia o link, e **Copiar mensagem de convite** copia um texto pronto para WhatsApp ou e-mail. Cada pessoa digita o nome e valida na mesma tela de interruptores. Duas pessoas nunca recebem a mesma postagem ao mesmo tempo.
4. **Acompanhar e trazer.** **Ver andamento** mostra quantas cada pessoa já validou. **Trazer validações para o app** traz as respostas, que também são trazidas sozinhas ao abrir a rodada.

> **Atualização do Apps Script:** se você já tinha o Apps Script da versão anterior, cole os dois arquivos novos e use **Implantar → Gerenciar implantações → Editar → Nova versão**. Assim o link continua o mesmo.

## 3 · Comentários

Para cada rodada, a aba reúne os comentários das postagens, a classificação da IA e a validação.

### 1. Coletar

Os comentários de cada postagem ficam em `midia/comentarios/SHORTCODE.csv` (uma linha por comentário: id, texto, curtidas, usuário, data e link). Há dois jeitos:

- **Pelo Apify, direto do app:** informe a sua chave do Apify (em [console.apify.com → Settings → Integrations](https://console.apify.com/settings/integrations)) e escolha **quantos comentários por postagem** coletar.
  - O app mostra antes o **máximo de comentários e o custo máximo estimado** (pelo preço por 1.000 comentários informado; confira o valor atual do *Instagram Comments Scraper* no Apify).
  - Esse limite vai junto com a coleta: o Apify não coleta nem cobra além dele.
  - Deixe marcado **Só postagens ainda sem comentários salvos** para não pagar duas vezes.
  - A chave fica só nesta pasta (`config/chave_apify.txt`) e pode ser apagada pelo app.
- **Arquivo baixado do Apify:** rode o *Instagram Comments Scraper* no site do Apify com os links das postagens, baixe o resultado em CSV ou JSON e escolha o arquivo no app. Os comentários são separados por postagem automaticamente.

### 2. Classificar com IA

A IA classifica cada comentário como **positivo, neutro ou negativo** em relação ao candidato e à postagem, considerando **ironia, sarcasmo, memes e figuras de linguagem** (que os dicionários de palavras não captam). As instruções ficam em `prompts/valencia_comentarios.txt` e podem ser ajustadas. O que já foi classificado não é cobrado de novo.

### 3. Validar

Em **Validar**, cada postagem mostra uma **amostra fixa** de comentários (30 por padrão, ajustável) com três botões: **Positivo · Neutro · Negativo**, que já vêm com a sugestão da IA. Corrija o que for preciso e clique em **Confirmar e próxima**. A subaba **Acurácia da IA** mostra a concordância entre a IA e a validação, por valência.

### Índice de valência

Para cada postagem, categoria ou período: **(positivos + 0,5 × neutros) ÷ total de comentários**. Vai de **0** (todos negativos) a **1** (todos positivos). Nas médias, cada comentário pesa igual (média ponderada pelo número de comentários).

## 4 · Relatório

O relatório é **um só**. No topo dele, quem lê escolhe um dos botões:

| Botão | O que mostra |
|---|---|
| **Semana** | Os últimos 7 dias analisados (até a data mais recente da base) |
| **Mês** | O último mês analisado |
| **Ano** | O último ano analisado |
| **Tudo** | Tudo o que já foi analisado |

As datas saem da própria base validada; não há escolha de datas no relatório. Os gráficos, os rankings e as considerações finais mudam junto com o botão.

Seções sobre os comentários:

| Seção | O que mostra |
|---|---|
| **09 · Comentários: positivos, neutros e negativos** | Proporção de cada valência por categoria e subcategoria, e uma tabela com os comentários de cada postagem (percentuais e índice) |
| **10 · Índice de valência** | Gráfico de linha com a evolução do índice da Autenticidade, da Competência e da Humanização ao longo do tempo, e um **radar** com a proporção de comentários positivos e negativos de todo o período (por subcategoria da Liderança ou por categoria). Quanto maior a área verde, melhor o desempenho; quanto maior a vermelha, pior. |

Na barra lateral da aba 4, em **Comentários**, escolha se entram **todos** (os validados e, os demais, com a classificação da IA) ou **só os validados**.

**Passo a passo na aba 4:**

1. **Base validada:** **Tudo junto** (todas as rodadas e todos os arquivos) ou **Uma rodada**. Também dá para importar um CSV já validado.
2. **Período da análise:** escolha **Semana**, **Mês**, **Ano** ou **Tudo**, os mesmos botões do relatório. O app mostra as datas de cada um.
3. **Texto do período:** o rascunho já vem com os números. Complete os trechos entre `[colchetes]` ou use **Redigir análise com IA** e revise. Depois clique em **Salvar texto deste período**. Faça isso para cada botão que quiser comentar.
4. Clique em **Gerar relatório**. Ele abre no botão escolhido. Botões sem texto salvo recebem um texto automático só com os números.

**Análises salvas:** cada texto fica preso às datas em que foi escrito.
- A coluna **No relatório** mostra quais textos aparecem agora (os do trecho mais recente de cada botão).
- Quando entra uma rodada nova, a "última semana" muda e o texto anterior vira **registro**: continua guardado, mas sai do relatório.
- **Editar** carrega o texto no formulário. **Excluir** apaga a análise; os dados validados continuam guardados.

**Relatório gerado:** fica em `saidas/relatorio/` (`index.html` + `dados/monitoramento.csv` + `dados/comentarios_valencia.csv` + `assets/img_cand/`), pronto para publicar no GitHub Pages.
- As fotos são lidas de `assets/img_cand/`, a mesma estrutura do projeto. Ao publicar, mantenha essa pasta ao lado do `index.html`.
- **Baixar (.html com as fotos)** gera um arquivo único, com as fotos dentro, para mandar por e-mail ou abrir em qualquer lugar.
- O link **Excluir** no quadro do relatório apaga essa pasta. Dá para gerar de novo quando quiser.
- Para excluir uma **rodada** inteira, use **Excluir esta rodada** na aba 2.

## Rodadas do esquema anterior

As rodadas categorizadas com o esquema anterior (Conteúdo programático e Conteúdo personalista) continuam guardadas em `saidas/rodadas`, mas não aparecem no app nem no relatório, porque as categorias mudaram. Para analisá-las com as categorias novas, categorize as postagens de novo na aba 1 (as imagens e os vídeos já baixados são reaproveitados).

## O que mudar e onde

| O que | Onde |
|---|---|
| Modelos, % padrão, arredondamento, categorias e cores | `R/config.R` |
| Definições e regras das categorias e subcategorias | `prompts/definicoes.txt` |
| Instruções da valência dos comentários | `prompts/valencia_comentarios.txt` |
| Ator e preço de referência do Apify | `R/comentarios.R` (`APIFY_ATOR`, `APIFY_PRECO_MIL`) |
| Instruções por fonte | `prompts/legenda.txt`, `prompts/imagem.txt`, `prompts/transcricao.txt`, `prompts/transcrever_audio.txt` |
| Candidatos e textos do "Sobre a pesquisa" | Pelo app (aba 4) ou `config/` |
| Análises salvas (textos de cada período) | Pelo app (aba 4) ou `config/periodos.json` |
| Visual do relatório | `templates/relatorio_template.html` |
| Validador compartilhado | `apps_script/` (depois de mudar, publique uma nova versão no Apps Script) |

## Sem a interface (pelo console)

```r
source("R/carregar.R")
rodar_categorizacao(c("dados/lula.xlsx", "dados/cury.xlsx"), c("Lula", "Augusto Cury"),
                    "2026-09-27", "2026-10-03")
```

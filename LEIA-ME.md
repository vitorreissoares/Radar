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
- **Fotos dos candidatos e sua foto do rodapé:** ficam em `Documentos/Radar/assets/img_cand/`. Dá para trocar as fotos dos candidatos pelo app, na aba 4 (painel **Candidatos**), e a sua foto no painel **Sobre a pesquisa**.

### Onde fica cada coisa (dentro de Documentos/Radar)

| O que | Pasta |
|---|---|
| Imagens das postagens (e capas dos vídeos) | `midia/postagens/` (`SHORTCODE.jpg`; carrosséis: `SHORTCODE_1.jpg`, `SHORTCODE_2.jpg`…) |
| Vídeos | `midia/videos/` (`SHORTCODE.mp4`) |
| Áudios extraídos dos vídeos | `midia/audios/` (`SHORTCODE.mp3`) |
| Comentários | `midia/comentarios/` (`SHORTCODE.csv`) |
| Fotos dos candidatos | `assets/img_cand/` (o nome de cada arquivo está na tabela de candidatos, ex.: `lula.jpg`) |
| Sua foto no rodapé do relatório | `assets/img_cand/politica-logo.jpg` (ou `.png`, `.svg`, `.webp`); dá para trocar pelo app (aba 4 → Sobre a pesquisa) |
| Rodadas, validações e relatório gerado | `saidas/` |
| Chaves e configurações | `config/` |

Para abrir a pasta, use o menu **Arquivo → Abrir pasta de dados**.

## Rodar pelo R, sem instalar (só na primeira vez)

1. Instale os pacotes no R:
   ```r
   install.packages(c("shiny", "bslib", "DT", "httr2", "tidyverse", "readxl", "jsonlite", "av"))
   ```
   O pacote `av` extrai o áudio dos vídeos para a transcrição. Não é preciso instalar o ffmpeg.
2. Informe a **chave do OpenRouter** na aba 1, no painel **Chave da IA** da barra lateral (ele abre sozinho enquanto não houver chave): cole a chave e clique em **Salvar chave**. Ela fica guardada só nesta pasta, em `config/chave_openrouter.txt`.
   - Para **compartilhar a pasta** com outra pessoa, clique antes em **Apagar chave**. A chave é removida da pasta e também do `.Renviron` do computador, se estiver lá.
   - A pessoa que receber a pasta informa a própria chave no mesmo quadro.
3. Coloque as fotos dos candidatos e a sua foto do rodapé (`politica-logo.jpg` ou `.png`) em `assets/img_cand/`. O relatório busca as imagens nessa pasta. Também dá para trocar a foto de um candidato pelo app, na aba 4 (painel **Candidatos**).

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

1. **Importar:** adicione um `.xlsx` por vez. Escolha o arquivo, confira ou escreva o nome do candidato e clique em **Adicionar à lista**. Repita para todos os candidatos.
2. **Selecionar:** escolha o início e o fim da coleta (alguns dias, uma semana, um mês, um ano…), o critério e a porcentagem. A regra é **os X% mais curtidos, mais visualizados ou mais comentados de cada candidato em todo o período escolhido** (não é por semana). Só os vídeos têm visualizações: pelo critério de visualizações, as demais postagens ficam no fim da fila. A tabela "Prévia da seleção por candidato" mostra quantas postagens entram.
3. **Analisar:** por padrão, as três fontes. Dá para desmarcar alguma.
   - **Legenda:** o texto da postagem.
   - **Imagens:** todas as imagens do carrossel. Nos vídeos, a capa.
   - **Vídeos:** o áudio é extraído e transcrito, e a transcrição é classificada.
4. Clique em **Baixar imagens, vídeos e áudios**. O app baixa a mídia das postagens selecionadas para a pasta `midia/` e extrai o áudio dos vídeos. Não usa IA e não tem custo. Acima do botão aparece quantas postagens ainda estão sem mídia.
5. Clique em **Categorizar postagens**. Para cada postagem, o app:
   - **transcreve** o áudio do vídeo;
   - pede à IA que marque, **em cada fonte**, as subcategorias presentes.
   - Se ainda faltar mídia, o app avisa antes: dá para voltar e baixar, ou categorizar só com o que houver.

**Nomes dos arquivos** (pelo shortcode da postagem):

| Tipo | Onde fica |
|---|---|
| Imagem única | `midia/postagens/SHORTCODE.jpg` |
| Carrossel | `midia/postagens/SHORTCODE_1.jpg`, `SHORTCODE_2.jpg`, … |
| Vídeo | `midia/videos/SHORTCODE.mp4`, com a capa em `midia/postagens/SHORTCODE.jpg` e o áudio em `midia/audios/SHORTCODE.mp3` |

O registro de cada download fica em `midia/log_downloads.csv`.

> **Baixe as postagens logo depois da coleta.** Os links de imagem e vídeo do Instagram expiram em poucos dias.

Se a categorização parar no meio (por falta de internet ou limite da API), basta clicar de novo. O que já foi feito fica em `saidas/cache_classificacoes_multimodal.csv` e não é cobrado outra vez.

**Visualizações:** vêm da coluna `videoPlayCount` da planilha (se ela faltar, de `videoViewCount`). Ao adicionar um arquivo novo na aba 1, as visualizações das postagens que já estão em rodadas antigas também são atualizadas.

**Comentários da planilha:** as colunas `latestComments/1/text` a `latestComments/10/text` (os primeiros comentários de cada postagem) são guardadas automaticamente em `midia/comentarios/`. Elas formam a **versão demo** da aba 3 (veja abaixo).

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
| **Aceitar classificação** | Aceita a sugestão da IA em **todas** as postagens ainda pendentes da rodada, sem revisão humana (fica registrado como "IA (aceita)") |
| **Anterior** / **Pular** | Servem para revisar |

Não há limite: ligue todas as subcategorias que a postagem tiver. Ao terminar, aparece o botão **Ir para o relatório**.

### Comentários da postagem

Abaixo da classificação de cada postagem fica o quadro **Comentários desta postagem**, a continuação da validação:

- **Números:** comentários que a postagem tem no Instagram, quantos estão salvos (da planilha e do Apify), quantos foram classificados e validados, e o índice da postagem.
- **Margem de erro do índice (IC 95%):** calculada com o número de comentários classificados e o total de comentários da postagem (com correção para população finita). Também aparece a margem só com os validados.
- **Amostra necessária:** quantos comentários classificados seriam precisos para a margem escolhida na barra lateral (**Margem de erro desejada**, 5 pontos por padrão) e quantos faltam. É só uma referência: você escolhe quantos baixar.
- **Classificar com IA:** classifica os comentários desta postagem que ainda não têm valência.
- **Baixar mais … pelo Apify:** escolha quantos comentários novos quer e clique. O Apify devolve os primeiros comentários da postagem, por isso o pedido inclui os que ele já tinha coletado; o custo máximo aparece antes de confirmar.
- **Lista de comentários:** cada um com a classificação da IA e as opções Positivo, Neutro e Negativo, 25 por página. Ajuste o que for preciso e clique em **Salvar validação desta página**.
- **Aceitar a IA nesta postagem** ou **em todos os comentários da rodada:** valida a classificação da IA sem revisão humana e segue para o relatório.

Como calcular a margem: cada comentário vale 1, 0,5 ou 0. Com n comentários classificados de um total N, a margem é 1,96 × √(s²/n) × √((N − n)/(N − 1)), em que s² é a variância observada. A amostra necessária usa o pior caso (s² = 0,25): n₀ = 1,96² × 0,25 / m² e n = n₀ / (1 + (n₀ − 1)/N).

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

Os comentários de cada postagem ficam em `midia/comentarios/SHORTCODE.csv` (uma linha por comentário: id, texto, curtidas, usuário, data, link e origem).

**Versão demo (sem custo):** os primeiros comentários de cada postagem, que já vêm na planilha do Instagram (`latestComments`), entram sozinhos ao categorizar. Antes de pagar pelo Apify, dá para classificar, validar e gerar o relatório só com eles. Um aviso na aba 3 indica quando os comentários são só os da planilha.

Para a análise completa, há dois jeitos de coletar mais:

- **Pelo Apify, direto do app:** informe a sua chave do Apify (em [console.apify.com → Settings → Integrations](https://console.apify.com/settings/integrations)) e escolha **quantos comentários por postagem** coletar.
  - O app mostra antes o **máximo de comentários e o custo máximo estimado** (pelo preço por 1.000 comentários informado; confira o valor atual do *Instagram Comments Scraper* no Apify).
  - Esse limite vai junto com a coleta: o Apify não coleta nem cobra além dele.
  - Deixe marcado **Só postagens ainda sem comentários do Apify** para não pagar duas vezes (os da planilha não contam).
  - A chave fica só nesta pasta (`config/chave_apify.txt`) e pode ser apagada pelo app.
- **Arquivo baixado do Apify:** rode o *Instagram Comments Scraper* no site do Apify com os links das postagens, baixe o resultado em CSV ou JSON e escolha o arquivo no app. Os comentários são separados por postagem automaticamente.

### 2. Classificar com IA

A IA classifica cada comentário como **positivo, neutro ou negativo** em relação ao candidato e à postagem, considerando **ironia, sarcasmo, memes e figuras de linguagem** (que os dicionários de palavras não captam). As instruções ficam em `prompts/valencia_comentarios.txt` e podem ser ajustadas. O que já foi classificado não é cobrado de novo.

### 3. Validar

Em **Validar**, cada postagem mostra uma **amostra fixa** de comentários (30 por padrão, ajustável) com três botões: **Positivo · Neutro · Negativo**, que já vêm com a sugestão da IA. Corrija o que for preciso e clique em **Confirmar e próxima**. A subaba **Acurácia da IA** mostra a concordância entre a IA e a validação, por valência.

### Índice de valência

Cada comentário vale **1** (positivo), **0,5** (neutro) ou **0** (negativo). O índice de uma postagem, categoria ou período é a média desses valores: **(positivos + 0,5 × neutros) ÷ total de comentários**, de **0** (todos negativos) a **1** (todos positivos). Cada comentário pesa igual.

- **Índice geral:** usa todos os comentários do período, com cada postagem uma vez só. Ele não é a média dos índices das categorias: como uma postagem pode estar em mais de uma categoria, essa média contaria os mesmos comentários duas vezes.
- **Intervalo de confiança de 95% (IC 95%):** mostra a margem de incerteza do índice. Como os comentários de uma mesma postagem tendem a ter o mesmo tom, o cálculo usa o erro-padrão robusto por postagem (para o estimador de razão) e a distribuição t com (número de postagens − 1) graus de liberdade. Com poucas postagens, o intervalo fica mais largo, como deve ser. Em simulações, o intervalo contém o valor verdadeiro em 90% a 95% das vezes, de 3 a 50 postagens; tratar os comentários como independentes acertaria só cerca de 35%.
- Intervalos que se sobrepõem indicam que a diferença entre dois grupos pode ser casual.

## 4 · Relatório

O relatório é **um só**. No topo dele, quem lê escolhe um dos botões:

| Botão | O que mostra |
|---|---|
| **Semana** | Os últimos 7 dias analisados (até a data mais recente da base) |
| **Mês** | O último mês analisado |
| **Ano** | O último ano analisado |
| **Tudo** | Tudo o que já foi analisado |

As datas saem da própria base validada; não há escolha de datas no relatório. Os gráficos, os rankings e as considerações finais mudam junto com o botão.

Algumas seções:

| Seção | O que mostra |
|---|---|
| **Qual subcategoria mais cresceu** | Para o botão escolhido (Semana, Mês, Ano), compara a parcela das postagens de cada candidato com Autenticidade, Competência e Humanização com a do período anterior de mesmo tamanho (no botão Tudo, a segunda metade com a primeira). Mostra a variação em pontos percentuais, o maior aumento de cada candidato e de todos juntos, e avisa quando há menos de 10 postagens num dos períodos. |
| **Top 10** | As 10 postagens com mais curtidas, mais comentários e mais visualizações (só os vídeos têm visualizações) |
| **Evolução do índice da Liderança** | Uma linha por candidato com o **índice da Liderança**: a média ponderada das três subcategorias, com peso pelo número de comentários de cada uma. Botões mostram cada subcategoria separada, se quiser. |
| **Desempenho nos comentários** | **Radar** com uma camada por candidato, sobrepostas (os valores não se somam): o índice de cada subcategoria da Liderança (ou de cada categoria). Ao lado, o índice da Liderança de cada candidato, com IC 95%. |
| **Desempenho dos candidatos** | Aparece quando há um `performance.csv` importado (veja abaixo): a evolução de cada métrica (intenção de voto, seguidores…) por candidato |
| **Índice de valência e intenção de voto** | Aparece só quando há pesquisas importadas: o índice da Liderança e a intenção de voto de todos os candidatos no mesmo gráfico, por turno |

As seções são numeradas na ordem em que aparecem; as que dependem de arquivos opcionais somem quando o arquivo não foi importado.

Os cartões das candidaturas no topo mostram só a foto, o partido e o número. Intenção de voto e seguidores ficam na seção **Desempenho dos candidatos**.

Cada variável tem sempre a mesma cor em todas as seções: Liderança (anil), Partido (verde-azulado), Políticas (laranja), Autenticidade (rosa), Competência (dourado), Humanização (azul-claro); comentários positivos em verde, neutros em cinza e negativos em vermelho; e cada candidato com a sua cor.

Na barra lateral da aba 4, em **Comentários**, escolha se entram **todos** (os validados e, os demais, com a classificação da IA) ou **só os validados**.

### Idioma do relatório

No painel **Idioma do relatório** (aba 4), escolha **Português**, **English** ou **Español**. No idioma escolhido saem:
- os títulos, botões, gráficos, legendas e notas do relatório;
- os nomes das categorias e subcategorias;
- o rascunho das considerações finais e o texto redigido pela IA.

O **título**, o **subtítulo**, o **texto do rodapé** e os quadros do **Sobre a pesquisa** são escritos por você, por isso são guardados **separadamente para cada idioma**. Ao trocar o idioma, os campos mostram a versão daquele idioma (na primeira vez, partem do texto em português, para você traduzir). Textos de considerações finais já salvos não são traduzidos: com outro idioma, clique em **Rascunho** e salve o texto novo.

### Pesquisas eleitorais (índice × intenção de voto)

No painel **Pesquisas e desempenho** (aba 4), escolha o CSV baixado de um agregador de pesquisas. Ele precisa das colunas `data`, `candidato` e `intencao`:

```
data,candidato,intencao
05/08/2026,Lula (1º turno),"40,3"
05/08/2026,Lula (2º turno),"45,6"
```

- Datas em `DD/MM/AAAA` ou `AAAA-MM-DD`; vírgula ou ponto decimal; separador vírgula ou ponto e vírgula.
- O turno pode vir no nome do candidato, como acima, ou numa coluna `turno`. Sem turno, vale o 1º.
- Os nomes são ligados aos da tabela de candidatos ("Flavio Bolsonaro" vira "Flávio Bolsonaro"). O painel avisa se algum nome não tem postagens na base.
- Importar de novo substitui as pesquisas anteriores. O arquivo fica em `config/pesquisas.csv`.

**Como o relatório compara as duas séries (seção 11):**
- Para cada pesquisa, o índice de valência é calculado com os comentários das postagens publicadas **desde a pesquisa anterior** do mesmo candidato (a primeira usa os 14 dias antes dela). Assim, cada ponto do índice fica ao lado da intenção de voto medida no fim do mesmo intervalo.
- O gráfico de cada candidato tem dois eixos: o índice (0 a 1, com a faixa do IC 95%) à esquerda e a intenção de voto (%) à direita. Botões trocam entre 1º e 2º turno.
- As medidas resumo usam as **variações** entre pesquisas, não os níveis (duas séries com tendência parecem andar juntas mesmo sem relação):
  - correlação entre a variação do índice e a variação da intenção (em p.p.) no mesmo intervalo;
  - correlação entre o índice de um intervalo e a variação da intenção no intervalo seguinte (o índice antecipa as pesquisas?).
  - Os resultados saem com o número de intervalos e o IC 95% (transformação de Fisher, a partir de 4 intervalos).
- É uma associação exploratória, não causal. Com menos de 8 intervalos, o relatório avisa que o resultado serve só como indicação. A seção usa todo o período analisado, qualquer que seja o botão escolhido no topo.

### Desempenho dos candidatos (performance.csv)

No mesmo painel **Pesquisas e desempenho**, escolha o `performance.csv`: uma linha por data e candidato e uma coluna por métrica.

```
data;candidato;intencao_voto;seguidores_ig
05/08/2026;Lula;40,3;15.300.000
05/08/2026;Flávio Bolsonaro;32,5;11.800.000
```

Aceita vírgula ou ponto e vírgula, vírgula decimal, ponto de milhar e valores como `15,3M`. No relatório, cada métrica vira um botão, com uma linha por candidato.

### Cabeçalho e rodapé

Em **Sobre a pesquisa** (aba 4):
- **Cabeçalho:** título, subtítulo (opcional) e a assinatura, que aparece abaixo do subtítulo.
- **Quadros do "Sobre a pesquisa":** use **Adicionar quadro** e o ícone de lixeira de cada quadro para decidir quais aparecem no relatório. O primeiro quadro abre a seção; os demais ficam lado a lado.
- **Rodapé:** foto (vira `assets/img_cand/politica-logo`), nome, **cargo ou formação**, **minibiografia**, links do **Lattes**, **ORCID**, **LinkedIn**, **Google Acadêmico** e **GitHub** e uma nota final opcional. Os links preenchidos viram ícones; os vazios não aparecem. Cargo, minibiografia e nota têm uma versão para cada idioma.

Clique em **Salvar cabeçalho, rodapé e textos** (ou só gere o relatório, que também salva).

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
- A pasta `assets/img_cand/` ao lado do `index.html` recebe as fotos dos candidatos e a sua foto do rodapé. Elas vêm da sua pasta de dados; as que faltarem, das fotos que acompanham o programa. Ao publicar, mantenha essa pasta ao lado do `index.html`.
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
| Candidatos e textos do "Sobre a pesquisa" | Pelo app (aba 4) ou `config/` (`sobre_a_pesquisa.json`; em inglês e espanhol, `sobre_a_pesquisa_en.json` e `sobre_a_pesquisa_es.json`) |
| Título, subtítulo, rodapé, links e idioma | Pelo app (aba 4) ou `config/relatorio.json` |
| Análises salvas (textos de cada período) | Pelo app (aba 4) ou `config/periodos.json` |
| Visual do relatório | `templates/relatorio_template.html` |
| Validador compartilhado | `apps_script/` (depois de mudar, publique uma nova versão no Apps Script) |

## Sem a interface (pelo console)

```r
source("R/carregar.R")
rodar_categorizacao(c("dados/lula.xlsx", "dados/cury.xlsx"), c("Lula", "Augusto Cury"),
                    "2026-09-27", "2026-10-03")
```

# Radar

Um único app com as etapas do monitoramento de postagens no Instagram. Cada pesquisa é um **projeto**, com a sua pasta:

| Aba | O que você faz | O que sai |
|---|---|---|
| **1 · Categorização** | Cria ou abre o projeto, importa um `.xlsx` por candidato (com nome, partido e foto), escolhe o período e a seleção, baixa a mídia e categoriza | Postagens selecionadas de cada candidato, com **legenda, imagens e vídeo** analisados pela IA; mídia salva na pasta de cada candidato |
| **2 · Validação** | Confere cada postagem e os seus **comentários** (classificação da IA, margem de erro, coleta pelo Apify), ou aceita a classificação da IA de uma vez | Base validada, comentários classificados como **positivos, neutros ou negativos** e **acurácia da IA** |
| **3 · Relatório** | Revisa o texto de cada botão, os candidatos e o "Sobre a pesquisa" | **Um único relatório**, com os botões **Semana, Mês, Ano e Tudo** no topo |

## Instalar o programa (recomendado)

Baixe o instalador do seu sistema (Windows, Mac ou Linux) na página **Releases** do repositório no GitHub e siga o passo a passo do README. O instalador já traz o R e todos os pacotes.

- **Chave da IA:** cada pessoa informa a **própria chave do OpenRouter** no painel **Chave da IA** da aba 1. Ela fica guardada só no computador de quem a informou.
- **Projetos:** cada pesquisa fica numa pasta escolhida por você (painel **Projeto**, aba 1). Candidatos, períodos, mídias, validações e relatórios de pesquisas diferentes nunca se misturam. O Radar abre sempre no último projeto usado.
- **Pasta do programa:** **Documentos/Radar** guarda só o que é seu: as chaves (OpenRouter e Apify) e a lista de projetos. Os dados das versões anteriores continuam nela e aparecem em **Abrir projeto** como "Pasta de dados do Radar". Instalar uma versão nova não apaga nada.

### Projetos

No painel **Projeto** (aba 1):

- **Novo projeto:** dê um nome à pesquisa e escolha onde salvar (o botão **Escolher…** abre a janela do sistema). O Radar cria, dentro da pasta escolhida, uma pasta com o nome da pesquisa. O cabeçalho, o rodapé e a sua foto do relatório vêm do projeto atual.
- **Abrir projeto:** escolha um projeto recente ou indique a pasta de outro.
- Cada projeto tem **uma rodada só**: categorizar de novo atualiza a seleção e mantém as validações das postagens que continuam nela. O relatório usa só as postagens do projeto.

### Onde fica cada coisa (dentro da pasta do projeto)

| O que | Pasta |
|---|---|
| Planilhas importadas | `bases/` (cópia de cada `.xlsx`; a lista fica em `config/bases.json`) |
| Imagens das postagens (e capas dos vídeos) | `midia/<Candidato>/imagens/` (`AAAA-MM-DD_SHORTCODE.jpg`; carrosséis: `…_1.jpg`, `…_2.jpg`) |
| Vídeos | `midia/<Candidato>/videos/` (`AAAA-MM-DD_SHORTCODE.mp4`) |
| Áudios extraídos dos vídeos | `midia/<Candidato>/audios/` (`AAAA-MM-DD_SHORTCODE.mp3`) |
| Comentários | `midia/<Candidato>/comentarios/` (`AAAA-MM-DD_SHORTCODE.csv`) |
| Fotos dos candidatos e a sua foto do rodapé | `assets/img_cand/` |
| Candidatos, pesquisas e desempenho, textos do relatório | `config/` |
| Rodada, validações e relatório gerado | `saidas/` |

A data no início do nome é a da postagem. Arquivos baixados por versões anteriores (`midia/postagens/SHORTCODE.jpg` etc.) continuam sendo encontrados.

## Rodar pelo R, sem instalar (só na primeira vez)

1. Instale os pacotes no R:
   ```r
   install.packages(c("shiny", "bslib", "DT", "httr2", "tidyverse", "readxl", "jsonlite", "av"))
   ```
   O pacote `av` extrai o áudio dos vídeos para a transcrição. Não é preciso instalar o ffmpeg.
2. Informe a **chave do OpenRouter** na aba 1, no painel **Chave da IA** da barra lateral (ele abre sozinho enquanto não houver chave): cole a chave e clique em **Salvar chave**. Ela fica guardada só neste computador, em `config/chave_openrouter.txt` da pasta de dados do programa (não vai junto com os projetos).
   - Para **compartilhar a pasta** com outra pessoa, clique antes em **Apagar chave**. A chave é removida da pasta e também do `.Renviron` do computador, se estiver lá.
   - A pessoa que receber a pasta informa a própria chave no mesmo quadro.
3. As fotos dos candidatos entram ao importar cada base (aba 1). A sua foto do rodapé (`politica-logo.jpg` ou `.png`) fica em `assets/img_cand/` do projeto e pode ser trocada na aba 3 (painel **Sobre a pesquisa**).

### Abrir o app

- **Sem o RStudio:** dê dois cliques em **`Abrir Radar.bat`**. Para ter um ícone na área de trabalho, rode uma vez **`Criar atalho na area de trabalho.bat`**. Para fechar o app, feche a janela preta.
- **Pelo RStudio:** abra `app.R` e clique em **Run App**.

### Como a tela é organizada

- A **barra lateral** de cada aba é dividida em painéis que abrem e fecham com um clique (por exemplo: Chave da IA, Arquivos, Período, O que a IA analisa, Modelos). O botão principal da aba fica sempre visível no rodapé da barra.
- A seta no topo da barra lateral esconde a barra inteira, para dar mais espaço.
- Na aba 3, **Análises salvas**, **Candidatos** e **Sobre a pesquisa** ficam recolhidos embaixo do texto. Clique no título para abrir.

## Categorias e subcategorias

Cada postagem pode receber **quantas categorias forem necessárias** (ou nenhuma). A IA e a validação humana escolhem entre todas:

| Categoria | Quando | Subcategorias |
|---|---|---|
| **Liderança** | A postagem enfatiza características da liderança política | **Autenticidade** (genuinidade e coerência: sinceridade, consistência, valores, credibilidade e confiança) · **Competência** (capacidade de exercer as funções e cumprir compromissos: conhecimento, habilidades, experiência, liderança e desempenho) · **Humanização** (o líder como pessoa próxima e identificável: empatia, vida cotidiana, experiências pessoais, acessibilidade e identificação) |
| **Partido** | A postagem enfatiza características do partido ou da sigla partidária | — |
| **Políticas** | A postagem enfatiza características relacionadas a políticas públicas | — |

A Liderança é marcada pelas suas subcategorias: uma postagem é de Liderança quando recebe ao menos uma delas. As definições completas usadas pela IA estão em `prompts/definicoes.txt`.

## 1 · Categorização

1. **Projeto:** crie um projeto novo para cada pesquisa (veja acima).
2. **Importar:** adicione um `.xlsx` por vez. Escolha o arquivo, confira ou escreva o **nome do candidato**, informe o **partido e número** (opcional) e a **foto** (opcional) e clique em **Adicionar à lista**. Repita para todos os candidatos. Os candidatos importados são os que entram no relatório, com essa foto e esse partido.
   - **Pesquisas e desempenho (opcional):** no mesmo painel, um `.csv` com intenção de voto, seguidores etc. (veja na aba 3). Sem ele, essas seções não aparecem no relatório.
3. **Selecionar:** escolha o início e o fim da coleta, o critério e a porcentagem: os X% **mais curtidos**, **mais visualizados**, **mais comentados** ou **aleatórios** de cada candidato no período escolhido. Só os vídeos têm visualizações. Na seleção aleatória, o sorteio é sempre o mesmo para a mesma base e o mesmo período. A tabela "Prévia da seleção por candidato" mostra quantas postagens entram.
4. **Analisar:** por padrão, as três fontes. Dá para desmarcar alguma.
   - **Legenda:** o texto da postagem.
   - **Imagens:** todas as imagens do carrossel. Nos vídeos, a capa.
   - **Vídeos:** o áudio é extraído e transcrito, e a transcrição é classificada.
5. Clique em **Baixar imagens, vídeos e áudios**. O app baixa a mídia das postagens selecionadas para a pasta de cada candidato e extrai o áudio dos vídeos. Não usa IA e não tem custo. Acima do botão aparece quantas postagens ainda estão sem mídia.
6. Clique em **Categorizar postagens**. Para cada postagem, o app transcreve o áudio do vídeo e pede à IA que marque, **em cada fonte**, as subcategorias presentes. Se ainda faltar mídia, o app avisa antes.

O registro de cada download fica em `midia/log_downloads.csv`.

> **Baixe as postagens logo depois da coleta.** Os links de imagem e vídeo do Instagram expiram em poucos dias.

Se a categorização parar no meio (por falta de internet ou limite da API), basta clicar de novo. O que já foi feito fica em `saidas/cache_classificacoes_multimodal.csv` e não é cobrado outra vez.

**Visualizações:** vêm da coluna `videoPlayCount` da planilha (se ela faltar, de `videoViewCount`). Ao adicionar um arquivo novo na aba 1, as visualizações das postagens que já estão em rodadas antigas também são atualizadas.

**Comentários da planilha:** as colunas `latestComments/1/text` a `latestComments/10/text` (os primeiros comentários de cada postagem) são guardadas automaticamente na pasta de comentários de cada candidato. Elas formam a **versão demo**: dá para classificar e gerar o relatório só com eles, sem custo, antes de baixar mais pelo Apify.

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
| **Aceitar classificação da IA** | Um botão só para tudo: as postagens pendentes ficam com a sugestão da IA, os comentários ainda sem classificação são classificados pela IA (se você deixar marcado) e todos os comentários passam a valer com a classificação da IA. Depois, vai para o relatório. Fica registrado como "IA (aceita)"; o que você já validou não muda. |
| **Anterior** / **Pular** | Servem para revisar |

Não há limite: ligue todas as subcategorias que a postagem tiver. Ao terminar, aparece o botão **Ir para o relatório**.

### Comentários da postagem

Abaixo da classificação de cada postagem fica o quadro **Comentários desta postagem**, a continuação da validação:

- **Números:** comentários que a postagem tem no Instagram, quantos estão salvos (da planilha e do Apify), quantos foram classificados e validados, e o índice da postagem.
- **Margem de erro com a amostra atual (IC 95%):** calculada com os comentários classificados e o total de comentários da postagem (com correção para população finita), com o intervalo de confiança e a margem só com os validados.
- **Amostra representativa:** quantos comentários classificados seriam precisos para a margem escolhida na barra lateral (**Margem de erro desejada**, 5 pontos por padrão), quantos faltam e, ao lado, a margem da amostra atual. É só uma referência: você escolhe quantos baixar.
- Se houver comentários ainda sem classificação, um aviso amarelo mostra quantos.
- **Classificar com IA:** classifica os comentários desta postagem que ainda não têm valência.
- **Baixar mais … pelo Apify:** escolha quantos comentários novos quer e clique. O Apify devolve os primeiros comentários da postagem, por isso o pedido inclui os que ele já tinha coletado; o custo máximo aparece antes de confirmar.
- **Lista de comentários:** cada um com a classificação da IA e as opções Positivo, Neutro e Negativo, 25 por página. Ajuste o que for preciso e clique em **Salvar validação desta página**.
- **Aceitar a IA nos comentários desta postagem:** valida a classificação da IA só desta postagem.

O relatório também mostra a precisão: a seção **Desempenho nos comentários** tem a tabela **Precisão da amostra de comentários**, com a margem atual, o IC 95% e a amostra representativa de cada candidato.

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

### Comentários de todas as postagens (barra lateral da aba 2)

O painel **Comentários (todas as postagens)** reúne o que vale para a rodada inteira:

- **Andamento:** quantos comentários estão salvos, classificados pela IA e validados.
- **Coletar pelo Apify, direto do app:** informe a sua chave do Apify (em [console.apify.com → Settings → Integrations](https://console.apify.com/settings/integrations)) e escolha **quantos comentários por postagem** coletar. O app mostra antes o máximo de comentários e o custo máximo estimado, e esse limite vai junto com a coleta. Deixe marcado **Só postagens ainda sem comentários do Apify** para não pagar duas vezes. A chave fica só no seu computador (`Documentos/Radar/config/chave_apify.txt`) e pode ser apagada pelo app.
- **Arquivo baixado do Apify:** rode o *Instagram Comments Scraper* no site do Apify, baixe o resultado em CSV ou JSON e escolha o arquivo. Os comentários vão para a pasta de cada candidato.
- **Classificar todos os comentários:** a IA classifica cada comentário como **positivo, neutro ou negativo** em relação ao candidato e à postagem, considerando **ironia, sarcasmo, memes e figuras de linguagem**. As instruções ficam em `prompts/valencia_comentarios.txt`. O que já foi classificado não é cobrado de novo.

A subaba **Comentários** mostra a visão geral por postagem, e **Acurácia da IA** mostra também a concordância entre a IA e a validação dos comentários.

### Índice de valência

Cada comentário vale **1** (positivo), **0,5** (neutro) ou **0** (negativo). O índice de uma postagem, categoria ou período é a média desses valores: **(positivos + 0,5 × neutros) ÷ total de comentários**, de **0** (todos negativos) a **1** (todos positivos). Cada comentário pesa igual.

- **Índice geral:** usa todos os comentários do período, com cada postagem uma vez só. Ele não é a média dos índices das categorias: como uma postagem pode estar em mais de uma categoria, essa média contaria os mesmos comentários duas vezes.
- **Intervalo de confiança de 95% (IC 95%):** mostra a margem de incerteza do índice. Como os comentários de uma mesma postagem tendem a ter o mesmo tom, o cálculo usa o erro-padrão robusto por postagem (para o estimador de razão) e a distribuição t com (número de postagens − 1) graus de liberdade. Com poucas postagens, o intervalo fica mais largo, como deve ser. Em simulações, o intervalo contém o valor verdadeiro em 90% a 95% das vezes, de 3 a 50 postagens; tratar os comentários como independentes acertaria só cerca de 35%.
- Intervalos que se sobrepõem indicam que a diferença entre dois grupos pode ser casual.

## 3 · Relatório

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

Na barra lateral da aba 3, em **Comentários**, escolha se entram **todos** (os validados e, os demais, com a classificação da IA) ou **só os validados**.

### Idioma do relatório

No painel **Idioma do relatório** (aba 3), escolha **Português**, **English** ou **Español**. No idioma escolhido saem:
- os títulos, botões, gráficos, legendas e notas do relatório;
- os nomes das categorias e subcategorias;
- o rascunho das considerações finais e o texto redigido pela IA.

O **título**, o **subtítulo**, o **texto do rodapé** e os quadros do **Sobre a pesquisa** são escritos por você, por isso são guardados **separadamente para cada idioma**. Ao trocar o idioma, os campos mostram a versão daquele idioma (na primeira vez, partem do texto em português, para você traduzir). Textos de considerações finais já salvos não são traduzidos: com outro idioma, clique em **Rascunho** e salve o texto novo.

### Pesquisas e desempenho (um arquivo só)

Na aba 1, painel **Importar**, escolha um `.csv` com `data`, `candidato` e uma coluna por métrica:

```
data;candidato;intencao_voto;seguidores_ig
05/08/2026;James Talarico;40,3;150.000
05/08/2026;Ken Paxton;32,5;210.000
```

- Datas em `DD/MM/AAAA` ou `AAAA-MM-DD`; vírgula ou ponto decimal, ponto de milhar e valores como `15,3M`; separador vírgula ou ponto e vírgula.
- **Turno:** pode vir numa coluna `turno`, no nome do candidato ("Lula (2º turno)") ou no nome da coluna (`intencao_1turno`, `intencao_2turno`). Sem turno, a intenção de voto vale como 1º turno.
- Os nomes são ligados aos dos candidatos importados. O painel avisa se algum nome não tem base importada.
- Importar de novo substitui o arquivo anterior (fica em `config/performance.csv`).

No relatório, o arquivo vira duas seções, que só aparecem quando ele existe:

- **Desempenho dos candidatos:** cada métrica vira um botão, com uma linha por candidato.
- **Índice de valência e intenção de voto:** as colunas de intenção de voto são comparadas com o índice da Liderança dos comentários.
  - Para cada pesquisa, o índice é calculado com os comentários das postagens publicadas **desde a pesquisa anterior** (a primeira usa os 14 dias antes dela).
  - Todos os candidatos ficam no mesmo gráfico: linha contínua para o índice (0 a 1) e tracejada para a intenção de voto (%), botões para 1º e 2º turno.
  - As medidas resumo usam as **variações** entre pesquisas, não os níveis: a variação do índice × a variação da intenção no mesmo intervalo, e o índice de um intervalo × a variação da intenção no seguinte. Saem com o número de intervalos e o IC 95% (transformação de Fisher, a partir de 4 intervalos).
  - É uma associação exploratória, não causal. Com menos de 8 intervalos, o relatório avisa que o resultado serve só como indicação.

### Cabeçalho e rodapé

Em **Sobre a pesquisa** (aba 3):
- **Cabeçalho:** título, subtítulo (opcional) e a assinatura, que aparece abaixo do subtítulo.
- **Quadros do "Sobre a pesquisa":** use **Adicionar quadro** e o ícone de lixeira de cada quadro para decidir quais aparecem no relatório. O primeiro quadro abre a seção; os demais ficam lado a lado.
- **Rodapé:** foto (vira `assets/img_cand/politica-logo`), nome, **cargo ou formação**, **minibiografia**, links do **Lattes**, **ORCID**, **LinkedIn**, **Google Acadêmico** e **GitHub** e uma nota final opcional. Os links preenchidos viram ícones; os vazios não aparecem. Cargo, minibiografia e nota têm uma versão para cada idioma.

Clique em **Salvar cabeçalho, rodapé e textos** (ou só gere o relatório, que também salva).

**Passo a passo na aba 3:**

1. **Base validada:** o relatório usa só as postagens do projeto aberto (a rodada única dele), sem misturar pesquisas. Em pastas de versões anteriores, com várias rodadas, escolha uma. Também dá para importar um CSV já validado.
2. **Texto por botão do relatório:** o período da pesquisa é o escolhido na aba 1. Aqui você escolhe qual botão (**Semana**, **Mês**, **Ano** ou **Tudo**) recebe as considerações finais e em qual o relatório abre. O app mostra as datas de cada um.
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
| Candidatos e textos do "Sobre a pesquisa" | Pelo app (aba 3) ou `config/` (`sobre_a_pesquisa.json`; em inglês e espanhol, `sobre_a_pesquisa_en.json` e `sobre_a_pesquisa_es.json`) |
| Título, subtítulo, rodapé, links e idioma | Pelo app (aba 3) ou `config/relatorio.json` |
| Análises salvas (textos de cada período) | Pelo app (aba 3) ou `config/periodos.json` |
| Visual do relatório | `templates/relatorio_template.html` |
| Validador compartilhado | `apps_script/` (depois de mudar, publique uma nova versão no Apps Script) |

## Sem a interface (pelo console)

```r
source("R/carregar.R")
rodar_categorizacao(c("dados/lula.xlsx", "dados/cury.xlsx"), c("Lula", "Augusto Cury"),
                    "2026-09-27", "2026-10-03")
```

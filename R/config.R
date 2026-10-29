# =========================================================
# CONFIGURAÇÕES DO MONITORAMENTO
# Edite aqui o que muda de uma rodada para outra.
# =========================================================

# Modelo usado no OpenRouter
MODELO_PADRAO <- "openai/gpt-5.6-luna"
# Como o modelo aparece escrito no texto de metodologia do relatório
MODELO_ROTULO <- "GPT-5.6 Luna"

# Domingo que inicia a "semana_01" (as semanas vão de domingo a sábado)
INICIO_SEMANA_01 <- as.Date("2026-08-16")

# Percentual de postagens mais curtidas de cada candidato, no período escolhido na aba 1
PROPORCAO_TOP_PADRAO <- 0.20
# "cima": 20% de 7 postagens = 2 (garante ao menos 1 por candidato)
# "baixo": 20% de 7 postagens = 1 (pode zerar candidatos com poucas postagens)
ARREDONDAMENTO_TOP <- "cima"

# Candidatos (nome, partido, intenção de voto, seguidores, foto) ficam em
# config/candidatos.csv e podem ser editados pelo app.
#
# Os padrões abaixo só servem para SUGERIR o candidato de cada arquivo
# (pela coluna "alt") e para arquivos que misturam vários candidatos.
# id em config/candidatos.csv  =  texto procurado na coluna "alt"
CANDIDATOS <- c(
  "Renan"  = "Renan",
  "Flavio" = "Bolsonaro",
  "Lula"   = "Lula",
  "Cury"   = "Cury",
  "Caiado" = "Caiado"
)

# ---------------------------------------------------------
# Categorias e subcategorias
# ---------------------------------------------------------
# Três categorias: Liderança, Partido e Políticas. Só a Liderança tem
# subcategorias (Autenticidade, Competência e Humanização): uma postagem é de
# Liderança quando recebe ao menos uma delas. Partido e Políticas são marcadas
# diretamente. Uma postagem pode receber quantas forem necessárias (ou nenhuma).
# "chave" é o nome usado pela IA (JSON) e nas colunas da base; não mude as chaves.
# "rotulo" é o que aparece no app e nos relatórios (pode mudar).
# "subcategoria": FALSE quando a chave é a própria categoria (sem subcategorias).
SUBCATEGORIAS_TAB <- tibble::tribble(
  ~chave,              ~categoria,   ~rotulo,          ~subcategoria,
  "lid_autenticidade", "Liderança",  "Autenticidade",  TRUE,
  "lid_competencia",   "Liderança",  "Competência",    TRUE,
  "lid_humanizacao",   "Liderança",  "Humanização",    TRUE,
  "partido",           "Partido",    "Partido",        FALSE,
  "politicas",         "Políticas",  "Políticas",      FALSE
)
CHAVES <- SUBCATEGORIAS_TAB$chave
CATEGORIAS <- unique(SUBCATEGORIAS_TAB$categoria)
SUBCATEGORIAS <- split(SUBCATEGORIAS_TAB$rotulo, SUBCATEGORIAS_TAB$categoria)
# Subcategorias da Liderança (usadas nos gráficos de valência dos comentários)
CHAVES_LIDERANCA <- SUBCATEGORIAS_TAB$chave[SUBCATEGORIAS_TAB$subcategoria]

# Cores das categorias no relatório
CORES_CATEGORIAS <- c("Liderança" = "#7c3aed", "Partido" = "#0e7490", "Políticas" = "#ea580c")

# Versão do esquema de categorias. Rodadas de esquemas anteriores (Programático e
# Personalista) ficam guardadas em saidas/rodadas, mas não entram no app nem no relatório.
ESQUEMA_VERSAO <- 2L

# Fontes analisadas pela IA em cada postagem
FONTES <- c(legenda = "Legenda", imagem = "Imagem", transcricao = "Vídeo (transcrição)")

# Modelos (OpenRouter). O de imagem precisa aceitar imagens; o de transcrição, áudio.
MODELO_TRANSCRICAO <- "google/gemini-2.5-flash"

# Máximo de imagens por requisição (carrosséis maiores são divididos em lotes)
MAX_IMAGENS_POR_REQUISICAO <- 10

# Arquivos de prompt (pasta prompts/)
PROMPTS <- list(
  definicoes = arquivo_app("prompts/definicoes.txt"),
  instrucao  = arquivo_app("prompts/instrucao_saida.txt"),
  legenda    = arquivo_app("prompts/legenda.txt"),
  imagem     = arquivo_app("prompts/imagem.txt"),
  transcricao = arquivo_app("prompts/transcricao.txt"),
  transcrever = arquivo_app("prompts/transcrever_audio.txt"),
  valencia   = arquivo_app("prompts/valencia_comentarios.txt")
)

# Ordem das colunas principais da base classificada/validada
COLUNAS_SAIDA <- c(
  "candidato", "url", "caption", "transcricao", "likes", "shortCode", "comentarios",
  "data", "semana", "formato"
)

# Mídia baixada (imagens: SHORTCODE.jpg ou SHORTCODE_1.jpg, _2.jpg... em carrosséis;
# vídeos: SHORTCODE.mp4; capa dos vídeos também em postagens/SHORTCODE.jpg)
PASTA_MIDIA <- "midia"
PASTA_IMAGENS <- file.path(PASTA_MIDIA, "postagens")
PASTA_VIDEOS <- file.path(PASTA_MIDIA, "videos")
PASTA_AUDIOS <- file.path(PASTA_MIDIA, "audios")
BAIXAR_CAPAS_VIDEOS <- TRUE

# Pastas de trabalho
PASTA_RODADAS <- "saidas/rodadas"
# Relatório único (pronto para publicar: index.html + dados + fotos)
PASTA_RELATORIO <- "saidas/relatorio"

# Cache de classificações (evita pagar duas vezes pela mesma postagem
# e permite retomar se a classificação for interrompida)
ARQUIVO_CACHE <- "saidas/cache_classificacoes_v2.csv"   # v2: categorias Liderança/Partido/Políticas

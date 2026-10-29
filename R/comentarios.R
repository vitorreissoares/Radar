# =========================================================
# COMENTÁRIOS DAS POSTAGENS (ETAPA 3)
# 1. Coleta: arquivo exportado do Apify ou coleta direta pela API do Apify,
#    com limite de comentários por postagem (controle de custo).
# 2. Cada postagem ganha um arquivo midia/comentarios/SHORTCODE.csv.
# 3. A IA classifica a valência de cada comentário (positivo, neutro, negativo),
#    considerando ironia, sarcasmo e figuras de linguagem.
# 4. A validação humana confirma ou corrige a classificação.
#
#   saidas/comentarios_valencia_ia.csv   classificação da IA (uma linha por comentário)
#   saidas/comentarios_validacao.csv     validação humana (a mais recente vale)
# =========================================================

PASTA_COMENTARIOS <- file.path(PASTA_MIDIA, "comentarios")
ARQUIVO_VALENCIA_IA <- "saidas/comentarios_valencia_ia.csv"
ARQUIVO_VALENCIA_VALIDACAO <- "saidas/comentarios_validacao.csv"
ARQUIVO_CHAVE_APIFY <- "config/chave_apify.txt"

# Ator do Apify que coleta comentários do Instagram e preço de referência
# (US$ por 1.000 comentários; confira o valor atual na página do ator)
APIFY_API <- "https://api.apify.com/v2/"
APIFY_ATOR <- "apify~instagram-comment-scraper"
APIFY_PRECO_MIL <- 2.30
COMENTARIOS_POR_POSTAGEM_PADRAO <- 50

VALENCIAS <- c(positivo = "Positivo", neutro = "Neutro", negativo = "Negativo")
COMENTARIOS_POR_LOTE <- 40   # comentários enviados à IA de uma vez

COLUNAS_COMENTARIOS <- c("comentario_id", "shortCode", "texto", "curtidas", "usuario", "data", "url_comentario")

comentarios_vazio <- function() {
  tibble(comentario_id = character(), shortCode = character(), texto = character(),
         curtidas = numeric(), usuario = character(), data = character(), url_comentario = character())
}

# ---------------------------------------------------------
# 1. Arquivos de comentários (um por postagem)
# ---------------------------------------------------------

arquivo_comentarios <- function(shortCode) file.path(PASTA_COMENTARIOS, paste0(shortCode, ".csv"))

# "https://www.instagram.com/p/DfCTPU6tRa0/c/181..." -> "DfCTPU6tRa0"
shortcode_de_url <- function(url) {
  str_match(coalesce(url, ""), "instagram\\.com/(?:[^/]+/)?(?:p|reel|reels|tv)/([A-Za-z0-9_-]+)")[, 2]
}

ler_comentarios <- function(shortCode) {
  arq <- arquivo_comentarios(shortCode)
  if (!file.exists(arq)) return(comentarios_vazio())
  read_csv(arq, col_types = cols(.default = col_character()), show_col_types = FALSE) %>%
    mutate(curtidas = suppressWarnings(as.numeric(curtidas)))
}

# Quantos comentários estão salvos para cada postagem
contar_comentarios_salvos <- function(shortCodes) {
  map_int(shortCodes, \(sc) nrow(ler_comentarios(sc)))
}

# Primeira coluna existente entre as indicadas (o Apify muda os nomes conforme o formato)
coluna <- function(d, nomes) {
  for (n in nomes) if (n %in% names(d)) return(as.character(d[[n]]))
  rep(NA_character_, nrow(d))
}

# Converte a saída do Apify (CSV ou JSON) para as colunas do projeto
normalizar_comentarios_apify <- function(d) {
  if (nrow(d) == 0) return(comentarios_vazio())
  names(d) <- str_remove(names(d), "^﻿")
  url_post <- coluna(d, c("postUrl", "inputUrl", "url"))
  url_com <- coluna(d, c("commentUrl"))
  tibble(
    comentario_id = coluna(d, c("id", "commentId")),
    shortCode = coalesce(shortcode_de_url(url_post), shortcode_de_url(url_com)),
    texto = coluna(d, c("text", "comment", "texto")),
    curtidas = suppressWarnings(as.numeric(coluna(d, c("likesCount", "likes")))),
    usuario = coluna(d, c("ownerUsername", "owner/username", "owner.username", "username")),
    data = coluna(d, c("timestamp", "createdAt", "date")),
    url_comentario = url_com
  ) %>%
    filter(!is.na(shortCode), !is.na(comentario_id), !is.na(texto), str_trim(texto) != "")
}

ler_arquivo_apify <- function(arquivo, nome = basename(arquivo)) {
  if (grepl("\\.json$", nome, ignore.case = TRUE)) {
    d <- fromJSON(arquivo, flatten = TRUE)
    d <- as_tibble(d) %>% mutate(across(everything(), \(x) if (is.list(x)) NA_character_ else as.character(x)))
  } else {
    d <- read_csv(arquivo, col_types = cols(.default = col_character()), show_col_types = FALSE)
  }
  normalizar_comentarios_apify(d)
}

# Grava cada postagem no seu arquivo, juntando com o que já estava salvo
# (sem repetir comentários). Devolve quantos comentários novos cada postagem ganhou.
salvar_comentarios <- function(d) {
  if (nrow(d) == 0) return(tibble(shortCode = character(), novos = integer(), total = integer()))
  dir.create(PASTA_COMENTARIOS, recursive = TRUE, showWarnings = FALSE)
  d %>%
    mutate(curtidas = as.character(curtidas)) %>%
    split(.$shortCode) %>%
    imap(\(novos, sc) {
      antigos <- ler_comentarios(sc) %>% mutate(curtidas = as.character(curtidas))
      tudo <- bind_rows(antigos, novos) %>% distinct(comentario_id, .keep_all = TRUE) %>%
        select(all_of(COLUNAS_COMENTARIOS))
      write_csv(tudo, arquivo_comentarios(sc), na = "")
      tibble(shortCode = sc, novos = nrow(tudo) - nrow(antigos), total = nrow(tudo))
    }) %>%
    bind_rows()
}

importar_comentarios_apify <- function(arquivos, nomes = basename(arquivos)) {
  map2(arquivos, nomes, ler_arquivo_apify) %>% bind_rows() %>% salvar_comentarios()
}

# ---------------------------------------------------------
# 2. Coleta direta pelo Apify (com limite de custo)
# ---------------------------------------------------------

# A chave fica só nesta pasta (config/chave_apify.txt) e pode ser apagada pelo app
carregar_chave_apify <- function() {
  if (file.exists(ARQUIVO_CHAVE_APIFY)) {
    chave <- str_trim(paste(readLines(ARQUIVO_CHAVE_APIFY, warn = FALSE), collapse = ""))
    if (nzchar(chave)) Sys.setenv(APIFY_TOKEN = chave)
  }
  invisible(Sys.getenv("APIFY_TOKEN"))
}

salvar_chave_apify <- function(chave) {
  chave <- str_trim(chave)
  stopifnot(nzchar(chave))
  dir.create(dirname(ARQUIVO_CHAVE_APIFY), showWarnings = FALSE)
  writeLines(chave, ARQUIVO_CHAVE_APIFY)
  Sys.setenv(APIFY_TOKEN = chave)
}

apagar_chave_apify <- function() {
  if (file.exists(ARQUIVO_CHAVE_APIFY)) file.remove(ARQUIVO_CHAVE_APIFY)
  Sys.unsetenv("APIFY_TOKEN")
}

tem_chave_apify <- function() nzchar(Sys.getenv("APIFY_TOKEN"))

chave_apify_mascarada <- function() {
  k <- Sys.getenv("APIFY_TOKEN")
  if (k == "") "" else paste0("••••", substr(k, nchar(k) - 3, nchar(k)))
}

# Custo máximo da coleta (US$): cada postagem traz no máximo "limite" comentários
custo_maximo_apify <- function(n_postagens, limite, preco_mil = APIFY_PRECO_MIL) {
  n_postagens * limite / 1000 * preco_mil
}

apify_req <- function(caminho) {
  token <- Sys.getenv("APIFY_TOKEN")
  if (token == "") stop("Chave do Apify não encontrada. Informe a chave na aba Comentários.", call. = FALSE)
  request(paste0(APIFY_API, caminho)) |>
    req_headers(Authorization = paste("Bearer", token)) |>
    req_timeout(120) |>
    req_retry(max_tries = 4, is_transient = \(r) resp_status(r) %in% c(429, 500, 502, 503, 504)) |>
    req_error(body = \(r) tryCatch(resp_body_json(r)$error$message, error = function(e) NULL))
}

# Inicia o ator do Apify para as postagens indicadas, espera terminar e devolve
# os comentários. O total de resultados cobrados é limitado a postagens x limite.
coletar_comentarios_apify <- function(urls, limite, preco_mil = APIFY_PRECO_MIL, ator = APIFY_ATOR,
                                      progresso = NULL, espera_maxima_min = 60) {
  urls <- unique(urls[!is.na(urls) & nzchar(urls)])
  if (length(urls) == 0) return(comentarios_vazio())
  limite <- as.integer(limite)
  maximo <- length(urls) * limite
  avisar <- function(msg) if (is.function(progresso)) progresso(msg)

  execucao <- apify_req(sprintf("acts/%s/runs", ator)) |>
    req_url_query(maxItems = maximo,
                  maxTotalChargeUsd = round(custo_maximo_apify(length(urls), limite, preco_mil) * 1.1 + 0.01, 2)) |>
    req_body_json(list(directUrls = as.list(urls), resultsLimit = limite,
                       includeNestedComments = FALSE, isNewestComments = FALSE)) |>
    req_perform() |>
    resp_body_json()
  run_id <- execucao$data$id
  dataset <- execucao$data$defaultDatasetId
  avisar(sprintf("Coleta iniciada no Apify (%d postagens, até %d comentários cada)…", length(urls), limite))

  inicio <- Sys.time()
  repeat {
    Sys.sleep(5)
    status <- apify_req(paste0("actor-runs/", run_id)) |> req_perform() |> resp_body_json()
    estado <- status$data$status
    avisar(sprintf("Apify: %s (%s)", estado, format(Sys.time() - inicio, digits = 2)))
    if (estado %in% c("SUCCEEDED", "FAILED", "ABORTED", "TIMED-OUT")) break
    if (difftime(Sys.time(), inicio, units = "mins") > espera_maxima_min) {
      stop("A coleta no Apify passou de ", espera_maxima_min, " minutos. Confira a execução no site do Apify.", call. = FALSE)
    }
  }
  if (estado != "SUCCEEDED") {
    stop("A coleta no Apify terminou com o status ", estado, ". Confira a execução no site do Apify.", call. = FALSE)
  }

  itens <- apify_req(sprintf("datasets/%s/items", dataset)) |>
    req_url_query(clean = "true", format = "json") |>
    req_timeout(600) |>
    req_perform() |>
    resp_body_string()
  d <- fromJSON(itens, flatten = TRUE)
  if (length(d) == 0) return(comentarios_vazio())
  as_tibble(d) %>%
    mutate(across(everything(), \(x) if (is.list(x)) NA_character_ else as.character(x))) %>%
    normalizar_comentarios_apify()
}

# ---------------------------------------------------------
# 3. Valência dos comentários pela IA
# ---------------------------------------------------------

ler_valencia_ia <- function() {
  if (!file.exists(ARQUIVO_VALENCIA_IA)) {
    return(tibble(comentario_id = character(), shortCode = character(), valencia_ia = character(), modelo = character()))
  }
  read_csv(ARQUIVO_VALENCIA_IA, col_types = cols(.default = col_character()), show_col_types = FALSE) %>%
    distinct(comentario_id, .keep_all = TRUE)
}

gravar_valencia_ia <- function(linhas) {
  dir.create(dirname(ARQUIVO_VALENCIA_IA), showWarnings = FALSE, recursive = TRUE)
  write_csv(linhas, ARQUIVO_VALENCIA_IA, append = file.exists(ARQUIVO_VALENCIA_IA), na = "")
}

normalizar_valencia <- function(x) {
  x <- str_to_lower(str_trim(coalesce(x, "")))
  case_when(str_starts(x, "pos") ~ "positivo", str_starts(x, "neg") ~ "negativo",
            str_starts(x, "neu") ~ "neutro", TRUE ~ NA_character_)
}

# Prompt de um lote: contexto da postagem + comentários numerados (c1, c2...)
montar_prompt_valencia <- function(post, comentarios) {
  lista <- sprintf("c%d: %s", seq_len(nrow(comentarios)),
                   str_trunc(str_squish(comentarios$texto), 500))
  ler_texto(PROMPTS$valencia) %>%
    sub("{candidato}", post$candidato %||% "", x = ., fixed = TRUE) %>%
    sub("{categorias}", coalesce(na_if(post$subcategorias %||% "", ""), "não informadas"), x = ., fixed = TRUE) %>%
    sub("{legenda}", str_trunc(str_squish(coalesce(post$caption, "")), 1500), x = ., fixed = TRUE) %>%
    sub("{comentarios}", paste(lista, collapse = "\n"), x = ., fixed = TRUE)
}

# Resposta {"c1": "positivo", ...} -> vetor de valências (NA para o que faltar)
ler_valencias <- function(resposta, n) {
  json <- str_extract(resposta %||% "", "\\{[\\s\\S]*\\}")
  lista <- if (is.na(json)) NULL else tryCatch(fromJSON(json), error = function(e) NULL)
  map_chr(seq_len(n), \(i) normalizar_valencia(lista[[paste0("c", i)]] %||% NA_character_))
}

# Classifica os comentários ainda sem valência de uma postagem
# post: uma linha da base (candidato, caption, subcategorias, shortCode)
classificar_valencia_postagem <- function(post, modelo = MODELO_PADRAO, progresso = NULL) {
  com <- ler_comentarios(post$shortCode)
  feitos <- ler_valencia_ia()$comentario_id
  pendentes <- com %>% filter(!comentario_id %in% feitos)
  if (nrow(pendentes) == 0) return(0L)
  lotes <- split(pendentes, ceiling(seq_len(nrow(pendentes)) / COMENTARIOS_POR_LOTE))
  total <- 0L
  for (lote in lotes) {
    valencias <- rep(NA_character_, nrow(lote))
    # Até 3 tentativas para os comentários que voltarem sem resposta válida
    for (tentativa in 1:3) {
      faltam <- which(is.na(valencias))
      if (length(faltam) == 0) break
      resposta <- chamar_ia(montar_prompt_valencia(post, lote[faltam, ]), modelo)
      valencias[faltam] <- ler_valencias(resposta, length(faltam))
    }
    ok <- !is.na(valencias)
    if (any(ok)) {
      gravar_valencia_ia(tibble(comentario_id = lote$comentario_id[ok], shortCode = post$shortCode,
                                valencia_ia = valencias[ok], modelo = modelo,
                                classificado_em = format(Sys.time(), "%Y-%m-%dT%H:%M:%S")))
    }
    total <- total + sum(ok)
    if (is.function(progresso)) progresso(sum(ok))
  }
  total
}

# ---------------------------------------------------------
# 4. Validação humana
# ---------------------------------------------------------

ler_validacao_comentarios <- function() {
  if (!file.exists(ARQUIVO_VALENCIA_VALIDACAO)) {
    return(tibble(comentario_id = character(), shortCode = character(), valencia_final = character(),
                  avaliador = character(), validado_em = character()))
  }
  read_csv(ARQUIVO_VALENCIA_VALIDACAO, col_types = cols(.default = col_character()), show_col_types = FALSE) %>%
    arrange(validado_em) %>%
    group_by(comentario_id) %>% slice_tail(n = 1) %>% ungroup()
}

salvar_validacao_comentarios <- function(comentario_id, shortCode, valencia, avaliador = "") {
  dir.create(dirname(ARQUIVO_VALENCIA_VALIDACAO), showWarnings = FALSE, recursive = TRUE)
  write_csv(tibble(comentario_id, shortCode, valencia_final = valencia, avaliador = coalesce(avaliador, ""),
                   validado_em = format(Sys.time(), "%Y-%m-%dT%H:%M:%OS3", tz = "UTC")),
            ARQUIVO_VALENCIA_VALIDACAO, append = file.exists(ARQUIVO_VALENCIA_VALIDACAO), na = "")
}

# Comentários das postagens com a classificação da IA e a validação
#   valencia: a validada, se houver; senão a da IA
base_comentarios <- function(shortCodes) {
  com <- map(unique(shortCodes), ler_comentarios) %>% bind_rows()
  if (nrow(com) == 0) {
    return(comentarios_vazio() %>% mutate(valencia_ia = character(), valencia_final = character(),
                                          validado = logical(), valencia = character()))
  }
  com %>%
    left_join(ler_valencia_ia() %>% select(comentario_id, valencia_ia), by = "comentario_id") %>%
    left_join(ler_validacao_comentarios() %>% select(comentario_id, valencia_final), by = "comentario_id") %>%
    mutate(validado = !is.na(valencia_final), valencia = coalesce(valencia_final, valencia_ia))
}

# Contagem por postagem: com_pos, com_neu, com_neg (e totais)
# so_validados = TRUE usa apenas os comentários validados
valencia_por_postagem <- function(shortCodes, so_validados = FALSE) {
  b <- base_comentarios(shortCodes)
  if (so_validados) b <- b %>% mutate(valencia = valencia_final)
  b %>%
    group_by(shortCode) %>%
    summarise(com_salvos = n(), com_classificados = sum(!is.na(valencia_ia)), com_validados = sum(validado),
              com_pos = sum(valencia %in% "positivo"), com_neu = sum(valencia %in% "neutro"),
              com_neg = sum(valencia %in% "negativo"), .groups = "drop")
}

# Acrescenta à base (uma linha por postagem) as colunas com_pos, com_neu e com_neg
juntar_valencia <- function(d, so_validados = FALSE) {
  if (nrow(d) == 0) return(d %>% mutate(com_pos = integer(), com_neu = integer(), com_neg = integer()))
  v <- valencia_por_postagem(d$shortCode, so_validados) %>% select(shortCode, com_pos, com_neu, com_neg)
  d %>%
    select(-any_of(c("com_pos", "com_neu", "com_neg"))) %>%
    left_join(v, by = "shortCode") %>%
    mutate(across(c(com_pos, com_neu, com_neg), \(x) coalesce(x, 0L)))
}

# Concordância entre a IA e a validação humana (só comentários validados)
acuracia_comentarios <- function(shortCodes) {
  b <- base_comentarios(shortCodes) %>% filter(validado, !is.na(valencia_ia))
  if (nrow(b) == 0) return(NULL)
  classes <- names(VALENCIAS)
  list(
    n = nrow(b),
    acuracia = mean(b$valencia_ia == b$valencia_final),
    matriz = table(IA = factor(b$valencia_ia, classes, VALENCIAS), Validação = factor(b$valencia_final, classes, VALENCIAS)),
    por_classe = map(classes, \(cl) tibble(
      valencia = VALENCIAS[[cl]],
      ia_marcou = sum(b$valencia_ia == cl),
      confirmados = sum(b$valencia_ia == cl & b$valencia_final == cl),
      precisao = if (sum(b$valencia_ia == cl) > 0) mean(b$valencia_final[b$valencia_ia == cl] == cl) else NA_real_,
      cobertura = if (sum(b$valencia_final == cl) > 0) mean(b$valencia_ia[b$valencia_final == cl] == cl) else NA_real_
    )) %>% bind_rows()
  )
}

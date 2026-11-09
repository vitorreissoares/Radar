# ---------------------------------------------------------
# Pesquisas eleitorais (intenção de voto de agregadores)
# ---------------------------------------------------------
# O arquivo importado na aba 4 é guardado já arrumado em config/pesquisas.csv:
#   data (AAAA-MM-DD), candidato, turno (1 ou 2), intencao (%)
# O relatório compara essas séries com o índice de valência dos comentários.

ARQUIVO_PESQUISAS <- "config/pesquisas.csv"

# Lê o CSV do agregador. Aceita vírgula ou ponto e vírgula, vírgula decimal,
# datas DD/MM/AAAA ou AAAA-MM-DD e o turno no nome ("Lula (2º turno)") ou numa
# coluna "turno". Os nomes são trocados pelos da tabela de candidatos quando batem.
ler_pesquisas_arquivo <- function(arquivo, candidatos = character()) {
  primeira <- readLines(arquivo, n = 1, warn = FALSE, encoding = "UTF-8")
  delim <- if (str_count(primeira, ";") > str_count(primeira, ",")) ";" else ","
  bruto <- read_delim(arquivo, delim = delim, col_types = cols(.default = col_character()),
                      locale = locale(encoding = "UTF-8"), show_col_types = FALSE, trim_ws = TRUE)
  names(bruto) <- normalizar_nome(names(bruto))
  achar <- function(...) { n <- intersect(c(...), names(bruto)); if (length(n)) n[1] else NA_character_ }
  col_data <- achar("data", "date", "dia")
  col_cand <- achar("candidato", "candidate", "nome")
  col_int <- achar("intencao", "intencao de voto", "intencao_voto", "voto", "valor", "percentual", "%")
  col_turno <- achar("turno", "round")
  if (anyNA(c(col_data, col_cand, col_int))) {
    stop("O arquivo precisa das colunas data, candidato e intencao (encontradas: ",
         paste(names(bruto), collapse = ", "), ").")
  }

  datas <- bruto[[col_data]]
  data <- suppressWarnings(coalesce(dmy(datas, quiet = TRUE), ymd(datas, quiet = TRUE)))
  intencao <- bruto[[col_int]] %>% str_remove_all("[%\\s]") %>%
    { ifelse(str_detect(., ","), str_replace_all(str_remove_all(., "\\.(?=\\d{3}(\\D|$))"), ",", "."), .) } %>%
    as.numeric() %>% suppressWarnings()
  nome_bruto <- bruto[[col_cand]]
  turno_nome <- str_match(nome_bruto, "(\\d)\\s*[ºo°]?\\s*turno")[, 2]
  turno <- as.integer(coalesce(if (!is.na(col_turno)) str_extract(bruto[[col_turno]], "\\d") else NA_character_,
                               turno_nome, "1"))
  candidato <- nome_bruto %>% str_remove("\\s*[\\(\\[-]?\\s*\\d\\s*[ºo°]?\\s*turno\\s*[\\)\\]]?") %>% str_squish()

  d <- tibble(data, candidato, turno, intencao) %>% filter(!is.na(data), !is.na(intencao), nzchar(candidato))
  if (nrow(d) == 0) stop("Nenhuma linha válida (confira as datas e os números de intenção de voto).")
  d %>%
    mutate(candidato = casar_candidato(candidato, candidatos)) %>%
    group_by(data, candidato, turno) %>% summarise(intencao = mean(intencao), .groups = "drop") %>%
    arrange(turno, candidato, data)
}

# "Lula" -> "Lula"; "Flavio Bolsonaro" -> "Flávio Bolsonaro"; "Luiz Inácio Lula da Silva" -> "Lula"
casar_candidato <- function(nomes, candidatos = character()) {
  info <- tryCatch(ler_candidatos_info(), error = function(e) tibble(id = character(), nome = character()))
  alvos <- unique(c(candidatos, info$nome))
  if (!length(alvos)) return(nomes)
  chave <- normalizar_nome(alvos)
  ids <- normalizar_nome(info$id)
  map_chr(nomes, \(n) {
    k <- normalizar_nome(n)
    i <- match(k, chave)
    if (is.na(i)) i <- match(k, ids) %>% { if (is.na(.)) NA else match(info$nome[.], alvos) }
    if (is.na(i)) i <- which(map_lgl(chave, \(a) str_detect(k, fixed(a)) || str_detect(a, fixed(k))))[1]
    if (is.na(i)) i <- which(map_lgl(chave, \(a) any(str_split_1(a, " ") %in% str_split_1(k, " ")[nchar(str_split_1(k, " ")) > 3])))[1]
    if (is.na(i)) n else alvos[i]
  })
}

ler_pesquisas <- function() {
  if (!file.exists(ARQUIVO_PESQUISAS)) return(tibble(data = as.Date(character()), candidato = character(),
                                                       turno = integer(), intencao = numeric()))
  read_csv(ARQUIVO_PESQUISAS, col_types = cols(data = col_date(), candidato = col_character(),
                                               turno = col_integer(), intencao = col_double()),
           show_col_types = FALSE)
}

salvar_pesquisas <- function(d) {
  dir.create(dirname(ARQUIVO_PESQUISAS), showWarnings = FALSE, recursive = TRUE)
  write_csv(d %>% mutate(data = as.character(data)), ARQUIVO_PESQUISAS, na = "")
}

apagar_pesquisas <- function() if (file.exists(ARQUIVO_PESQUISAS)) file.remove(ARQUIVO_PESQUISAS)

# Pesquisas de intenção de voto: as colunas de intenção do arquivo de desempenho
# (ou, em projetos antigos, o config/pesquisas.csv)
pesquisas_do_desempenho <- function(perf = ler_performance()) {
  perf %>% filter(eh_intencao(metrica)) %>%
    transmute(data, candidato, turno = coalesce(as.integer(turno), 1L), intencao = valor)
}

pesquisas_js <- function(p = NULL) {
  if (is.null(p)) {
    p <- pesquisas_do_desempenho()
    if (nrow(p) == 0) p <- ler_pesquisas()
  }
  if (nrow(p) == 0) return(list())
  p %>% mutate(data = as.character(data)) %>% transpose()
}

# ---------------------------------------------------------
# Desempenho dos candidatos (performance.csv)
# ---------------------------------------------------------
# Uma linha por data e candidato e uma coluna por métrica, por exemplo:
#   data,candidato,intencao_voto,seguidores_ig
#   05/08/2026,Lula,"40,3",15300000
# Também aceita o formato longo: data,candidato,metrica,valor.
# Fica guardado em config/performance.csv (formato longo).

ARQUIVO_PERFORMANCE <- "config/performance.csv"

numero_br <- function(x) {
  x <- str_remove_all(as.character(x), "[%\\s]")
  # "15.300.000" ou "15.300.000,5": ponto de milhar; "40,3": vírgula decimal
  milhar <- str_detect(x, "^-?\\d{1,3}(\\.\\d{3})+(,\\d+)?$")
  x[milhar] <- str_remove_all(x[milhar], "\\.")
  x <- str_replace(x, ",", ".")
  # 15,3M / 2.2K
  mult <- case_when(str_detect(x, "(?i)m$") ~ 1e6, str_detect(x, "(?i)k$|mil$") ~ 1e3, TRUE ~ 1)
  suppressWarnings(as.numeric(str_remove(x, "(?i)(m|k|mil)$")) * mult)
}

ler_performance_arquivo <- function(arquivo, candidatos = character()) {
  primeira <- readLines(arquivo, n = 1, warn = FALSE, encoding = "UTF-8")
  delim <- if (str_count(primeira, ";") > str_count(primeira, ",")) ";" else ","
  bruto <- read_delim(arquivo, delim = delim, col_types = cols(.default = col_character()),
                      locale = locale(encoding = "UTF-8"), show_col_types = FALSE, trim_ws = TRUE)
  originais <- names(bruto)
  names(bruto) <- normalizar_nome(names(bruto))
  if (!all(c("data", "candidato") %in% names(bruto))) {
    stop("O arquivo precisa das colunas data e candidato (encontradas: ", paste(originais, collapse = ", "), ").")
  }
  if (!"turno" %in% names(bruto)) bruto$turno <- NA_character_
  longo <- if (all(c("metrica", "valor") %in% names(bruto))) {
    bruto %>% select(data, candidato, turno, metrica, valor)
  } else {
    outras <- setdiff(names(bruto), c("data", "candidato", "turno"))
    if (!length(outras)) stop("O arquivo não tem colunas de métricas além de data e candidato.")
    rotulos <- set_names(originais[match(outras, names(bruto))], outras)
    bruto %>% pivot_longer(all_of(outras), names_to = "metrica", values_to = "valor") %>%
      mutate(metrica = unname(rotulos[metrica]))
  }
  regex_turno <- "(\\d)\\s*[ºo°]?\\s*(turno|t)\\b"
  d <- longo %>%
    mutate(
      # O turno pode vir numa coluna, no nome do candidato ("Lula (2º turno)") ou no da métrica ("intencao_2turno")
      turno = as.integer(coalesce(str_extract(turno, "\\d"),
                                  str_match(candidato, regex_turno)[, 2],
                                  str_match(str_replace_all(metrica, "_", " "), regex_turno)[, 2])),
      candidato = str_squish(str_remove(candidato, "\\s*[\\(\\[-]?\\s*\\d\\s*[ºo°]?\\s*turno\\s*[\\)\\]]?")),
      metrica = str_squish(str_remove(str_replace_all(metrica, "_", " "), regex_turno)) %>% str_replace_all(" ", "_"),
      data = suppressWarnings(coalesce(dmy(data, quiet = TRUE), ymd(data, quiet = TRUE))),
      valor = numero_br(valor), candidato = casar_candidato(candidato, candidatos)) %>%
    filter(!is.na(data), !is.na(valor), nzchar(candidato))
  if (nrow(d) == 0) stop("Nenhuma linha válida (confira as datas e os números).")
  # Intenção de voto sem turno indicado: 1º turno
  d <- d %>% mutate(turno = if_else(is.na(turno) & eh_intencao(metrica), 1L, turno))
  d %>% group_by(data, candidato, turno, metrica) %>% summarise(valor = mean(valor), .groups = "drop") %>%
    arrange(metrica, turno, candidato, data)
}

eh_intencao <- function(metrica) str_detect(normalizar_nome(metrica), "intenc|^voto|vote|intention")

ler_performance <- function() {
  if (!file.exists(ARQUIVO_PERFORMANCE)) return(tibble(data = as.Date(character()), candidato = character(),
                                                         turno = integer(), metrica = character(), valor = numeric()))
  read_csv(ARQUIVO_PERFORMANCE, col_types = cols(data = col_date(), candidato = col_character(), turno = col_integer(),
                                                 metrica = col_character(), valor = col_double()),
           show_col_types = FALSE) %>%
    garantir_coluna("turno")
}

salvar_performance <- function(d) {
  dir.create(dirname(ARQUIVO_PERFORMANCE), showWarnings = FALSE, recursive = TRUE)
  write_csv(d %>% mutate(data = as.character(data)), ARQUIVO_PERFORMANCE, na = "")
}

apagar_performance <- function() if (file.exists(ARQUIVO_PERFORMANCE)) file.remove(ARQUIVO_PERFORMANCE)

performance_js <- function(p = ler_performance()) {
  if (nrow(p) == 0) return(list())
  p %>% mutate(metrica = if_else(!is.na(turno), paste0(metrica, " · ", turno, "º turno"), metrica),
               data = as.character(data)) %>%
    select(data, candidato, metrica, valor) %>% transpose()
}

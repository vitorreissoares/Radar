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

pesquisas_js <- function(p = ler_pesquisas()) {
  if (nrow(p) == 0) return(list())
  p %>% mutate(data = as.character(data)) %>% transpose()
}

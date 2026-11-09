# =========================================================
# PROJETOS (uma pasta por pesquisa)
# =========================================================
# Cada pesquisa fica numa pasta escolhida pelo pesquisador, com tudo dela:
#   config/      candidatos, textos do relatório, desempenho, períodos
#   saidas/      a rodada (categorização e validação) e o relatório
#   midia/<Candidato>/imagens | videos | audios | comentarios
#   assets/img_cand/   fotos dos candidatos
# Assim, candidatos e períodos de pesquisas diferentes nunca se misturam.
#
# A pasta de dados do programa (Documentos/Radar) guarda só o que é da pessoa:
# as chaves (OpenRouter, Apify) e a lista de projetos (config/projetos.json).
# Ela também continua funcionando como projeto, para quem já usava o Radar.
# =========================================================

ARQUIVO_PROJETOS <- function() file.path(PASTA_BASE, "config", "projetos.json")
ARQUIVO_PROJETO <- "config/projeto.json"   # dentro de cada pasta de projeto
ID_RODADA_PROJETO <- "pesquisa"            # cada projeto tem uma rodada só

ler_projetos <- function() {
  arq <- ARQUIVO_PROJETOS()
  if (!file.exists(arq)) return(list(ativo = NULL, lista = list()))
  p <- tryCatch(read_json(arq), error = function(e) list())
  list(ativo = p$ativo, lista = keep(p$lista %||% list(), \(x) !is.null(x$pasta)))
}

salvar_projetos <- function(p) {
  dir.create(dirname(ARQUIVO_PROJETOS()), showWarnings = FALSE, recursive = TRUE)
  write_json(p, ARQUIVO_PROJETOS(), auto_unbox = TRUE, pretty = TRUE, null = "null")
}

# É uma pasta de projeto (criada pelo Radar 1.6 ou depois)?
eh_projeto <- function(pasta = getwd()) file.exists(file.path(pasta, ARQUIVO_PROJETO))

info_projeto <- function(pasta = getwd()) {
  if (!eh_projeto(pasta)) {
    return(list(nome = "Pasta de dados do Radar", pasta = normalizePath(pasta, mustWork = FALSE), antigo = TRUE))
  }
  c(read_json(file.path(pasta, ARQUIVO_PROJETO)), list(pasta = normalizePath(pasta, mustWork = FALSE), antigo = FALSE))
}

# Cria a estrutura de um projeto novo. O cabeçalho e o rodapé do relatório vêm do
# projeto atual (o pesquisador costuma ser o mesmo); candidatos começam vazios.
criar_projeto <- function(pasta, nome) {
  pasta <- path.expand(pasta)
  if (!nzchar(str_trim(nome))) stop("Dê um nome ao projeto.")
  if (eh_projeto(pasta)) stop("Já existe um projeto nesta pasta. Use \"Abrir projeto\".")
  if (dir.exists(file.path(pasta, "saidas", "rodadas"))) stop("Esta pasta já tem dados do Radar. Escolha uma pasta vazia ou nova.")
  for (sub in c("config", "saidas/rodadas", "midia", "assets/img_cand")) {
    dir.create(file.path(pasta, sub), recursive = TRUE, showWarnings = FALSE)
  }
  write_json(list(nome = str_trim(nome), criado_em = format(Sys.time(), "%Y-%m-%d %H:%M")),
             file.path(pasta, ARQUIVO_PROJETO), auto_unbox = TRUE, pretty = TRUE)
  write_csv(tibble(id = character(), nome = character(), partido = character(), foto = character()),
            file.path(pasta, "config", "candidatos.csv"))
  if (file.exists(ARQUIVO_CONFIG_RELATORIO)) {
    file.copy(ARQUIVO_CONFIG_RELATORIO, file.path(pasta, ARQUIVO_CONFIG_RELATORIO))
  }
  # A foto do rodapé (do pesquisador) vai junto
  foto <- arquivo_logo()
  if (file.exists(foto)) file.copy(foto, file.path(pasta, foto))
  registrar_projeto(pasta, nome)
  normalizePath(pasta)
}

registrar_projeto <- function(pasta, nome = NULL) {
  pasta <- normalizePath(pasta, mustWork = FALSE)
  nome <- nome %||% tryCatch(info_projeto(pasta)$nome, error = function(e) basename(pasta))
  p <- ler_projetos()
  p$lista <- c(list(list(nome = nome, pasta = pasta)), discard(p$lista, \(x) identical(x$pasta, pasta)))
  p$ativo <- pasta
  salvar_projetos(p)
}

# Troca a pasta de trabalho para o projeto (o app recarrega a sessão depois)
abrir_projeto <- function(pasta) {
  pasta <- normalizePath(path.expand(pasta), mustWork = FALSE)
  if (!dir.exists(pasta)) stop("A pasta não existe: ", pasta)
  if (!eh_projeto(pasta) && !identical(pasta, normalizePath(PASTA_BASE))) {
    if (dir.exists(file.path(pasta, "saidas", "rodadas"))) {
      # Pasta de dados de uma versão antiga: vira projeto sem perder nada
      write_json(list(nome = basename(pasta), criado_em = format(Sys.time(), "%Y-%m-%d %H:%M")),
                 file.path(pasta, ARQUIVO_PROJETO), auto_unbox = TRUE, pretty = TRUE)
    } else {
      stop("Esta pasta não é um projeto do Radar. Para começar uma pesquisa nela, use \"Novo projeto\".")
    }
  }
  setwd(pasta)
  criar_pastas_midia()
  registrar_projeto(pasta)
  invisible(pasta)
}

# Ao abrir o programa: volta ao último projeto usado, se ele ainda existir
abrir_ultimo_projeto <- function() {
  ativo <- ler_projetos()$ativo
  if (!is.null(ativo) && dir.exists(ativo)) tryCatch(abrir_projeto(ativo), error = function(e) NULL)
  invisible(getwd())
}

# Nome de pasta seguro para cada candidato (mantém acentos e espaços)
pasta_candidato <- function(nome) {
  nome <- str_squish(str_replace_all(coalesce(nome, ""), "[/\\\\:*?\"<>|]", " "))
  if (nzchar(nome)) nome else "sem_candidato"
}

# ---------------------------------------------------------
# Bases importadas (.xlsx) ficam guardadas no projeto, em bases/,
# para a pesquisa poder ser reaberta depois
# ---------------------------------------------------------
ARQUIVO_BASES <- "config/bases.json"

ler_bases <- function() {
  vazio <- tibble(nome = character(), caminho = character(), candidato = character(), postagens = integer())
  if (!file.exists(ARQUIVO_BASES)) return(vazio)
  b <- tryCatch(read_json(ARQUIVO_BASES), error = function(e) list())
  if (!length(b)) return(vazio)
  map(b, \(x) tibble(nome = x$nome %||% basename(x$arquivo), caminho = normalizePath(x$arquivo, mustWork = FALSE),
                     candidato = x$candidato, postagens = as.integer(x$postagens %||% NA))) %>%
    bind_rows() %>% filter(file.exists(caminho))
}

salvar_lista_bases <- function(d) {
  dir.create("config", showWarnings = FALSE)
  rel <- map_chr(d$caminho, \(x) { r <- sub(paste0("^", str_escape(normalizePath(getwd())), "[/\\\\]?"), "", normalizePath(x, mustWork = FALSE)); r })
  write_json(map(seq_len(nrow(d)), \(i) list(nome = d$nome[i], arquivo = rel[i], candidato = d$candidato[i],
                                              postagens = d$postagens[i])),
             ARQUIVO_BASES, auto_unbox = TRUE, pretty = TRUE)
}

# Copia a planilha para bases/ e acrescenta à lista
guardar_base <- function(caminho, nome, candidato, postagens) {
  dir.create("bases", showWarnings = FALSE)
  destino <- file.path("bases", paste0(format(Sys.time(), "%Y%m%d-%H%M%S"), "_", pasta_candidato(candidato), ".xlsx"))
  file.copy(caminho, destino, overwrite = TRUE)
  d <- bind_rows(ler_bases(), tibble(nome = nome, caminho = normalizePath(destino), candidato = candidato,
                                     postagens = as.integer(postagens)))
  salvar_lista_bases(d)
  d
}

remover_base <- function(i) {
  d <- ler_bases()
  if (i >= 1 && i <= nrow(d)) {
    if (startsWith(normalizePath(d$caminho[i]), normalizePath(file.path(getwd(), "bases")))) file.remove(d$caminho[i])
    d <- d[-i, ]
  }
  salvar_lista_bases(d)
  d
}

# Cadastra ou atualiza um candidato (nome, partido e número, foto)
salvar_candidato <- function(nome, partido = NULL, foto_tmp = NULL, foto_nome = NULL) {
  info <- tryCatch(ler_candidatos_info(), error = function(e) tibble(id = character(), nome = character()))
  for (col in c("id", "nome", "partido", "intencao_voto", "seguidores_ig", "foto")) if (!col %in% names(info)) info[[col]] <- character()
  foto <- NULL
  if (!is.null(foto_tmp) && file.exists(foto_tmp)) {
    ext <- tolower(tools::file_ext(foto_nome %||% foto_tmp))
    if (ext == "jpeg") ext <- "jpg"
    base <- normalizar_nome(nome) %>% str_replace_all("[^a-z0-9]+", "_")
    foto <- paste0(base, ".", ext)
    dir.create(PASTA_FOTOS, recursive = TRUE, showWarnings = FALSE)
    file.copy(foto_tmp, file.path(PASTA_FOTOS, foto), overwrite = TRUE)
  }
  i <- match(nome, info$nome)
  if (is.na(i)) {
    info <- bind_rows(info, tibble(id = nome, nome = nome, partido = partido %||% "", intencao_voto = "", seguidores_ig = "",
                                   foto = foto %||% paste0(normalizar_nome(nome) %>% str_replace_all("[^a-z0-9]+", "_"), ".jpg")))
  } else {
    if (!is.null(partido) && nzchar(partido)) info$partido[i] <- partido
    if (!is.null(foto)) info$foto[i] <- foto
  }
  salvar_candidatos_info(info)
  invisible(info)
}

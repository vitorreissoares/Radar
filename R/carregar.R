# Carrega configurações e funções do projeto (usado pelo app e no console)
#
# PASTA_APP: onde estão os arquivos do programa (R/, prompts/, templates/...).
# No programa instalado, os dados de cada pessoa (config/, saidas/, midia/,
# assets/) ficam em outra pasta, indicada em RADAR_DADOS.
if (!exists("PASTA_APP")) PASTA_APP <- normalizePath(Sys.getenv("RADAR_APP", getwd()))
arquivo_app <- function(...) file.path(PASTA_APP, ...)

for (arquivo in c("R/config.R", "R/categorizacao.R", "R/rodadas.R", "R/validacao_remota.R",
                  "R/relatorio.R", "R/textos.R", "R/periodos.R", "R/historico.R", "R/comentarios.R", "R/pesquisas.R", "R/projetos.R")) {
  source(arquivo_app(arquivo), encoding = "UTF-8", local = environment())
}

# Passa a trabalhar na pasta de dados (se houver uma). Na primeira vez, copia para
# ela as configurações e imagens iniciais do programa, sem sobrescrever nada.
usar_pasta_dados <- function(pasta = Sys.getenv("RADAR_DADOS")) {
  if (!nzchar(pasta)) { definir_pasta_base(getwd()); return(invisible(getwd())) }
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  pessoais <- c("chave_openrouter.txt", "chave_apify.txt", "validacao_remota.json")   # nunca vêm do programa
  for (sub in c("config", "assets")) {
    origem <- arquivo_app(sub)
    if (normalizePath(origem, mustWork = FALSE) == normalizePath(file.path(pasta, sub), mustWork = FALSE)) next
    for (a in list.files(origem, recursive = TRUE)) {
      destino <- file.path(pasta, sub, a)
      if (basename(a) %in% pessoais || file.exists(destino)) next
      dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
      file.copy(file.path(origem, a), destino)
    }
  }
  setwd(pasta)
  definir_pasta_base(getwd())
  invisible(pasta)
}

# A pasta de dados do programa guarda o que é da pessoa (chaves, lista de projetos);
# o resto é de cada projeto e fica na pasta de trabalho (getwd()).
definir_pasta_base <- function(pasta = getwd()) {
  PASTA_BASE <<- normalizePath(pasta)
  ARQUIVO_CHAVE <<- file.path(PASTA_BASE, "config", "chave_openrouter.txt")
  ARQUIVO_CHAVE_APIFY <<- file.path(PASTA_BASE, "config", "chave_apify.txt")
  ARQUIVO_CONFIG_REMOTA <<- file.path(PASTA_BASE, "config", "validacao_remota.json")
  invisible(PASTA_BASE)
}
definir_pasta_base()

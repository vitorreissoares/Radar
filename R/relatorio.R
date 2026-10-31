# =========================================================
# FUNÇÕES DO RELATÓRIO
# =========================================================

# ---------------------------------------------------------
# 1. Ler a base validada e aplicar a validação humana
# ---------------------------------------------------------

# Base validada (uma linha por postagem, de base_validada_rodada) pronta para o relatório:
# só postagens já validadas, nomes completos dos candidatos e datas como Date
aplicar_validacao <- function(dados) {
  dados %>%
    garantir_coluna("visualizacoes") %>%
    filter(validada) %>%
    mutate(
      candidato = nome_completo(candidato),
      likes = as.numeric(likes),
      comentarios = as.numeric(comentarios),
      visualizacoes = suppressWarnings(as.numeric(visualizacoes)),
      data = as.Date(data),
      semana = calcular_semana(data)
    )
}

# TRUE para as postagens que têm alguma marcação final da categoria
tem_categoria <- function(d, categoria) {
  cols <- paste0("final_", SUBCATEGORIAS_TAB$chave[SUBCATEGORIAS_TAB$categoria == categoria])
  rowSums(as.matrix(d[cols]) == 1, na.rm = TRUE) > 0
}

ler_candidatos_info <- function() {
  read_csv("config/candidatos.csv", col_types = cols(.default = col_character()),
           show_col_types = FALSE)
}

# "Flavio" -> "Flávio Bolsonaro" (nomes que não estão na tabela ficam como estão)
nome_completo <- function(x) {
  info <- ler_candidatos_info()
  coalesce(info$nome[match(x, info$id)], x)
}

# ---------------------------------------------------------
# 4. Redação com IA (opcional): transforma o rascunho em texto analítico
# ---------------------------------------------------------

redigir_com_ia <- function(d, rascunho, modelo = MODELO_PADRAO, idioma = "pt") {
  postagens <- d %>%
    arrange(candidato, desc(likes)) %>%
    mutate(
      fala = if_else(texto_vazio_vetor(transcricao), "", paste0(" | Fala do vídeo: ", str_trunc(str_squish(transcricao), 300))),
      linha = sprintf("- [%s | %s | %s | %s curtidas | %s comentários] %s%s",
                      candidato, coalesce(na_if(categorias, ""), "sem categoria"),
                      coalesce(na_if(subcategorias, ""), "—"), num(likes), num(comentarios),
                      str_trunc(str_squish(coalesce(caption, "")), 500), fala)
    ) %>%
    pull(linha) %>%
    paste(collapse = "\n")

  prompt <- ler_texto(arquivo_app("prompts/relatorio.txt")) %>%
    sub("{rascunho}", rascunho, x = ., fixed = TRUE) %>%
    sub("{postagens}", postagens, x = ., fixed = TRUE)
  if (!identical(idioma, "pt")) {
    prompt <- paste0(prompt, "\n\nIMPORTANTE: escreva o texto final em ",
                     L(idioma, "português", "inglês (English)", "espanhol (español)"),
                     ", mantendo todos os números do rascunho.")
  }

  texto <- chamar_ia(prompt, modelo, timeout = 600)
  if (trimws(texto) == "") stop("A IA devolveu uma resposta vazia. Tente novamente.")
  str_trim(texto)
}

texto_vazio_vetor <- function(x) map_lgl(x %||% NA_character_, texto_vazio)

# ---------------------------------------------------------
# 5. Textos editáveis: "Sobre a pesquisa" e candidatos
# ---------------------------------------------------------

ARQUIVO_SOBRE <- "config/sobre_a_pesquisa.json"

# Lista de quadros: list(list(titulo = "...", texto = "..."), ...)
# Textos padrão (usados se o arquivo não existir ou se um quadro estiver vazio)
ARQUIVO_SOBRE_PADRAO <- "padrao/sobre_a_pesquisa.json"

vazio_txt <- function(x) is.null(x) || length(x) == 0 || all(is.na(x)) || !nzchar(str_trim(paste(x, collapse = "")))

# Um arquivo por idioma: config/sobre_a_pesquisa.json (português),
# config/sobre_a_pesquisa_en.json, config/sobre_a_pesquisa_es.json.
# Idioma ainda sem textos próprios: parte dos textos em português.
arquivo_sobre <- function(idioma = "pt") {
  if (identical(idioma, "pt")) ARQUIVO_SOBRE else sub("\\.json$", paste0("_", idioma, ".json"), ARQUIVO_SOBRE)
}

ler_sobre <- function(idioma = "pt") {
  if (!identical(idioma, "pt") && !file.exists(arquivo_sobre(idioma))) return(ler_sobre("pt"))
  padrao <- read_json(arquivo_app(ARQUIVO_SOBRE_PADRAO))
  arquivo <- arquivo_sobre(idioma)
  if (!file.exists(arquivo)) return(padrao)
  quadros <- tryCatch(read_json(arquivo), error = function(e) list())
  if (length(quadros) == 0) return(padrao)
  # Quadro sem título e sem texto (ex.: apagado por engano) volta ao texto padrão
  imap(quadros, \(q, i) {
    if (vazio_txt(q$titulo) && vazio_txt(q$texto) && i <= length(padrao)) padrao[[i]] else
      list(titulo = q$titulo %||% "", texto = q$texto %||% "")
  })
}

salvar_sobre <- function(quadros, idioma = "pt") {
  write_json(quadros, arquivo_sobre(idioma), auto_unbox = TRUE, pretty = TRUE)
}

salvar_candidatos_info <- function(info) {
  write_csv(info, "config/candidatos.csv", na = "")
}

# Inclui na tabela os candidatos da base que ainda não estão nela
completar_candidatos_info <- function(candidatos) {
  info <- ler_candidatos_info()
  novos <- setdiff(candidatos, c(info$nome, info$id))
  if (length(novos) == 0) return(info)
  info <- bind_rows(info, tibble(
    id = novos, nome = novos, partido = "", intencao_voto = "", seguidores_ig = "",
    foto = paste0(normalizar_nome(novos) %>% str_replace_all("[^a-z0-9]+", "_"), ".jpg")
  ))
  salvar_candidatos_info(info)
  info
}

# ---------------------------------------------------------
# 6. Gerar o HTML do relatório
# ---------------------------------------------------------

esc <- function(x) htmltools::htmlEscape(coalesce(x, ""))

html_cards <- function(candidatos, idioma = "pt") {
  info <- ler_candidatos_info() %>% filter(nome %in% candidatos)
  sprintf('
      <article class="candidate-card" data-candidate="%1$s" tabindex="0">
        <div class="candidate-top">
          <img class="candidate-photo" src="assets/img_cand/%2$s" alt="%7$s %1$s">
          <div>
            <h2 class="candidate-name">%1$s</h2>
            <p class="candidate-party">%3$s</p>
          </div>
        </div>
        <div class="candidate-meta">
          <div class="meta-box"><span>%8$s</span><strong>%4$s</strong></div>
          <div class="meta-box"><span>%9$s</span><strong>%5$s</strong></div>
        </div>
        <p class="candidate-info">%6$s</p>
      </article>',
    esc(info$nome), esc(info$foto), esc(info$partido),
    esc(info$intencao_voto), esc(info$seguidores_ig),
    L(idioma, "Clique para filtrar os resultados.", "Click to filter the results.", "Haga clic para filtrar los resultados."),
    L(idioma, "Foto de", "Photo of", "Foto de"),
    L(idioma, "Intenção de voto", "Voting intention", "Intención de voto"),
    L(idioma, "Seguidores IG", "IG followers", "Seguidores IG")
  ) %>% paste(collapse = "\n")
}

# Fotos usadas nos filtros e gráficos (CONFIG.candidateImages do relatório)
js_imagens_candidatos <- function() {
  info <- ler_candidatos_info()
  toJSON(as.list(set_names(paste0("assets/img_cand/", info$foto), info$nome)), auto_unbox = TRUE)
}


# Texto -> parágrafos <p> (parágrafos separados por linha em branco).
# escapar = FALSE mantém tags HTML digitadas (ex.: links <a href>)
paragrafos_html <- function(texto, estilo = NULL, escapar = TRUE) {
  paragrafos <- str_split(str_trim(texto), "\n\\s*\n")[[1]] %>% str_squish() %>% discard(~ .x == "")
  if (escapar) paragrafos <- htmltools::htmlEscape(paragrafos)
  if (is.null(estilo)) return(paste0("<p>", paragrafos, "</p>", collapse = "\n"))
  sprintf('<p style="%s">%s</p>', estilo[pmin(seq_along(paragrafos), length(estilo))], paragrafos) %>%
    paste(collapse = "\n\n")
}

html_paragrafos <- function(texto) {
  paragrafos_html(texto, estilo = c('margin:0; color:var(--muted); font-size:.8rem;',
                                    'color:var(--muted); font-size:.8rem;'))
}

# Os 7 quadros do "Sobre a pesquisa": o primeiro ocupa a largura toda, os demais em grade
html_sobre <- function(quadros, proporcao, modelo_rotulo) {
  quadro <- function(q, classe) {
    texto <- q$texto %>%
      str_replace_all(fixed("{proporcao}"), paste0(round(proporcao * 100), "%")) %>%
      str_replace_all(fixed("{modelo}"), modelo_rotulo)
    sprintf('      <div class="%s">\n        <h3>%s</h3>\n        %s\n      </div>',
            classe, esc(q$titulo), paragrafos_html(texto, escapar = FALSE))
  }
  if (length(quadros) == 0) return("")
  paste0(
    quadro(quadros[[1]], "method-card research-intro-card"), "\n",
    '      <div class="method-grid">\n',
    paste(map_chr(quadros[-1], quadro, classe = "method-card"), collapse = "\n"),
    "\n      </div>"
  )
}

# Fotos do relatório: ficam em assets/img_cand (o relatório aponta para lá).
PASTA_FOTOS <- "assets/img_cand"

# Foto do rodapé: assets/img_cand/politica-logo.jpg (ou .png, .webp, .svg);
# na falta dela, logo.* (nome usado na versão 1.2)
arquivo_logo <- function() {
  achados <- c(list.files(PASTA_FOTOS, pattern = "^politica-logo\\.(png|jpe?g|webp|svg)$", ignore.case = TRUE),
               list.files(PASTA_FOTOS, pattern = "^logo\\.(png|jpe?g|webp|svg)$", ignore.case = TRUE))
  paste0("assets/img_cand/", if (length(achados)) achados[1] else "politica-logo.jpg")
}

# ---------------------------------------------------------
# Identidade do relatório: título, subtítulo, autoria, rodapé e idioma
# (editáveis no app, aba 4 > Sobre a pesquisa; ficam em config/relatorio.json)
# ---------------------------------------------------------

ARQUIVO_CONFIG_RELATORIO <- "config/relatorio.json"

LINKS_RODAPE <- c(scholar = "Google Acadêmico", lattes = "Lattes", orcid = "ORCID",
                  github = "GitHub", linkedin = "LinkedIn")

config_relatorio_padrao <- function() {
  list(
    titulo = "Radar da Liderança Política",
    subtitulo = "",
    autoria = "Vitor Reis Soares",
    rodape_nome = "Vitor Reis Soares",
    rodape_texto = "",
    links = as.list(set_names(rep("", length(LINKS_RODAPE)), names(LINKS_RODAPE))),
    idioma = "pt"
  )
}

ler_config_relatorio <- function() {
  padrao <- config_relatorio_padrao()
  if (!file.exists(ARQUIVO_CONFIG_RELATORIO)) return(padrao)
  salvo <- tryCatch(read_json(ARQUIVO_CONFIG_RELATORIO), error = function(e) list())
  cfg <- modifyList(padrao, salvo)
  cfg$links <- modifyList(padrao$links, salvo$links %||% list())
  cfg
}

# Título, subtítulo e texto do rodapé podem ter uma versão por idioma: a de
# português fica no topo do arquivo; as outras em por_idioma$en, por_idioma$es.
CAMPOS_POR_IDIOMA <- c("titulo", "subtitulo", "rodape_texto")

textos_no_idioma <- function(cfg, idioma = cfg$idioma %||% "pt") {
  outro <- cfg$por_idioma[[idioma]]
  if (identical(idioma, "pt") || is.null(outro)) return(cfg)
  for (campo in CAMPOS_POR_IDIOMA) {
    valor <- outro[[campo]]
    # Título vazio em outro idioma: usa o de português
    if (!is.null(valor) && (campo != "titulo" || !vazio_txt(valor))) cfg[[campo]] <- valor
  }
  cfg
}

guardar_textos_idioma <- function(cfg, valores, idioma = "pt") {
  if (identical(idioma, "pt")) return(modifyList(cfg, valores))
  cfg$por_idioma <- cfg$por_idioma %||% list()
  cfg$por_idioma[[idioma]] <- modifyList(cfg$por_idioma[[idioma]] %||% list(), valores)
  cfg
}

salvar_config_relatorio <- function(cfg) {
  dir.create(dirname(ARQUIVO_CONFIG_RELATORIO), showWarnings = FALSE, recursive = TRUE)
  write_json(cfg, ARQUIVO_CONFIG_RELATORIO, auto_unbox = TRUE, pretty = TRUE)
}

ICONES_LINKS <- c(scholar = '<i class="fa-brands fa-google-scholar"></i>',
                  lattes = '<span class="icone-lattes">L</span>',
                  orcid = '<i class="fa-brands fa-orcid"></i>',
                  github = '<i class="fa-brands fa-github"></i>',
                  linkedin = '<i class="fa-brands fa-linkedin"></i>')

# Rodapé: foto (assets/img_cand/politica-logo.*), nome, ícones dos links e texto
html_rodape <- function(cfg) {
  foto <- arquivo_logo()
  links <- cfg$links %||% list()
  icones <- imap_chr(LINKS_RODAPE, \(nome, chave) {
    url <- str_trim(links[[chave]] %||% "")
    if (!nzchar(url)) return("")
    if (!grepl("^https?://", url)) url <- paste0("https://", url)
    sprintf('<a class="rodape-link" href="%s" target="_blank" rel="noopener noreferrer" title="%s" aria-label="%s">%s</a>',
            esc(url), nome, nome, ICONES_LINKS[[chave]])
  }) %>% paste(collapse = "")
  paste0(
    '<div class="rodape">',
    if (file.exists(foto)) sprintf('<img class="rodape-foto" src="%s" alt="%s">', foto, esc(cfg$rodape_nome)) else "",
    '<div class="rodape-info">',
    if (nzchar(cfg$rodape_nome %||% "")) sprintf('<strong class="rodape-nome">%s</strong>', esc(cfg$rodape_nome)) else "",
    if (nzchar(icones)) sprintf('<div class="rodape-links">%s</div>', icones) else "",
    if (nzchar(cfg$rodape_texto %||% "")) sprintf('<p class="rodape-texto">%s</p>', esc(cfg$rodape_texto)) else "",
    '</div></div>'
  )
}

# Versão "arquivo único" do relatório: troca "assets/img_cand/arquivo.jpg" pela
# própria imagem, para o HTML funcionar sozinho (usado no botão de download)
embutir_imagens <- function(html) {
  arquivos <- unique(str_match_all(html, "assets/img_cand/([^\"'()<>]+?\\.(?i:jpe?g|png|webp|svg))")[[1]][, 2])
  for (a in arquivos) {
    caminho <- file.path(PASTA_FOTOS, URLdecode(a))
    if (!file.exists(caminho)) next
    ext <- tolower(tools::file_ext(a))
    tipo <- switch(ext, png = "image/png", webp = "image/webp", svg = "image/svg+xml", "image/jpeg")
    uri <- paste0("data:", tipo, ";base64,",
                  base64_enc(readBin(caminho, "raw", file.info(caminho)$size)) %>% str_remove_all("\n"))
    html <- str_replace_all(html, fixed(paste0("assets/img_cand/", a)), uri)
  }
  html
}

# Categorias, cores e subcategorias para os gráficos do relatório
esquema_js <- function(idioma = "pt") {
  list(categorias = map(CATEGORIAS, \(cat) list(
         nome = traduzir_nome(cat, idioma), cor = unname(CORES_CATEGORIAS[[cat]]),
         subcategorias = I(traduzir_nome(SUBCATEGORIAS_TAB$rotulo[SUBCATEGORIAS_TAB$categoria == cat & SUBCATEGORIAS_TAB$subcategoria], idioma))
       )),
       coresSubcategorias = as.list(set_names(unname(CORES_SUBCATEGORIAS), traduzir_nome(names(CORES_SUBCATEGORIAS), idioma))),
       coresValencia = as.list(CORES_VALENCIA),
       corIndiceGeral = COR_INDICE_GERAL)
}

# Comentários de cada postagem: {shortCode: [positivos, neutros, negativos]}
# (d precisa das colunas com_pos, com_neu, com_neg; ver juntar_valencia)
valencia_js <- function(d) {
  if (!all(c("com_pos", "com_neu", "com_neg") %in% names(d))) return(set_names(list(), character()))
  v <- d %>% distinct(shortCode, .keep_all = TRUE) %>% filter(com_pos + com_neu + com_neg > 0)
  set_names(pmap(list(v$com_pos, v$com_neu, v$com_neg), \(a, b, c) c(a, b, c)), v$shortCode)
}

# Colunas do monitoramento.csv usado pelos relatórios
COLUNAS_RELATORIO <- c("candidato", "url", "caption", "likes", "shortCode", "comentarios", "visualizacoes",
                       "data", "semana", "categoria", "subcategoria", "formato")

# Uma linha por postagem x subcategoria final (uma postagem pode aparecer em várias linhas;
# os gráficos do relatório contam cada postagem uma vez por categoria)
csv_relatorio <- function(d, idioma = "pt") {
  longo <- para_longo(d)
  # Postagens sem nenhuma categoria entram com uma linha sem categoria: contam nos totais,
  # nos rankings, nos formatos e nos comentários, mas não nos gráficos de categorias
  sem_categoria <- d %>% filter(!shortCode %in% longo$shortCode) %>%
    mutate(categoria = "", subcategoria = "")
  bind_rows(longo, sem_categoria) %>%
    arrange(data, candidato) %>%
    # nomes no idioma do relatório (o JavaScript usa os mesmos nomes do esquema)
    mutate(categoria = traduzir_nome(categoria, idioma), subcategoria = traduzir_nome(subcategoria, idioma),
           formato = traduzir_nome(formato, idioma)) %>%
    mutate(data = as.character(data)) %>%
    select(any_of(COLUNAS_RELATORIO)) %>%
    format_csv(na = "")
}


# Gera o relatório único: todos os dados de d (base validada, uma linha por postagem),
# com os botões Semana / Mês / Ano / Tudo (o trecho mais recente da base em cada um).
# periodo_inicial é o botão que abre primeiro ("semana", "mes", "ano" ou "tudo").
# Devolve o caminho do index.html.
gerar_relatorio <- function(d, pasta = PASTA_RELATORIO, periodo_inicial = NULL,
                            proporcao = PROPORCAO_TOP_PADRAO, modelo_rotulo = MODELO_ROTULO,
                            config = ler_config_relatorio(), sobre = ler_sobre(config$idioma %||% "pt")) {
  config <- textos_no_idioma(config)

  d <- d %>% mutate(data = as.Date(data))
  template <- ler_texto(arquivo_app("templates/relatorio_template.html"))

  idioma <- config$idioma %||% "pt"
  csv <- csv_relatorio(d, idioma)
  periodos <- periodos_relatorio(d, idioma)
  json_js <- function(x) toJSON(x, auto_unbox = TRUE, null = "null") %>% str_replace_all(fixed("</"), "<\\/")
  dados_js <- paste0(
    "    window.MONITORAMENTO_CSV = ", json_js(csv), ";\n",
    "    window.PERIODOS = ", json_js(periodos), ";\n",
    "    window.PERIODO_INICIAL = ", json_js(periodo_inicial %||% ""), ";\n",
    "    window.ESQUEMA = ", json_js(esquema_js(idioma)), ";\n",
    "    window.IDIOMA = ", json_js(idioma), ";\n",
    "    window.VALENCIA = ", json_js(valencia_js(d)), ";"
  )

  # Texto inicial do cabeçalho e das considerações (o JavaScript troca ao mudar de período)
  periodo_inicial <- periodo_inicial %||% "semana"
  inicial <- periodos[[periodo_inicial]] %||% list(rotulo = "Sem dados", analise = "")

  candidatos <- unique(d$candidato)
  completar_candidatos_info(candidatos)

  html <- template %>%
    str_replace(fixed("__PERIODO__"), \(m) inicial$rotulo) %>%
    str_replace(fixed("__TITULO_PAGINA__"), \(m) esc(paste(c(config$titulo, if (nzchar(config$autoria %||% "")) config$autoria), collapse = " | "))) %>%
    str_replace(fixed("__TITULO__"), \(m) esc(config$titulo)) %>%
    str_replace(fixed("__SUBTITULO__"), \(m) esc(config$subtitulo %||% "")) %>%
    str_replace(fixed("__AUTORIA__"), \(m) esc(config$autoria %||% "")) %>%
    str_replace(fixed("__RODAPE__"), \(m) html_rodape(config)) %>%
    str_replace(fixed('<html lang="pt-BR">'), \(m) sprintf('<html lang="%s">', L(idioma, "pt-BR", "en", "es"))) %>%
    str_replace(fixed("__CARDS_CANDIDATOS__"), \(m) html_cards(candidatos, idioma)) %>%
    str_replace(fixed("__SOBRE_A_PESQUISA__"), \(m) html_sobre(sobre, proporcao, modelo_rotulo)) %>%
    str_replace(fixed("__CANDIDATE_IMAGES__"), \(m) js_imagens_candidatos()) %>%
    str_replace(fixed("__CONSIDERACOES__"), \(m) inicial$analise %||% "") %>%
    str_replace(fixed("__DADOS__"), \(m) dados_js) %>%
    adaptar_js_multirrotulo()

  dir.create(file.path(pasta, "dados"), showWarnings = FALSE, recursive = TRUE)
  arquivo <- file.path(pasta, "index.html")
  writeLines(html, arquivo, useBytes = TRUE)
  # Cópias para guardar/publicar: os dados do relatório e as fotos
  writeLines(csv, file.path(pasta, "dados", "monitoramento.csv"), useBytes = TRUE)
  if (all(c("com_pos", "com_neu", "com_neg") %in% names(d))) {
    d %>% distinct(shortCode, .keep_all = TRUE) %>%
      transmute(candidato, data = as.character(data), shortCode, url, categorias = subcategorias,
                positivos = com_pos, neutros = com_neu, negativos = com_neg,
                indice = round(indice_valencia(com_pos, com_neu, com_neg), 4)) %>%
      write_csv(file.path(pasta, "dados", "comentarios_valencia.csv"), na = "")
  }
  # As fotos vão junto, na mesma estrutura do projeto (assets/img_cand)
  fotos <- list.files(PASTA_FOTOS, pattern = "\\.(jpe?g|png|webp|svg)$", full.names = TRUE, ignore.case = TRUE)
  unlink(file.path(pasta, "img_cand"), recursive = TRUE)   # pasta da versão anterior
  if (length(fotos)) {
    dir.create(file.path(pasta, PASTA_FOTOS), showWarnings = FALSE, recursive = TRUE)
    file.copy(fotos, file.path(pasta, PASTA_FOTOS), overwrite = TRUE)
  }
  invisible(arquivo)
}

excluir_relatorio <- function(pasta = PASTA_RELATORIO) unlink(pasta, recursive = TRUE)

# ---------------------------------------------------------
# 7. Gráficos com várias subcategorias por postagem
# ---------------------------------------------------------
# O CSV dos relatórios tem uma linha por postagem x subcategoria. Nos gráficos
# de subcategorias isso é o certo; nos de categoria, curtidas, top 10 e formatos
# cada postagem deve contar uma vez. Esta função ajusta o JavaScript do relatório
# para isso. Não faz nada se o ajuste já estiver lá.

JS_FUNCOES_MULTIRROTULO <- '
    /* Uma postagem pode ter várias subcategorias (uma linha por subcategoria no CSV).
       Estas funções evitam contar a mesma postagem mais de uma vez. */
    function chavePostagem(item) {
      return item.url || [item.candidato, item.data, item.likes, item.comentarios].join("|");
    }

    function dadosPorCategoria() {
      const vistos = new Set();
      return STATE.dados.filter(item => {
        const chave = chavePostagem(item) + "|" + categoriaTipo(item.categoria);
        if (vistos.has(chave)) return false;
        vistos.add(chave);
        return true;
      });
    }

    function dadosPorPostagem() {
      const mapa = new Map();
      STATE.dados.forEach(item => {
        const chave = chavePostagem(item);
        if (!mapa.has(chave)) mapa.set(chave, { ...item, _subs: [] });
        const atual = mapa.get(chave);
        if (item.subcategoria && !atual._subs.includes(item.subcategoria)) atual._subs.push(item.subcategoria);
      });
      return [...mapa.values()].map(item => ({ ...item, subcategoria: item._subs.join(" · ") }));
    }

'

adaptar_js_multirrotulo <- function(html) {
  # Mensagem "N publicações carregadas" conta postagens, não linhas do CSV
  html <- str_replace_all(html, fixed('${STATE.dados.length.toLocaleString("pt-BR")} publicações'),
                          '${dadosPorPostagem().length.toLocaleString("pt-BR")} publicações')
  if (str_detect(html, fixed("function dadosPorCategoria()"))) return(html)

  # Troca STATE.dados por outra fonte só dentro de uma função
  trocar_em <- function(html, funcao, novo) {
    inicio <- str_locate(html, fixed(paste0("    function ", funcao, "(")))[1, "start"]
    if (is.na(inicio)) return(html)
    resto <- substr(html, inicio + 1, nchar(html))
    fim_rel <- str_locate(resto, fixed("\n    function "))[1, "start"]
    fim <- if (is.na(fim_rel)) nchar(html) else inicio + fim_rel - 1
    trecho <- substr(html, inicio, fim)
    paste0(substr(html, 1, inicio - 1),
           str_replace_all(trecho, fixed("STATE.dados"), novo),
           substr(html, fim + 1, nchar(html)))
  }
  for (f in c("criarGraficoApelos", "criarDonuts", "criarGraficoDispersao")) {
    html <- trocar_em(html, f, "dadosPorCategoria()")
  }
  for (f in c("renderizarListasEngajamento", "criarGraficoFormatos")) {
    html <- trocar_em(html, f, "dadosPorPostagem()")
  }
  # As funções auxiliares entram logo antes do primeiro gráfico
  str_replace(html, fixed("    function criarGraficoApelos("),
              \(m) paste0(JS_FUNCOES_MULTIRROTULO, "    function criarGraficoApelos("))
}

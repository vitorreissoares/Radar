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
    filter(validada) %>%
    mutate(
      candidato = nome_completo(candidato),
      likes = as.numeric(likes),
      comentarios = as.numeric(comentarios),
      data = as.Date(data),
      semana = calcular_semana(data)
    )
}

# TRUE para as postagens que têm alguma marcação final da categoria
tem_categoria <- function(d, categoria) {
  cols <- paste0("final_", SUBCATEGORIAS_TAB$chave[SUBCATEGORIAS_TAB$categoria == categoria])
  rowSums(as.matrix(d[cols]) == 1, na.rm = TRUE) > 0
}

# Nome de uma chave no texto: "autenticidade", "partido", "políticas"
rotulo_texto <- function(chave) str_to_lower(rotulo_de(chave))

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
# 2. Formatação de números e datas em português
# ---------------------------------------------------------

MESES <- c("janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho",
           "agosto", "setembro", "outubro", "novembro", "dezembro")

num <- function(x) format(round(x), big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
pct <- function(x) paste0(format(round(x, 1), nsmall = 1, decimal.mark = ",", trim = TRUE), "%")

periodo_extenso <- function(inicio, fim) {
  d1 <- day(inicio); m1 <- MESES[month(inicio)]
  d2 <- day(fim);    m2 <- MESES[month(fim)]
  if (as.Date(inicio) == as.Date(fim)) return(sprintf("%d de %s de %d", d2, m2, year(fim)))
  if (month(inicio) == month(fim)) {
    sprintf("%d a %d de %s de %d", d1, d2, m2, year(fim))
  } else {
    sprintf("%d de %s a %d de %s de %d", d1, m1, d2, m2, year(fim))
  }
}

# c("a", "b", "c") -> "a, b e c"
listar <- function(x) {
  if (length(x) <= 1) return(paste(x, collapse = ""))
  paste(paste(head(x, -1), collapse = ", "), "e", tail(x, 1))
}

# qtd(1, "postagem", "postagens") -> "1 postagem"
qtd <- function(n, singular, plural) paste(n, if (n == 1) singular else plural)

trecho <- function(legenda, n = 70) {
  t <- str_squish(coalesce(legenda, ""))
  t <- str_split_i(t, "(?<=[.!?])\\s", 1)
  if (nchar(t) > n) t <- paste0(str_trunc(t, n, ellipsis = ""), "…")
  t
}

# Nome do formato no texto: com artigo ("os vídeos") e com "de" ("dos vídeos")
FORMATOS_TEXTO <- tribble(
  ~formato,           ~nome,                          ~artigo, ~de,
  "Video",            "vídeos",                       "os",    "dos",
  "Image",            "imagens",                      "as",    "das",
  "Sidecar",          "carrosséis",                   "os",    "dos",
  "Produzido por IA", "conteúdos produzidos por IA",  "os",    "dos"
)

# ---------------------------------------------------------
# 3. Rascunho automático das Considerações Finais
#    (todos os números saem da base; trechos entre [colchetes]
#    são lembretes para completar a análise qualitativa)
# ---------------------------------------------------------

# Nome da categoria dentro da frase ("liderança", "partido", "políticas")
cat_texto <- function(categoria) str_to_lower(categoria)

# Quantas postagens de cada categoria (uma postagem pode estar em mais de uma)
contagem_categorias <- function(d) {
  map_int(set_names(CATEGORIAS), \(cat) sum(tem_categoria(d, cat)))
}

# "12 de liderança, 5 de partido e 9 de políticas"
listar_categorias <- function(n) {
  listar(sprintf("%d de %s", n, cat_texto(names(n))))
}

# Médias de curtidas/comentários das postagens de cada categoria
# (uma postagem com mais de uma categoria entra em todas as médias dela)
frase_medias <- function(d) {
  medias <- map(CATEGORIAS, \(cat) {
    x <- d[tem_categoria(d, cat), ]
    if (nrow(x) == 0) return(NULL)
    tibble(categoria = cat, n = nrow(x), likes = mean(x$likes), coment = mean(x$comentarios))
  }) %>% bind_rows()
  if (nrow(medias) < 2) {
    return(sprintf("As postagens registraram média de %s curtidas e %s comentários por publicação.",
                   num(mean(d$likes)), num(mean(d$comentarios))))
  }
  partes <- sprintf("%s curtidas e %s comentários nas de %s", num(medias$likes), num(medias$coment),
                    cat_texto(medias$categoria))
  mais_l <- medias %>% slice_max(likes, n = 1, with_ties = FALSE)
  mais_c <- medias %>% slice_max(coment, n = 1, with_ties = FALSE)
  paste0(
    sprintf("Em média, as postagens registraram %s.", listar(partes)),
    if (identical(mais_l$categoria, mais_c$categoria)) {
      sprintf(" As postagens de %s tiveram as maiores médias de curtidas e de comentários.", cat_texto(mais_l$categoria))
    } else {
      sprintf(" A maior média de curtidas foi das postagens de %s, e a de comentários, das de %s.",
              cat_texto(mais_l$categoria), cat_texto(mais_c$categoria))
    }
  )
}

paragrafo_geral <- function(d, periodo = NULL) {
  k <- n_distinct(d$candidato)
  quem <- if (k == 1) paste("de", unique(d$candidato)) else sprintf("dos %d candidatos monitorados", k)
  n <- contagem_categorias(d)
  marcadas <- map(CATEGORIAS, \(cat) tem_categoria(d, cat)) %>% reduce(`+`)
  partes <- c(
    sprintf("A análise das publicações no Instagram de %s reúne %d postagens %s, analisadas a partir da legenda, das imagens e da transcrição dos vídeos.",
            periodo %||% periodo_extenso(min(d$data), max(d$data)), nrow(d), quem),
    sprintf("Por categoria, são %s; %s.", listar_categorias(n),
            qtd(sum(marcadas > 1), "postagem combina mais de uma categoria", "postagens combinam mais de uma categoria")),
    if (sum(marcadas == 0) > 0)
      sprintf("%s em nenhuma categoria.", qtd(sum(marcadas == 0), "postagem não se encaixa", "postagens não se encaixam")),
    paragrafo_lideranca(d),
    frase_medias(d)
  )
  paste(partes, collapse = " ")
}

# Subcategorias da Liderança (Autenticidade, Competência, Humanização)
paragrafo_lideranca <- function(d) {
  s <- para_longo(d) %>% filter(chave %in% CHAVES_LIDERANCA) %>% count(chave, sort = TRUE)
  if (nrow(s) == 0) return(NULL)
  sprintf("Entre as postagens de liderança, aparecem %s.", listar(sprintf("%s (%d)", rotulo_texto(s$chave), s$n)))
}

paragrafo_candidato <- function(d, nome) {
  dc <- d %>% filter(candidato == nome)
  n <- contagem_categorias(dc)

  abertura <- sprintf("%s publicou %s no período: %s.",
                      nome, qtd(nrow(dc), "postagem analisada", "postagens analisadas"), listar_categorias(n))

  mais_curtida <- dc %>% slice_max(likes, n = 1, with_ties = FALSE)
  mais_comentada <- dc %>% slice_max(comentarios, n = 1, with_ties = FALSE)
  descreve <- function(p) if (nzchar(p$subcategorias)) paste0(" (", str_to_lower(p$subcategorias), ")") else ""
  # Postagens sem legenda (só imagem ou vídeo) são citadas pela data
  citar <- function(p) {
    t <- trecho(p$caption)
    if (nzchar(t)) sprintf("a publicação “%s”", t) else sprintf("a publicação sem legenda de %s", format(as.Date(p$data), "%d/%m"))
  }
  destaque <- sprintf("Entre os destaques, %s%s alcançou %s curtidas e %s comentários.",
                      citar(mais_curtida), descreve(mais_curtida),
                      num(mais_curtida$likes), num(mais_curtida$comentarios))
  if (mais_comentada$shortCode != mais_curtida$shortCode) {
    destaque <- paste(destaque, sprintf("A publicação com mais comentários foi %s, com %s comentários.",
                                        str_remove(citar(mais_comentada), "^a publicação "), num(mais_comentada$comentarios)))
  }

  paste(c(
    abertura,
    paragrafo_lideranca(dc),
    sprintf("[Descreva os temas das postagens de %s.]", nome),
    # Com um só candidato as médias já estão no parágrafo geral
    if (n_distinct(d$candidato) > 1) frase_medias(dc),
    destaque
  ), collapse = " ")
}

paragrafo_comparativo <- function(d) {
  if (n_distinct(d$candidato) < 2) return(NULL)
  frases <- map_chr(CATEGORIAS, \(cat) {
    prop <- d %>% mutate(tem = tem_categoria(d, cat)) %>%
      group_by(candidato) %>% summarise(p = mean(tem) * 100, n = sum(tem), .groups = "drop") %>%
      arrange(desc(p))
    if (prop$n[1] == 0) return(sprintf("Nenhum candidato publicou postagens de %s.", cat_texto(cat)))
    sprintf("%s teve a maior proporção de postagens de %s (%s).", prop$candidato[1], cat_texto(cat), pct(prop$p[1]))
  })
  paste("Em termos comparativos:", paste(frases, collapse = " "))
}

paragrafo_subcategorias <- function(d) {
  longo <- para_longo(d)
  if (nrow(longo) == 0) return(NULL)
  n_top <- min(10, nrow(d))
  top_l <- d %>% slice_max(likes, n = n_top, with_ties = FALSE)
  top_c <- d %>% slice_max(comentarios, n = n_top, with_ties = FALSE)
  dono <- top_l %>% count(candidato, sort = TRUE)
  paste(c(
    sprintf("Entre as %d publicações mais curtidas, há %s. Entre as %d mais comentadas, %s.",
            n_top, listar_categorias(contagem_categorias(top_l)), n_top, listar_categorias(contagem_categorias(top_c))),
    if (n_distinct(d$candidato) > 1)
      sprintf("%s concentra %d das %d publicações mais curtidas.", dono$candidato[1], dono$n[1], n_top)
  ), collapse = " ")
}

# Valência dos comentários: índice de 0 (todos negativos) a 1 (todos positivos).
# Neutros contam como 0,5; a média é ponderada pelo número de comentários.
indice_valencia <- function(pos, neu, neg) {
  total <- pos + neu + neg
  ifelse(total > 0, (pos + 0.5 * neu) / total, NA_real_)
}

# d precisa das colunas com_pos, com_neu, com_neg (comentários de cada postagem)
paragrafo_comentarios <- function(d) {
  if (!all(c("com_pos", "com_neu", "com_neg") %in% names(d))) return(NULL)
  d <- d %>% filter(com_pos + com_neu + com_neg > 0)
  if (nrow(d) == 0) return(NULL)
  dec <- function(x) format(round(x, 2), nsmall = 2, decimal.mark = ",")
  tot <- c(pos = sum(d$com_pos), neu = sum(d$com_neu), neg = sum(d$com_neg))
  geral <- sprintf(
    "Nos comentários analisados (%s, de %s), %s são positivos, %s neutros e %s negativos, o que resulta num índice de valência de %s (0 = todos negativos; 1 = todos positivos).",
    num(sum(tot)), qtd(nrow(d), "postagem", "postagens"), pct(tot[["pos"]] / sum(tot) * 100),
    pct(tot[["neu"]] / sum(tot) * 100), pct(tot[["neg"]] / sum(tot) * 100),
    dec(indice_valencia(tot[["pos"]], tot[["neu"]], tot[["neg"]])))
  por_chave <- map(CHAVES, \(k) {
    x <- d[d[[paste0("final_", k)]] %in% 1, ]
    if (nrow(x) == 0) return(NULL)
    tibble(chave = k, indice = indice_valencia(sum(x$com_pos), sum(x$com_neu), sum(x$com_neg)))
  }) %>% bind_rows() %>% arrange(desc(indice))
  comp <- if (nrow(por_chave) >= 2) {
    sprintf("Por categoria e subcategoria, o índice foi maior em %s e menor em %s.",
            listar(sprintf("%s (%s)", rotulo_texto(por_chave$chave[1]), dec(por_chave$indice[1]))),
            sprintf("%s (%s)", rotulo_texto(tail(por_chave$chave, 1)), dec(tail(por_chave$indice, 1))))
  }
  paste(c(geral, comp, "[Comente o tom dos comentários: elogios, críticas, ironias e temas recorrentes.]"), collapse = " ")
}

paragrafo_formatos <- function(d) {
  f <- d %>%
    group_by(formato) %>%
    summarise(n = n(), likes = mean(likes), coment = mean(comentarios), .groups = "drop") %>%
    left_join(FORMATOS_TEXTO, by = "formato") %>%
    mutate(nome = coalesce(nome, formato), artigo = coalesce(artigo, "os"), de = coalesce(de, "de"))
  princ <- f %>% slice_max(n, n = 1, with_ties = FALSE)
  if (nrow(f) == 1) {
    return(sprintf("Quanto aos formatos, todas as publicações foram %s.", princ$nome))
  }
  ordem <- function(col) {
    o <- f %>% arrange(desc(.data[[col]]))
    resto <- sprintf("%s (%s)", o$nome[-1], num(o[[col]][-1]))
    sprintf("a maior média foi %s %s, com %s por publicação, seguida por %s",
            o$de[1], o$nome[1], num(o[[col]][1]), listar(resto))
  }
  sprintf(
    "Quanto aos formatos, predominaram %s %s, que representam %s do total. Em curtidas, %s. Em comentários, %s.",
    princ$artigo, princ$nome, pct(princ$n / nrow(d) * 100), ordem("likes"), ordem("coment")
  )
}

# periodo: texto do período (ex.: "28 de setembro a 4 de outubro de 2026");
# se ficar vazio, usa a primeira e a última data da base
gerar_rascunho <- function(d, periodo = NULL) {
  ordem <- ler_candidatos_info()$nome
  candidatos <- c(intersect(ordem, unique(d$candidato)), setdiff(unique(d$candidato), ordem))
  c(
    paragrafo_geral(d, periodo),
    map_chr(candidatos, \(c) paragrafo_candidato(d, c)),
    paragrafo_comparativo(d),
    paragrafo_subcategorias(d),
    paragrafo_comentarios(d),
    paragrafo_formatos(d),
    "[Escreva aqui a análise do estilo de linguagem de cada candidato e a conclusão do período.]"
  ) %>%
    discard(is.null) %>%
    paste(collapse = "\n\n")
}

# ---------------------------------------------------------
# 4. Redação com IA (opcional): transforma o rascunho em texto analítico
# ---------------------------------------------------------

redigir_com_ia <- function(d, rascunho, modelo = MODELO_PADRAO) {
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

ler_sobre <- function() {
  padrao <- read_json(arquivo_app(ARQUIVO_SOBRE_PADRAO))
  if (!file.exists(ARQUIVO_SOBRE)) return(padrao)
  quadros <- tryCatch(read_json(ARQUIVO_SOBRE), error = function(e) list())
  if (length(quadros) == 0) return(padrao)
  # Quadro sem título e sem texto (ex.: apagado por engano) volta ao texto padrão
  imap(quadros, \(q, i) {
    if (vazio_txt(q$titulo) && vazio_txt(q$texto) && i <= length(padrao)) padrao[[i]] else
      list(titulo = q$titulo %||% "", texto = q$texto %||% "")
  })
}

salvar_sobre <- function(quadros) {
  write_json(quadros, ARQUIVO_SOBRE, auto_unbox = TRUE, pretty = TRUE)
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

html_cards <- function(candidatos) {
  info <- ler_candidatos_info() %>% filter(nome %in% candidatos)
  sprintf('
      <article class="candidate-card" data-candidate="%1$s" tabindex="0">
        <div class="candidate-top">
          <img class="candidate-photo" src="assets/img_cand/%2$s" alt="Foto de %1$s">
          <div>
            <h2 class="candidate-name">%1$s</h2>
            <p class="candidate-party">%3$s</p>
          </div>
        </div>
        <div class="candidate-meta">
          <div class="meta-box"><span>Intenção de voto</span><strong>%4$s</strong></div>
          <div class="meta-box"><span>Seguidores IG</span><strong>%5$s</strong></div>
        </div>
        <p class="candidate-info">Clique para filtrar os resultados.</p>
      </article>',
    esc(info$nome), esc(info$foto), esc(info$partido),
    esc(info$intencao_voto), esc(info$seguidores_ig)
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

# Versão "arquivo único" do relatório: troca "assets/img_cand/arquivo.jpg" pela
# própria imagem, para o HTML funcionar sozinho (usado no botão de download)
embutir_imagens <- function(html) {
  arquivos <- unique(str_match_all(html, "assets/img_cand/([^\"'()<>]+?\\.(?i:jpe?g|png|webp))")[[1]][, 2])
  for (a in arquivos) {
    caminho <- file.path(PASTA_FOTOS, URLdecode(a))
    if (!file.exists(caminho)) next
    ext <- tolower(tools::file_ext(a))
    tipo <- if (ext == "png") "image/png" else if (ext == "webp") "image/webp" else "image/jpeg"
    uri <- paste0("data:", tipo, ";base64,",
                  base64_enc(readBin(caminho, "raw", file.info(caminho)$size)) %>% str_remove_all("\n"))
    html <- str_replace_all(html, fixed(paste0("assets/img_cand/", a)), uri)
  }
  html
}

# Categorias, cores e subcategorias para os gráficos do relatório
esquema_js <- function() {
  list(categorias = map(CATEGORIAS, \(cat) list(
    nome = cat, cor = unname(CORES_CATEGORIAS[[cat]]),
    subcategorias = I(SUBCATEGORIAS_TAB$rotulo[SUBCATEGORIAS_TAB$categoria == cat & SUBCATEGORIAS_TAB$subcategoria])
  )))
}

# Comentários de cada postagem: {shortCode: [positivos, neutros, negativos]}
# (d precisa das colunas com_pos, com_neu, com_neg; ver juntar_valencia)
valencia_js <- function(d) {
  if (!all(c("com_pos", "com_neu", "com_neg") %in% names(d))) return(set_names(list(), character()))
  v <- d %>% distinct(shortCode, .keep_all = TRUE) %>% filter(com_pos + com_neu + com_neg > 0)
  set_names(pmap(list(v$com_pos, v$com_neu, v$com_neg), \(a, b, c) c(a, b, c)), v$shortCode)
}

# Colunas do monitoramento.csv usado pelos relatórios
COLUNAS_RELATORIO <- c("candidato", "url", "caption", "likes", "shortCode", "comentarios",
                       "data", "semana", "categoria", "subcategoria", "formato")

# Uma linha por postagem x subcategoria final (uma postagem pode aparecer em várias linhas;
# os gráficos do relatório contam cada postagem uma vez por categoria)
csv_relatorio <- function(d) {
  para_longo(d) %>%
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
                            sobre = ler_sobre()) {

  d <- d %>% mutate(data = as.Date(data))
  template <- ler_texto(arquivo_app("templates/relatorio_template.html"))

  csv <- csv_relatorio(d)
  periodos <- periodos_relatorio(d)
  json_js <- function(x) toJSON(x, auto_unbox = TRUE, null = "null") %>% str_replace_all(fixed("</"), "<\\/")
  dados_js <- paste0(
    "    window.MONITORAMENTO_CSV = ", json_js(csv), ";\n",
    "    window.PERIODOS = ", json_js(periodos), ";\n",
    "    window.PERIODO_INICIAL = ", json_js(periodo_inicial %||% ""), ";\n",
    "    window.ESQUEMA = ", json_js(esquema_js()), ";\n",
    "    window.VALENCIA = ", json_js(valencia_js(d)), ";"
  )

  # Texto inicial do cabeçalho e das considerações (o JavaScript troca ao mudar de período)
  periodo_inicial <- periodo_inicial %||% "semana"
  inicial <- periodos[[periodo_inicial]] %||% list(rotulo = "Sem dados", analise = "")

  candidatos <- unique(d$candidato)
  completar_candidatos_info(candidatos)

  html <- template %>%
    str_replace(fixed("__PERIODO__"), \(m) inicial$rotulo) %>%
    str_replace(fixed("__CARDS_CANDIDATOS__"), \(m) html_cards(candidatos)) %>%
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
  fotos <- list.files(PASTA_FOTOS, pattern = "\\.(jpe?g|png|webp)$", full.names = TRUE, ignore.case = TRUE)
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

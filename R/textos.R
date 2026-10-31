# =========================================================
# TEXTOS DO RELATÓRIO EM PORTUGUÊS, INGLÊS E ESPANHOL
# Números, datas, nomes das categorias e o rascunho automático
# das Considerações Finais. idioma: "pt", "en" ou "es".
# (todos os números saem da base; trechos entre [colchetes]
#  são lembretes para completar a análise qualitativa)
# =========================================================

IDIOMAS <- c(pt = "Português", en = "English", es = "Español")

# Escolhe o texto do idioma
L <- function(idioma, pt, en, es) switch(idioma %||% "pt", en = en, es = es, pt)

# ---------------------------------------------------------
# Nomes das categorias, subcategorias, formatos e valências
# ---------------------------------------------------------

NOMES_TRADUZIDOS <- tibble::tribble(
  ~pt,                 ~en,               ~es,
  "Liderança",         "Leadership",      "Liderazgo",
  "Partido",           "Party",           "Partido",
  "Políticas",         "Policies",        "Políticas",
  "Autenticidade",     "Authenticity",    "Autenticidad",
  "Competência",       "Competence",      "Competencia",
  "Humanização",       "Humanization",    "Humanización",
  "Video",             "Video",           "Video",
  "Image",             "Image",           "Imagen",
  "Sidecar",           "Carousel",        "Carrusel",
  "Produzido por IA",  "AI-generated",    "Producido por IA"
)

# Nomes dos formatos no relatório em português
FORMATOS_PT <- c("Video" = "Vídeo", "Image" = "Imagem", "Sidecar" = "Carrossel")

traduzir_nome <- function(x, idioma = "pt") {
  if (identical(idioma, "pt")) return(coalesce(unname(FORMATOS_PT[x]), x))
  i <- match(x, NOMES_TRADUZIDOS$pt)
  ifelse(is.na(i), x, NOMES_TRADUZIDOS[[idioma]][i])
}

# Nome dentro da frase ("liderança", "leadership", "liderazgo")
cat_texto <- function(categoria, idioma = "pt") str_to_lower(traduzir_nome(categoria, idioma))
rotulo_texto <- function(chave, idioma = "pt") str_to_lower(traduzir_nome(rotulo_de(chave), idioma))

# ---------------------------------------------------------
# Números e datas
# ---------------------------------------------------------

MESES <- c("janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho",
           "agosto", "setembro", "outubro", "novembro", "dezembro")
MESES_IDIOMA <- list(
  pt = MESES,
  en = c("January", "February", "March", "April", "May", "June", "July",
         "August", "September", "October", "November", "December"),
  es = c("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
         "agosto", "septiembre", "octubre", "noviembre", "diciembre")
)

num <- function(x, idioma = "pt") {
  format(round(x), big.mark = if (identical(idioma, "en")) "," else ".",
         decimal.mark = if (identical(idioma, "en")) "." else ",", scientific = FALSE, trim = TRUE)
}

pct <- function(x, idioma = "pt") {
  v <- format(round(x, 1), nsmall = 1, decimal.mark = if (identical(idioma, "en")) "." else ",", trim = TRUE)
  paste0(v, if (identical(idioma, "es")) " %" else "%")
}

dec2 <- function(x, idioma = "pt") {
  format(round(x, 2), nsmall = 2, decimal.mark = if (identical(idioma, "en")) "." else ",", trim = TRUE)
}

periodo_extenso <- function(inicio, fim, idioma = "pt") {
  inicio <- as.Date(inicio); fim <- as.Date(fim)
  m <- MESES_IDIOMA[[idioma %||% "pt"]] %||% MESES
  d1 <- day(inicio); m1 <- m[month(inicio)]; a1 <- year(inicio)
  d2 <- day(fim);    m2 <- m[month(fim)];    a2 <- year(fim)
  if (identical(idioma, "en")) {
    if (inicio == fim) return(sprintf("%s %d, %d", m2, d2, a2))
    if (a1 != a2) return(sprintf("%s %d, %d – %s %d, %d", m1, d1, a1, m2, d2, a2))
    if (month(inicio) == month(fim)) return(sprintf("%s %d–%d, %d", m2, d1, d2, a2))
    return(sprintf("%s %d – %s %d, %d", m1, d1, m2, d2, a2))
  }
  ate <- if (identical(idioma, "es")) "al" else "a"
  if (inicio == fim) return(sprintf("%d de %s de %d", d2, m2, a2))
  if (a1 != a2) return(sprintf("%d de %s de %d %s %d de %s de %d", d1, m1, a1, ate, d2, m2, a2))
  if (month(inicio) == month(fim)) return(sprintf("%d %s %d de %s de %d", d1, ate, d2, m2, a2))
  sprintf("%d de %s %s %d de %s de %d", d1, m1, ate, d2, m2, a2)
}

# c("a", "b", "c") -> "a, b e c" ("and", "y")
listar <- function(x, idioma = "pt") {
  if (length(x) <= 1) return(paste(x, collapse = ""))
  paste(paste(head(x, -1), collapse = ", "), L(idioma, "e", "and", "y"), tail(x, 1))
}

# qtd(1, "postagem", "postagens") -> "1 postagem"
qtd <- function(n, singular, plural) paste(n, if (n == 1) singular else plural)

trecho <- function(legenda, n = 70) {
  t <- str_squish(coalesce(legenda, ""))
  t <- str_split_i(t, "(?<=[.!?])\\s", 1)
  if (nchar(t) > n) t <- paste0(str_trunc(t, n, ellipsis = ""), "…")
  t
}

# Nome do formato no texto, com artigo e com "de"
FORMATOS_TEXTO <- tibble::tribble(
  ~formato,           ~idioma, ~nome,                          ~artigo, ~de,
  "Video",            "pt",    "vídeos",                       "os",    "dos",
  "Image",            "pt",    "imagens",                      "as",    "das",
  "Sidecar",          "pt",    "carrosséis",                   "os",    "dos",
  "Produzido por IA", "pt",    "conteúdos produzidos por IA",  "os",    "dos",
  "Video",            "en",    "videos",                       "",      "",
  "Image",            "en",    "images",                       "",      "",
  "Sidecar",          "en",    "carousels",                    "",      "",
  "Produzido por IA", "en",    "AI-generated content",         "",      "",
  "Video",            "es",    "videos",                       "los",   "de los",
  "Image",            "es",    "imágenes",                     "las",   "de las",
  "Sidecar",          "es",    "carruseles",                   "los",   "de los",
  "Produzido por IA", "es",    "contenidos producidos por IA", "los",   "de los"
)

# Rótulos dos períodos do relatório
TITULO_MODO_IDIOMA <- list(
  pt = c(semana = "Última semana", mes = "Último mês", ano = "Último ano", tudo = "Todo o período"),
  en = c(semana = "Last week", mes = "Last month", ano = "Last year", tudo = "Whole period"),
  es = c(semana = "Última semana", mes = "Último mes", ano = "Último año", tudo = "Todo el período")
)

# ---------------------------------------------------------
# Rascunho automático das Considerações Finais
# ---------------------------------------------------------

# Quantas postagens de cada categoria (uma postagem pode estar em mais de uma)
contagem_categorias <- function(d) {
  map_int(set_names(CATEGORIAS), \(cat) sum(tem_categoria(d, cat)))
}

# "12 de liderança, 5 de partido e 9 de políticas"
listar_categorias <- function(n, idioma = "pt") {
  listar(sprintf(L(idioma, "%d de %s", "%d on %s", "%d de %s"), n, cat_texto(names(n), idioma)), idioma)
}

# Rótulos finais de uma postagem no idioma ("competência · políticas")
rotulos_postagem <- function(p, idioma = "pt") {
  k <- CHAVES[unlist(p[paste0("final_", CHAVES)]) %in% 1]
  paste(str_to_lower(traduzir_nome(rotulo_de(k), idioma)), collapse = " · ")
}

# Médias de curtidas/comentários das postagens de cada categoria
frase_medias <- function(d, idioma = "pt") {
  medias <- map(CATEGORIAS, \(cat) {
    x <- d[tem_categoria(d, cat), ]
    if (nrow(x) == 0) return(NULL)
    tibble(categoria = cat, n = nrow(x), likes = mean(x$likes), coment = mean(x$comentarios))
  }) %>% bind_rows()
  if (nrow(medias) < 2) {
    return(sprintf(L(idioma, "As postagens registraram média de %s curtidas e %s comentários por publicação.",
                     "Posts averaged %s likes and %s comments each.",
                     "Las publicaciones registraron un promedio de %s me gusta y %s comentarios cada una."),
                   num(mean(d$likes), idioma), num(mean(d$comentarios), idioma)))
  }
  partes <- sprintf(L(idioma, "%s curtidas e %s comentários nas de %s", "%s likes and %s comments for %s posts",
                      "%s me gusta y %s comentarios en las de %s"),
                    num(medias$likes, idioma), num(medias$coment, idioma), cat_texto(medias$categoria, idioma))
  mais_l <- medias %>% slice_max(likes, n = 1, with_ties = FALSE)
  mais_c <- medias %>% slice_max(coment, n = 1, with_ties = FALSE)
  paste0(
    sprintf(L(idioma, "Em média, as postagens registraram %s.", "On average, posts received %s.",
              "En promedio, las publicaciones registraron %s."), listar(partes, idioma)),
    if (identical(mais_l$categoria, mais_c$categoria)) {
      sprintf(L(idioma, " As postagens de %s tiveram as maiores médias de curtidas e de comentários.",
                " Posts on %s had the highest average likes and comments.",
                " Las publicaciones de %s tuvieron los mayores promedios de me gusta y de comentarios."),
              cat_texto(mais_l$categoria, idioma))
    } else {
      sprintf(L(idioma, " A maior média de curtidas foi das postagens de %s, e a de comentários, das de %s.",
                " The highest average likes came from %s posts, and the highest average comments from %s posts.",
                " El mayor promedio de me gusta fue de las publicaciones de %s, y el de comentarios, de las de %s."),
              cat_texto(mais_l$categoria, idioma), cat_texto(mais_c$categoria, idioma))
    }
  )
}

paragrafo_geral <- function(d, periodo = NULL, idioma = "pt") {
  k <- n_distinct(d$candidato)
  quem <- if (k == 1) paste(L(idioma, "de", "by", "de"), unique(d$candidato)) else
    sprintf(L(idioma, "dos %d candidatos monitorados", "by the %d candidates monitored", "de los %d candidatos monitoreados"), k)
  n <- contagem_categorias(d)
  marcadas <- map(CATEGORIAS, \(cat) tem_categoria(d, cat)) %>% reduce(`+`)
  partes <- c(
    sprintf(L(idioma,
              "A análise das publicações no Instagram de %s reúne %d postagens %s, analisadas a partir da legenda, das imagens e da transcrição dos vídeos.",
              "The analysis of Instagram posts from %s covers %d posts %s, analyzed through captions, images and video transcripts.",
              "El análisis de las publicaciones en Instagram del %s reúne %d publicaciones %s, analizadas a partir del texto, las imágenes y la transcripción de los videos."),
            periodo %||% periodo_extenso(min(d$data), max(d$data), idioma), nrow(d), quem),
    sprintf(L(idioma, "Por categoria, são %s; %s.", "By category: %s; %s.", "Por categoría, son %s; %s."),
            listar_categorias(n, idioma),
            qtd(sum(marcadas > 1),
                L(idioma, "postagem combina mais de uma categoria", "post combines more than one category", "publicación combina más de una categoría"),
                L(idioma, "postagens combinam mais de uma categoria", "posts combine more than one category", "publicaciones combinan más de una categoría"))),
    if (sum(marcadas == 0) > 0)
      sprintf(L(idioma, "%s em nenhuma categoria.", "%s into any category.", "%s en ninguna categoría."),
              qtd(sum(marcadas == 0),
                  L(idioma, "postagem não se encaixa", "post does not fit", "publicación no encaja"),
                  L(idioma, "postagens não se encaixam", "posts do not fit", "publicaciones no encajan"))),
    paragrafo_lideranca(d, idioma),
    frase_medias(d, idioma)
  )
  paste(partes, collapse = " ")
}

# Subcategorias da Liderança (Autenticidade, Competência, Humanização)
paragrafo_lideranca <- function(d, idioma = "pt") {
  s <- para_longo(d) %>% filter(chave %in% CHAVES_LIDERANCA) %>% count(chave, sort = TRUE)
  if (nrow(s) == 0) return(NULL)
  sprintf(L(idioma, "Entre as postagens de liderança, aparecem %s.", "Among leadership posts: %s.",
            "Entre las publicaciones de liderazgo, aparecen %s."),
          listar(sprintf("%s (%d)", rotulo_texto(s$chave, idioma), s$n), idioma))
}

paragrafo_candidato <- function(d, nome, idioma = "pt") {
  dc <- d %>% filter(candidato == nome)
  n <- contagem_categorias(dc)
  abertura <- sprintf(L(idioma, "%s publicou %s no período: %s.", "%s published %s in the period: %s.",
                        "%s publicó %s en el período: %s."),
                      nome, qtd(nrow(dc), L(idioma, "postagem analisada", "analyzed post", "publicación analizada"),
                                L(idioma, "postagens analisadas", "analyzed posts", "publicaciones analizadas")),
                      listar_categorias(n, idioma))

  mais_curtida <- dc %>% slice_max(likes, n = 1, with_ties = FALSE)
  mais_comentada <- dc %>% slice_max(comentarios, n = 1, with_ties = FALSE)
  descreve <- function(p) { r <- rotulos_postagem(p, idioma); if (nzchar(r)) paste0(" (", r, ")") else "" }
  prefixo <- L(idioma, "a publicação ", "the post ", "la publicación ")
  # Postagens sem legenda (só imagem ou vídeo) são citadas pela data
  citar <- function(p) {
    t <- trecho(p$caption)
    if (nzchar(t)) return(sprintf("%s“%s”", prefixo, t))
    data <- format(as.Date(p$data), if (identical(idioma, "en")) "%m/%d" else "%d/%m")
    sprintf(L(idioma, "a publicação sem legenda de %s", "the post without caption from %s", "la publicación sin texto del %s"), data)
  }
  destaque <- sprintf(L(idioma, "Entre os destaques, %s%s alcançou %s curtidas e %s comentários.",
                        "Among the highlights, %s%s reached %s likes and %s comments.",
                        "Entre los destacados, %s%s alcanzó %s me gusta y %s comentarios."),
                      citar(mais_curtida), descreve(mais_curtida),
                      num(mais_curtida$likes, idioma), num(mais_curtida$comentarios, idioma))
  if (mais_comentada$shortCode != mais_curtida$shortCode) {
    destaque <- paste(destaque, sprintf(L(idioma, "A publicação com mais comentários foi %s, com %s comentários.",
                                          "The most commented post was %s, with %s comments.",
                                          "La publicación con más comentarios fue %s, con %s comentarios."),
                                        str_remove(citar(mais_comentada), paste0("^", prefixo)),
                                        num(mais_comentada$comentarios, idioma)))
  }

  paste(c(
    abertura,
    paragrafo_lideranca(dc, idioma),
    sprintf(L(idioma, "[Descreva os temas das postagens de %s.]", "[Describe the topics of %s's posts.]",
              "[Describa los temas de las publicaciones de %s.]"), nome),
    # Com um só candidato as médias já estão no parágrafo geral
    if (n_distinct(d$candidato) > 1) frase_medias(dc, idioma),
    destaque
  ), collapse = " ")
}

paragrafo_comparativo <- function(d, idioma = "pt") {
  if (n_distinct(d$candidato) < 2) return(NULL)
  frases <- map_chr(CATEGORIAS, \(cat) {
    prop <- d %>% mutate(tem = tem_categoria(d, cat)) %>%
      group_by(candidato) %>% summarise(p = mean(tem) * 100, n = sum(tem), .groups = "drop") %>%
      arrange(desc(p))
    if (prop$n[1] == 0) {
      return(sprintf(L(idioma, "Nenhum candidato publicou postagens de %s.", "No candidate published %s posts.",
                       "Ningún candidato publicó publicaciones de %s."), cat_texto(cat, idioma)))
    }
    sprintf(L(idioma, "%s teve a maior proporção de postagens de %s (%s).", "%s had the highest share of %s posts (%s).",
              "%s tuvo la mayor proporción de publicaciones de %s (%s)."),
            prop$candidato[1], cat_texto(cat, idioma), pct(prop$p[1], idioma))
  })
  paste(L(idioma, "Em termos comparativos:", "In comparative terms:", "En términos comparativos:"),
        paste(frases, collapse = " "))
}

paragrafo_subcategorias <- function(d, idioma = "pt") {
  longo <- para_longo(d)
  if (nrow(longo) == 0) return(NULL)
  n_top <- min(10, nrow(d))
  top_l <- d %>% slice_max(likes, n = n_top, with_ties = FALSE)
  top_c <- d %>% slice_max(comentarios, n = n_top, with_ties = FALSE)
  dono <- top_l %>% count(candidato, sort = TRUE)
  paste(c(
    sprintf(L(idioma, "Entre as %d publicações mais curtidas, há %s. Entre as %d mais comentadas, %s.",
              "Among the %d most liked posts: %s. Among the %d most commented: %s.",
              "Entre las %d publicaciones con más me gusta, hay %s. Entre las %d más comentadas, %s."),
            n_top, listar_categorias(contagem_categorias(top_l), idioma),
            n_top, listar_categorias(contagem_categorias(top_c), idioma)),
    if (n_distinct(d$candidato) > 1)
      sprintf(L(idioma, "%s concentra %d das %d publicações mais curtidas.", "%s accounts for %d of the %d most liked posts.",
                "%s concentra %d de las %d publicaciones con más me gusta."), dono$candidato[1], dono$n[1], n_top)
  ), collapse = " ")
}

# Valência dos comentários: índice de 0 (todos negativos) a 1 (todos positivos).
# Neutros contam como 0,5; a média é ponderada pelo número de comentários.
indice_valencia <- function(pos, neu, neg) {
  total <- pos + neu + neg
  ifelse(total > 0, (pos + 0.5 * neu) / total, NA_real_)
}

# Índice de um conjunto de postagens, com intervalo de confiança de 95%.
# - Cada comentário vale 1 (positivo), 0,5 (neutro) ou 0 (negativo); o índice é a média
#   desses valores sobre todos os comentários (estimador de razão: soma ÷ total).
# - Comentários da mesma postagem não são independentes. O erro-padrão é o robusto por
#   postagem (linearização de Taylor do estimador de razão); se ele ficar menor que o
#   erro-padrão simples (comentários independentes), usa-se o simples, por cautela.
# - O intervalo usa a distribuição t com (postagens - 1) graus de liberdade, a correção
#   usual quando há poucos grupos (postagens).
# - Para o índice geral, cada postagem entra uma vez só, mesmo que esteja em várias
#   categorias: assim nenhum comentário é contado duas vezes.
indice_ic <- function(pos, neu, neg) {
  t <- pos + neu + neg
  ok <- !is.na(t) & t > 0
  pos <- pos[ok]; neu <- neu[ok]; t <- t[ok]
  n <- sum(t); m <- length(t)
  if (n == 0) return(list(indice = NA_real_, inf = NA_real_, sup = NA_real_, n = 0, m = 0))
  y <- pos + 0.5 * neu
  r <- sum(y) / n
  ep_simples <- sqrt(max(0, (sum(pos) + 0.25 * sum(neu)) / n - r^2) / n)
  ep_robusto <- if (m >= 2) sqrt(m / (m - 1) * sum((y - r * t)^2)) / n else 0
  ep <- max(ep_simples, ep_robusto)
  # Com poucas postagens, usa a distribuição t com (postagens - 1) graus de liberdade
  z <- if (m >= 2) qt(0.975, df = m - 1) else 1.96
  list(indice = r, inf = max(0, r - z * ep), sup = min(1, r + z * ep), n = n, m = m)
}

# d precisa das colunas com_pos, com_neu, com_neg (comentários de cada postagem)
paragrafo_comentarios <- function(d, idioma = "pt") {
  if (!all(c("com_pos", "com_neu", "com_neg") %in% names(d))) return(NULL)
  d <- d %>% filter(com_pos + com_neu + com_neg > 0)
  if (nrow(d) == 0) return(NULL)
  tot <- c(pos = sum(d$com_pos), neu = sum(d$com_neu), neg = sum(d$com_neg))
  geral <- indice_ic(d$com_pos, d$com_neu, d$com_neg)
  texto_geral <- sprintf(
    L(idioma,
      "Nos comentários analisados (%s, de %s), %s são positivos, %s neutros e %s negativos, o que resulta num índice geral de valência de %s (intervalo de confiança de 95%%: %s a %s; 0 = todos negativos, 1 = todos positivos).",
      "In the comments analyzed (%s, from %s), %s are positive, %s neutral and %s negative, resulting in an overall valence index of %s (95%% confidence interval: %s to %s; 0 = all negative, 1 = all positive).",
      "En los comentarios analizados (%s, de %s), el %s son positivos, el %s neutros y el %s negativos, lo que resulta en un índice general de valencia de %s (intervalo de confianza del 95 %%: %s a %s; 0 = todos negativos, 1 = todos positivos)."),
    num(sum(tot), idioma),
    qtd(nrow(d), L(idioma, "postagem", "post", "publicación"), L(idioma, "postagens", "posts", "publicaciones")),
    pct(tot[["pos"]] / sum(tot) * 100, idioma), pct(tot[["neu"]] / sum(tot) * 100, idioma),
    pct(tot[["neg"]] / sum(tot) * 100, idioma),
    dec2(geral$indice, idioma), dec2(geral$inf, idioma), dec2(geral$sup, idioma))
  por_chave <- map(CHAVES, \(k) {
    x <- d[d[[paste0("final_", k)]] %in% 1, ]
    if (nrow(x) == 0) return(NULL)
    tibble(chave = k, indice = indice_valencia(sum(x$com_pos), sum(x$com_neu), sum(x$com_neg)))
  }) %>% bind_rows() %>% arrange(desc(indice))
  comp <- if (nrow(por_chave) >= 2) {
    sprintf(L(idioma, "Por categoria e subcategoria, o índice foi maior em %s e menor em %s.",
              "By category and subcategory, the index was highest for %s and lowest for %s.",
              "Por categoría y subcategoría, el índice fue mayor en %s y menor en %s."),
            sprintf("%s (%s)", rotulo_texto(por_chave$chave[1], idioma), dec2(por_chave$indice[1], idioma)),
            sprintf("%s (%s)", rotulo_texto(tail(por_chave$chave, 1), idioma), dec2(tail(por_chave$indice, 1), idioma)))
  }
  paste(c(texto_geral, comp,
          L(idioma, "[Comente o tom dos comentários: elogios, críticas, ironias e temas recorrentes.]",
            "[Comment on the tone of the comments: praise, criticism, irony and recurring themes.]",
            "[Comente el tono de los comentarios: elogios, críticas, ironías y temas recurrentes.]")),
        collapse = " ")
}

paragrafo_formatos <- function(d, idioma = "pt") {
  nomes <- FORMATOS_TEXTO %>% filter(idioma == !!idioma) %>% select(-idioma)
  f <- d %>%
    group_by(formato) %>%
    summarise(n = n(), likes = mean(likes), coment = mean(comentarios), .groups = "drop") %>%
    left_join(nomes, by = "formato") %>%
    mutate(nome = coalesce(nome, formato), artigo = coalesce(artigo, ""), de = coalesce(de, ""))
  princ <- f %>% slice_max(n, n = 1, with_ties = FALSE)
  junta <- function(...) str_squish(paste(...))
  if (nrow(f) == 1) {
    return(sprintf(L(idioma, "Quanto aos formatos, todas as publicações foram %s.", "As for formats, all posts were %s.",
                     "En cuanto a los formatos, todas las publicaciones fueron %s."), princ$nome))
  }
  ordem <- function(col) {
    o <- f %>% arrange(desc(.data[[col]]))
    resto <- sprintf("%s (%s)", o$nome[-1], num(o[[col]][-1], idioma))
    sprintf(L(idioma, "a maior média foi %s, com %s por publicação, seguida por %s",
              "the highest average was for %s, with %s per post, followed by %s",
              "el mayor promedio fue %s, con %s por publicación, seguido por %s"),
            junta(o$de[1], o$nome[1]), num(o[[col]][1], idioma), listar(resto, idioma))
  }
  sprintf(
    L(idioma, "Quanto aos formatos, predominaram %s, que representam %s do total. Em curtidas, %s. Em comentários, %s.",
      "As for formats, %s predominated, accounting for %s of the total. In likes, %s. In comments, %s.",
      "En cuanto a los formatos, predominaron %s, que representan el %s del total. En me gusta, %s. En comentarios, %s."),
    junta(princ$artigo, princ$nome), pct(princ$n / nrow(d) * 100, idioma), ordem("likes"), ordem("coment")
  )
}

# periodo: texto do período (ex.: "28 de setembro a 4 de outubro de 2026");
# se ficar vazio, usa a primeira e a última data da base
gerar_rascunho <- function(d, periodo = NULL, idioma = "pt") {
  ordem <- ler_candidatos_info()$nome
  candidatos <- c(intersect(ordem, unique(d$candidato)), setdiff(unique(d$candidato), ordem))
  c(
    paragrafo_geral(d, periodo, idioma),
    map_chr(candidatos, \(c) paragrafo_candidato(d, c, idioma)),
    paragrafo_comparativo(d, idioma),
    paragrafo_subcategorias(d, idioma),
    paragrafo_comentarios(d, idioma),
    paragrafo_formatos(d, idioma),
    L(idioma, "[Escreva aqui a análise do estilo de linguagem de cada candidato e a conclusão do período.]",
      "[Write here the analysis of each candidate's language style and the conclusion for the period.]",
      "[Escriba aquí el análisis del estilo de lenguaje de cada candidato y la conclusión del período.]")
  ) %>%
    discard(is.null) %>%
    paste(collapse = "\n\n")
}

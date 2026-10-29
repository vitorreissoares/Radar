# Inicia o Radar para o programa de computador (chamado pelo Electron).
# RADAR_APP: pasta do programa · RADAR_DADOS: pasta de dados
# RADAR_PORTA: porta local que a janela do programa vai abrir
options(shiny.launch.browser = FALSE, warn = 1)
porta <- as.integer(Sys.getenv("RADAR_PORTA", "8765"))
pasta_app <- Sys.getenv("RADAR_APP")

# O app é carregado como objeto (e não como pasta) para que o Shiny não troque
# a pasta de trabalho: tudo o que o app grava vai para a pasta de dados
app <- source(file.path(pasta_app, "app.R"), local = new.env(), encoding = "UTF-8")$value
cat("Radar: dados em", getwd(), "\n")
shiny::runApp(app, port = porta, host = "127.0.0.1", launch.browser = FALSE)

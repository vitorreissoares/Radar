// Abre o app num navegador (como a janela do programa faz) e passa pelas quatro abas,
// conferindo que a sessão não cai (a "sombra" cinza de desconexão do Shiny).
// Uso: node testar_janela.js http://127.0.0.1:PORTA
const { chromium } = require("playwright");

(async () => {
  const url = process.argv[2];
  const navegador = await chromium.launch();
  const pagina = await navegador.newPage({ viewport: { width: 1400, height: 900 } });
  const erros = [];
  pagina.on("pageerror", e => erros.push(e.message));
  await pagina.goto(url);
  await pagina.waitForTimeout(8000);
  const caiu = () => pagina.evaluate(() => !!document.getElementById("shiny-disconnected-overlay"));
  let falhou = false;
  for (const aba of ["categorizacao", "validacao", "comentarios", "relatorio"]) {
    await pagina.click(`a[data-value="${aba}"]`);
    await pagina.waitForTimeout(4000);
    const c = await caiu();
    console.log(`Aba ${aba}: ${c ? "A SESSÃO CAIU" : "ok"}`);
    if (c) falhou = true;
  }
  if (erros.length) console.log("Erros na página:", erros.join(" | "));
  await navegador.close();
  process.exit(falhou ? 1 : 0);
})().catch(e => { console.log("Falha no teste da janela:", e.message); process.exit(1); });

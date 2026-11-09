// Ponte entre a janela do Radar e o programa: permite abrir a janela do sistema
// para escolher uma pasta (onde salvar cada projeto).
const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("radar", {
  escolherPasta: titulo => ipcRenderer.invoke("escolher-pasta", titulo)
});

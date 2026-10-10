# Validação do 1.3.0 — vídeo de demonstração para a App Review

Em 10/10/2026 a Apple respondeu ao envio do 1.3.0 (2) para iOS com a guideline **2.1 — Information Needed** (Submission ID `99434e86-e883-4321-a2a8-2542b9bc48e7`). Não é uma nova recusa por 4.3: eles pedem um vídeo da versão 1.3.0 rodando num **iPhone físico** (não simulador), mostrando todas as funções e todo pedido de permissão do sistema. Provavelmente é para confirmar que o app é real e funciona, porque a conta ainda está sendo analisada pelo 4.3.

A gravação precisa ser feita no próprio aparelho. Um vídeo do teste automatizado (`integration_test/`) não serve, porque não mostraria o build 1.3.0 (2) que a Apple analisou.

Os textos para a Apple (a linha do campo Notes e a resposta no App Review) estão em `assets/store_media/listing/demo_video.txt`, que o git ignora, com o marcador `<LINK DO VÍDEO>` no lugar do link.

## Antes de gravar

- **Instale o 1.3.0 (2) pelo TestFlight.** Apague o app antes, para ele abrir limpo e com o histórico de senhas vazio. Se o build não aparecer, adicione-o ao grupo interno "Casa".
- **Ative o Não Perturbe**, deixe o celular em retrato e grave sem microfone. Narração não é obrigatória.
- **Copie esta lista no app Notas.** Ela serve para mostrar o pedido "Permitir Colar", a única permissão que o app pode disparar:

  ```
  123.456.789-09
  11.222.333/0001-80
  111.111.111-11
  12.ABC.345/01DE-35
  ```

  São um CPF válido, um CNPJ com dígito verificador errado (o certo é `-81`), um CPF com todos os dígitos repetidos e o CNPJ alfanumérico de exemplo da Receita.

## Roteiro (cerca de 3 minutos, sem pressa entre os toques)

1. **Abertura:** ligue a gravação de tela pela Central de Controle. Abra o TestFlight e mostre "1.3.0 (2)", depois volte à tela inicial e toque em "Massa Teste".
2. **CPF:** mude a quantidade para 10, escolha SP em "Estado de emissão", ligue e desligue "Com pontuação" e toque em **Gerar**. Depois **Copiar**, e por fim **Exportar → CSV**, salvando em Arquivos.
3. **CNPJ:** gere os do tipo Numérico, depois os Alfanuméricos, desmarque "Matriz" (filiais) e exporte em **JSON**.
4. **Validar:** toque em "Ver exemplo" e role pelos resultados. Limpe, toque em **Colar** e depois em **"Permitir Colar"**. A Apple pediu explicitamente para mostrar os pedidos de permissão. Role pelas explicações de cada linha.
5. **Mais → UUID v4:** gere e copie.
6. **Mais → Cron:** escolha um item de "Exemplos", digite uma expressão e mostre "Próximas execuções". Digite uma inválida para aparecer o erro.
7. **Mais → Lorem:** troque entre Palavras, Parágrafos e Listas, mude a quantidade e a opção "Começar com Lorem ipsum", e gere.
8. **Mais → Senha:** mude o tamanho e as opções, gere duas ou três, mostre **Recentes** e use **Limpar**.
9. **Mais → QR Code:** digite um link, mude "Correção de erros" e use **Download → salvar PNG**.
10. **Final:** abra o app Arquivos e mostre o CSV, o JSON e o PNG salvos. Pare a gravação.

## Depois de gravar

1. Passe o vídeo para o Mac por AirDrop.
2. Converta para MP4 H.264, que abre em qualquer navegador e fica menor:

   ```sh
   ffmpeg -i entrada.MOV -c:v libx264 -crf 23 -preset slow -pix_fmt yuv420p -movflags +faststart -an massa-de-teste-1.3.0-demo.mp4
   ```

3. Suba o vídeo num bucket S3 (pelo AWS MCP) para ter um link público. **Não coloque o vídeo no repositório.**
4. Troque `<LINK DO VÍDEO>` em `assets/store_media/listing/demo_video.txt` pelo link e coloque a linha do vídeo no **topo do campo Notes** (App Review Information). As notas atuais têm cerca de 3.400 caracteres e ficam com uns 3.600, abaixo do limite de 4.000.
5. Envie a resposta em **App Review** no App Store Connect, colando o texto do mesmo arquivo. A API não responde mensagens da Apple, então isso é feito à mão.

A resposta diz que o app pode ser analisado sem o vídeo, porque não tem login nem configuração especial. A Apple avisa que, se o app só puder ser analisado com vídeo, vai pedir um novo vídeo a cada envio. Essa frase ajuda a evitar isso.

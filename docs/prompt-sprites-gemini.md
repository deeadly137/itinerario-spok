# Prompt para o Gemini — sprites dos jogadores

Cole o bloco abaixo no Gemini (Nano Banana / gerador de imagem). Ele foi feito
para devolver arquivos que caem direto no jogo, sem precisar editar nada.

Antes de gerar, veja a seção **Como manter o estilo igual** e o **Checklist**
no fim deste arquivo.

---

## PROMPT (copie daqui)

Preciso de **9 sprites de personagem** para um jogo mobile 2D (Godot) sobre
acidificação dos oceanos, inspirado em Among Us. São criaturas marinhas
antropomórficas e cientistas mergulhadores, todos fofos e amigáveis (é um jogo
educativo, para escola — nada de assustador, nada de realista).

### Especificação técnica (obrigatória)

- **1 PNG por personagem**, com **canal alfa** e **fundo 100% transparente**.
- **512×512 px**, quadrado. O jogo reduz para ~46 px na tela.
- Personagem **centralizado**, ocupando cerca de **85% da altura** do quadrado
  (deixe uma margem transparente pequena e igual dos quatro lados).
- **Não** monte folha de sprite / grade: eu preciso de um arquivo por personagem.
- **Sem** sombra no chão, **sem** moldura, **sem** texto, **sem** marca d'água,
  **sem** cenário ou chão.
- Cada personagem deve ser desenhado **inteiro** (cabeça + corpo + pés), sem
  cortar nada nas bordas.

### Câmera e estilo

- Vista **de cima levemente inclinada (top-down 3/4)** — a câmera do jogo olha
  o mapa de cima. O personagem deve estar "de frente para o observador",
  **nunca desenhado de lado**, porque o sprite **nunca gira** no jogo.
- **Cartoon chapado**: contorno escuro grosso (3–4 px na escala 512) com
  transparência, formas simples e arredondadas.
- **Cel shading de 1 tom**: cor base + **uma** sombra mais escura. Luz vindo de
  **cima e da esquerda**. Sem gradientes, sem textura granulada, sem brilhos
  complexos.
- Cada personagem precisa ser reconhecível **pela silhueta** a 46 px. Vale mais
  a forma do que o detalhe miúdo.
- No jogo, atrás de cada personagem é desenhado um **halo circular na cor
  dominante** dele. Então a cor dominante do sprite deve ser exatamente a cor
  indicada abaixo, para o halo e o personagem combinarem.

### Os 9 personagens (com o nome exato do arquivo)

**Animais — criaturas marinhas fofas, de pé, antropomórficas:**

1. `pteropode.png` — cor dominante **#5BC8E8** (azul-claro). É a "borboleta do
   mar": concha cônica fina presa ao corpo e um par de nadadeiras/asas claras.
   Na história a concha está **corroída pela acidez** — desenhe a concha com
   furinhos e rachaduras discretos, sem deixar feio.
2. `polipo.png` — **#FF7B9C** (rosa). Pólipo de coral: corpo cilíndrico rosa com
   uma coroa de tentáculos curtos e rechonchudos no topo da cabeça.
3. `alga.png` — **#7BE495** (verde). Alga marinha: corpo verde-samambaia com
   folhas onduladas saindo do topo (tipo um "cabelo" de folhas).
4. `ostra.png` — **#D9C8FF** (lilás). Ostra: concha bivalve arredondada e
   entreaberta, com uma pérola clara aparecendo dentro.
5. `plancton.png` — **#FFE066** (amarelo). Plâncton: bolinha fofa amarela com
   cílios/espinhos curtos em volta e um olho grande e simpático.
6. `caranguejo.png` — **#FF9A5C** (laranja). Caranguejo: corpo oval laranja,
   duas pinças grandes e quatro patinhas curtas.

**Cientistas — humanos em traje de mergulho/pesquisa:**

Os três usam **o mesmo traje** (capacete com visor azul-claro, corpo do traje,
botas), mudando só o tom e um detalhe de identidade:

7. `cientista1.png` — traje **#E8E8E8** (branco); detalhe: antena curta no
   capacete.
8. `cientista2.png` — traje **#C9C9C9** (cinza-claro); detalhe: viseira
   arredondada maior.
9. `cientista3.png` — traje **#A8A8A8** (cinza-médio); detalhe: mochila/tanque
   de ar visível nas costas.

*(Opcional)* `player.png` — um personagem genérico (cientista de traje branco),
usado como reserva quando nenhum dos 9 está disponível.

---

## Como manter o estilo igual entre os 9

Gerar 9 imagens separadas costuma sair com estilos diferentes. Faça assim:

1. Gere **primeiro** o `pteropode.png` e aprove só a versão que ficou boa.
2. Nas próximas, mande **junto a imagem aprovada** e escreva:
   *"Use exatamente este estilo, esta espessura de contorno, este ângulo de
   câmera e esta paleta. Agora faça o POLVO DE CORAL (item 2 da lista)."*
3. Repita, sempre anexando a mesma referência.

### Se o Gemini não conseguir fundo transparente

Peça o fundo em **cor sólida chroma-key**, por exemplo *"fundo magenta puro
#FF00FF, sem gradiente e sem sombra no chão"*. Me avise: eu removo o fundo,
recorto a margem e corto a folha em 9 arquivos automaticamente.

### Se eu preferir a folha única (uma imagem só)

Peça: *"uma grade 3×3, um personagem por célula, fundo magenta puro #FF00FF,
mesma escala e mesmo alinhamento em todas as células, sem linhas de grade,
sem números, sem texto"*. Também resolvo com um script.

---

## Checklist antes de me mandar

- [ ] São 9 arquivos PNG, um por personagem, com transparência de verdade.
- [ ] Nome de arquivo **exatamente** igual ao da lista (tudo minúsculo, sem
      acento): `pteropode.png`, `polipo.png`, `alga.png`, `ostra.png`,
      `plancton.png`, `caranguejo.png`, `cientista1.png`, `cientista2.png`,
      `cientista3.png`.
- [ ] Teste de miniatura: reduza para 46 px (ou olhe de longe) — ainda dá para
      saber qual bicho é? Se virou borrão, peça uma versão mais simples.
- [ ] Todos com o mesmo ângulo de câmera (de cima, de frente para o
      observador), mesma espessura de contorno, mesma direção de luz.
- [ ] Sem chão, sem moldura, sem texto, sem sombra projetada.

**Onde salvar:**

```
godot/assets/img/animals/     -> pteropode, polipo, alga, ostra, plancton, caranguejo
godot/assets/img/scientists/  -> cientista1, cientista2, cientista3
```

Depois é só me avisar que eu rodo o import, reconstruo o APK e os sprites
aparecem **no mapa e no lobby**.

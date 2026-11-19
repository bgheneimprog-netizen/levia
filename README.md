# levia.

Diagnóstico completo e plano de treino, nutrição e saúde até a linha de chegada: corrida, triathlon, duathlon, HYROX, ciclismo, natação, esportes de raquete ou emagrecimento.

- Diagnóstico em 7 passos (objetivo, saúde/PAR-Q, o que você já pratica, teste de força, rotina e estilo de vida)
- Plano periodizado semana a semana, com treinos completos (séries, repetições, carga, descanso e ilustração de cada exercício)
- Avatar 3D com a sua altura e o seu peso
- Nutrição, peso e IMC, exames, equipamentos e estratégia de prova

Os dados de cada pessoa ficam só no navegador dela (localStorage). Nada é enviado a servidor.

## Como publicar

É um site estático: basta servir esta pasta (GitHub Pages, Netlify, Vercel…). Para testar localmente:

```
python3 -m http.server 8000
```

e abra http://localhost:8000

## Créditos e licenças

- **Corpo 3D:** base mesh, targets e esqueleto do [MakeHuman](http://www.makehumancommunity.org) — CC0 (`levia-body.json`).
- **Ilustrações dos exercícios** (`ex/`): [Everkinetic](https://github.com/everkinetic/data) — [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Imagens redimensionadas.
- **Bibliotecas** (carregadas por CDN): three.js (MIT), pdf.js (Apache 2.0), fontes Google Fonts (OFL).

Este app orienta, mas não substitui avaliação médica, nutricional ou de um profissional de educação física.

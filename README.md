# Altar

App de macOS que lembra você de fazer o devocional ao longo do dia e guarda uma página para cada dia: versículo, horário em que você fez, o que escreveu, notas ditadas pelo microfone e orações gravadas em áudio.

Tudo roda e fica salvo no seu Mac. Sem login, sem nuvem.

Site: https://danielgacioly.github.io/altar-app (pasta `docs/`).

## Como funciona

- O Altar fica só como um ícone de livro na barra de menus.
- A cada 30 minutos de uso do Mac (teclado ou mouse), aparece uma notificação com uma pergunta e um versículo.
- Botões da notificação:
  - **Sim**: marca o dia como feito e silencia até o dia virar.
  - **Não**: espera mais um intervalo de uso.
  - **Me lembra em 15 min**: o próximo lembrete vem mais cedo.
  - **Botão extra** (opcional): aparece só nos dias e horários que você escolher, com o nome e o efeito que quiser. Exemplo: "Estou na faculdade" de segunda a quinta, das 17h às 21h, silenciando até o fim do horário.
- Tela bloqueada ou Mac dormindo não contam como uso. O modo Foco do macOS é respeitado.
- A janela (menu do ícone > Abrir o Altar) tem as telas **Hoje**, **Histórico**, **Plantas**, **Mensagens**, **Ajustes** e **Minha conta**.
- Na primeira abertura, uma tela de boas-vindas apresenta o app e pede seu nome.

## Plantas

Cada mês do ano tem uma árvore: ipê-amarelo, palmeira, oliveira, cerejeira, cedro do Líbano, flamboyant, araucária, ipê-roxo, jacarandá, cipreste, figueira e pinheiro. Cada devocional do mês faz a árvore crescer, e no fim do mês ela é colhida do tamanho que chegou (15 devocionais num mês de 30 dias deixam a árvore pela metade). Os meses que ainda não chegaram aparecem em preto e branco.

## Minha conta

A conta é só local: nome, foto e um resumo dos seus devocionais. Dali você exporta um backup (.zip com tudo, inclusive os áudios) e restaura em outro Mac.

## Tudo é configurável

Em **Ajustes** você muda:

- de quanto em quanto tempo vem o lembrete, quanto tempo o "Me lembra" adia e depois de quanto tempo parado o Mac deixa de contar como uso;
- a hora em que o dia vira e o horário sem lembretes (por exemplo, de madrugada);
- os botões extras: nome, efeito (silenciar até o fim do horário, por alguns minutos ou até o dia virar) e em que dias e horários aparecem;
- as faixas do dia e as frases de cada uma.

Os versículos são editados na tela **Versículos**.

## Requisitos

- macOS 26 ou mais novo.
- Xcode 26 ou mais novo para compilar.

## Como instalar

1. Clone o repositório e abra `Altar.xcodeproj` no Xcode.
2. Escolha **Product > Archive**, depois **Distribute App > Copy App**, ou simplesmente rode com **Product > Run** e copie o `Altar.app` gerado para a pasta Aplicativos.
3. Abra o Altar pela pasta Aplicativos. Ele pede permissão para notificações e passa a abrir junto com o login.
4. Em **Ajustes do Sistema > Notificações > Altar**, escolha o estilo **Alertas**, para a notificação ficar na tela até você responder.

O microfone e o reconhecimento de fala só são pedidos na primeira vez que você ditar uma nota ou gravar uma oração. A transcrição acontece no próprio Mac; na primeira vez o macOS pode baixar o modelo de português.

Pelo terminal, com o Xcode instalado:

```bash
xcodebuild -project Altar.xcodeproj -scheme Altar -configuration Release -derivedDataPath build build
cp -R build/Build/Products/Release/Altar.app /Applications/
```

## Onde ficam os dados

`~/Library/Application Support/Altar/`

- `ajustes.json`: suas configurações
- `versiculos.json`: sua lista de versículos
- `dias/`: uma página por dia
- `oracoes/`: os áudios das orações (AAC)
- `registro.jsonl`: cada lembrete e cada resposta, usado no Histórico
- `perfil.json` e `foto.png`: nome e foto da sua conta

## Para quem vai mexer no código

O projeto é gerado com [XcodeGen](https://github.com/yonaskolb/XcodeGen) a partir do `project.yml`. Depois de mudar arquivos ou ajustes do projeto:

```bash
xcodegen
```

Para testar os lembretes sem esperar, abra o app com o tempo acelerado (cada "minuto" vira 2 segundos):

```bash
open build/Build/Products/Debug/Altar.app --args -segundosPorMinuto 2
```

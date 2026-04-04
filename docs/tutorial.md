# Tutorial MeloOS

Este tutorial mostra o fluxo completo para construir, publicar, instalar e manter uma imagem personalizada do MeloOS.

## 1. Preparar o ambiente

Pré-requisitos:

- Fedora ou outro sistema Linux compatível com Podman/bootc/just
- acesso a um registro de imagens, como GHCR
- conta GitHub com permissão para publicar pacotes

Obs.: no Fedora 43, o stack do Hyprland é obtido via COPR no build do projeto, então o fluxo já inclui isso na imagem final.

Instale as ferramentas necessárias no host de desenvolvimento e entre no ambiente de trabalho:

```bash
just install
distrobox enter dev-java
distrobox enter dev-node
```

Use `dev-java` para tarefas com SDKMAN e `dev-node` para validar o stack Node. O host continua limpo; o desenvolvimento acontece nos containers.

## 2. Construir a imagem personalizada

Edite os arquivos de build do projeto e gere a imagem com:

```bash
just build your-user/meloos custom
```

Esse comando monta a imagem bootc do projeto usando o contexto atual e produz uma imagem pronta para publicação.

## 3. Publicar no GHCR

Depois de construir a imagem, envie-a para o GitHub Container Registry:

```bash
podman push localhost/your-user/meloos:custom ghcr.io/your-user/meloos:custom
```

Se preferir um fluxo mais seguro, publique também uma tag imutável, como `stable`, ou use digest após o push.

Exemplo de uso posterior:

```bash
sudo bootc switch ghcr.io/your-user/meloos:custom
```

## 4. Gerar ISO, QCOW2 e RAW

O repositório já expõe os alvos para artefatos de instalação e VM:

```bash
just build-iso ghcr.io/your-user/meloos custom
just build-qcow2 ghcr.io/your-user/meloos custom
just build-raw ghcr.io/your-user/meloos custom
```

- **ISO**: instalação em PC real ou VM
- **QCOW2**: máquinas virtuais
- **RAW**: gravação direta em disco ou mídia

Os artefatos são gerados em `output/`.

## 5. Instalar em um PC real

1. Grave a ISO em um pendrive.
2. Inicialize o computador pela mídia.
3. Siga o instalador gráfico/bootc do projeto.
4. No primeiro boot do sistema instalado, finalize a configuração com:

```bash
just install
```

Esse passo aplica os pacotes do host, configura Flatpak, prepara os containers `dev-java` e `dev-node` e também aplica o perfil de dotfiles inspirado no HyprLuna.

O perfil inclui configs para Hyprland, Waybar, Kitty, Wofi, Dunst, Hyprpaper, Hyprlock, Hypridle e um placeholder leve para AGS.
Ele é original, pensado para Fedora 43, e não copia o projeto HyprLuna arquivado.

Para detalhes de uso, backup e personalização, veja [docs/dotfiles.md](dotfiles.md).

Para personalizar, edite os arquivos em `dotfiles/hyprluna/home` e rode novamente `just install` ou `scripts/apply-dotfiles.sh`.

O script faz backup dos arquivos conflitantes em `~/.local/state/meloos-install/dotfiles-backup` e evita apagar dados do usuário sem necessidade.

## 6. Trocar um sistema existente para a imagem customizada

Em um MeloOS já instalado, a troca para a sua imagem é direta:

```bash
sudo bootc switch ghcr.io/your-user/meloos:custom
systemctl reboot
```

Após reiniciar, o sistema passa a acompanhar a nova imagem do registro.

## 7. Reverter se algo der errado

Se a nova imagem não funcionar como esperado, volte para a implantação anterior:

```bash
sudo bootc rollback
systemctl reboot
```

Depois do reboot, valide o estado com:

```bash
bootc status
```

## 8. Uso diário

Para trabalhar no ambiente de desenvolvimento, entre nos containers quando precisar:

```bash
distrobox enter dev-java
distrobox enter dev-node
```

Fluxo recomendado:

1. construir com `just build`
2. publicar no GHCR
3. gerar `ISO`, `QCOW2` e `RAW`
4. instalar ou alternar o sistema com `bootc switch`
5. usar `bootc rollback` se necessário

Isso mantém o host reproduzível e facilita atualizações futuras.

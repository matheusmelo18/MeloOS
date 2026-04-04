# Dotfiles do MeloOS

Este perfil é a base visual e de atalhos do desktop do MeloOS.
Ele é inspirado no HyprLuna, mas foi adaptado para o MeloOS e para o Fedora 43.

> Aviso: o projeto original HyprLuna está arquivado; aqui usamos um perfil próprio, compatível com o fluxo do MeloOS.

## O que este perfil inclui

- Hyprland
- Waybar
- Kitty
- Wofi
- Dunst
- Hyprpaper
- Hyprlock
- Hypridle
- um placeholder leve para AGS

## Onde os configs ficam no repositório

Os arquivos vivem em:

- `dotfiles/hyprluna/home`
- `dotfiles/hyprluna/README.md`

Exemplo: `dotfiles/hyprluna/home/.config/hypr/hyprland.conf`.

## Como são aplicados na instalação

Durante `just install`, o script `scripts/apply-dotfiles.sh` copia o conteúdo de `dotfiles/hyprluna/home` para a home do usuário.
O processo faz parte do fluxo padrão do MeloOS, depois da preparação do host e dos Flatpaks.

## Como personalizar depois da instalação

Edite os arquivos dentro de `dotfiles/hyprluna/home` e rode novamente:

```bash
just install
```

Se preferir, você também pode reaplicar direto com:

```bash
scripts/apply-dotfiles.sh
```

## Como reaplicar depois

Reaplique sempre que quiser voltar ao estado do repositório:

```bash
just install
```

Isso mantém o perfil consistente após alterações locais, novos testes ou troca de máquina.

## Como funcionam os backups

Se já existir um arquivo no destino e ele for diferente do arquivo do repositório, o instalador cria backup antes de sobrescrever.

Os backups vão para:

```bash
~/.local/state/meloos-install/dotfiles-backup
```

## Galeria / catálogo de dotfiles

Referências úteis para explorar setups e ideias de Hyprland:

- [Hyprland Wiki: Preconfigured setups](https://wiki.hypr.land/Getting-Started/Preconfigured-setups/)
- [Awesome Omarchy](https://awesome-omarchy.com/)
- [Hyprland Wiki](https://wiki.hypr.land/)

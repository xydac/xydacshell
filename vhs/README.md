# vhs/

Scripted terminal recordings built with [VHS](https://github.com/charmbracelet/vhs).

## Render

```bash
# install VHS once (macOS)
brew install vhs

# render the demo to a gif
cd ~/.xydacshell      # or wherever this repo lives
vhs vhs/demo.tape     # outputs vhs/demo.gif

# optional: render an mp4 alongside
vhs vhs/demo.tape --publish   # or edit the tape to add Output demo.mp4
```

The tape uses a real zsh instance and your actual `$HOME` to produce an honest demo. If you'd rather hide your home-dir contents, edit the `Setup` block in `demo.tape` to `cd /tmp` or set a different working dir first.

## Tapes

- `demo.tape` — ~25 s showcase: `x` help → `x storage --top 5` → `x doctor --no-prompt`.

# xydacshell demo — rendered with https://github.com/charmbracelet/vhs
#
# Build: vhs vhs/demo.tape
# Output: vhs/demo.gif

Output vhs/demo.gif

Set Shell "zsh"
Set FontSize 14
Set Width 1100
Set Height 700
Set Padding 22
Set TypingSpeed 40ms
Set Theme "Catppuccin Mocha"

# Setup: put $XYDACSHELL_HOME/bin on PATH so `x` resolves in this demo shell.
# Hidden from the recording — the viewer sees a clean terminal to start.
Hide
Type "export XYDACSHELL_HOME=$(pwd)"
Enter
Type "export PATH=$XYDACSHELL_HOME/bin:$PATH"
Enter
Type "clear"
Enter
Sleep 500ms
Show

# Act 1: the command surface.
Type "# xydacshell — one command, short and sharp:"
Enter
Sleep 1200ms
Type "x"
Enter
Sleep 5s

Type "clear"
Enter
Sleep 400ms

# Act 2: the storage report — the real win.
Type "# where did all my disk go?"
Enter
Sleep 1200ms
Type "x storage --top 5"
Enter
Sleep 7s

Type "clear"
Enter
Sleep 400ms

# Act 3: doctor — self-diagnose + upgrade offer.
Type "# what's my install state?"
Enter
Sleep 1200ms
Type "x doctor --no-prompt"
Enter
Sleep 6s

# Fade out.
Sleep 1s

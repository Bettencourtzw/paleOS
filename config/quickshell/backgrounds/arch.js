.pragma library
// The Arch logo (same art as the screensaver and login screen) as points.
const ART = [
"                  -`",
"                 .o+`",
"                `ooo/",
"               `+oooo:",
"              `+oooooo:",
"              -+oooooo+:",
"            `/:-:++oooo+:",
"           `/++++/+++++++:",
"          `/++++++++++++++:",
"         `/+++ooooooooooooo/`",
"        ./ooosssso++osssssso+`",
"       .oossssso-````/ossssss+`",
"      -osssssso.      :ssssssso.",
"     :osssssss/        osssso+++.",
"    /ossssssss/        +ssssooo/-",
"  `/ossssso+/:-        -:/+osssso+-",
" `+sso+:-`                 `.-/+oso:",
"`++:.                           `-/+/",
".`                                 `"]
// Points in a unit box: x 0..1, y 0..1 (aspect-correct for ~0.55 wide cells), plus density 0..1.
function points() {
    const W = 36, H = ART.length, out = [], dens = ".`-:/+os"
    for (let y = 0; y < H; y++) for (let x = 0; x < ART[y].length; x++) {
        const c = ART[y][x]; if (c === " ") continue
        out.push({ x: x / W, y: y / (H - 1), d: Math.max(0, dens.indexOf(c)) / (dens.length - 1) })
    }
    return out
}
const aspect = 36 * 0.55 / 19     // logo width / height
// deterministic "random" in 0..1 for (i, seed)
function rnd(i, seed) { const s = Math.sin(i * 12.9898 + seed * 78.233) * 43758.5453; return s - Math.floor(s) }

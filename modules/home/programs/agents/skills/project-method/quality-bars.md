# Quality bars

The references, default budgets and measurements of each kind of project. A project copies what
applies into the "Quality bar" section of its `docs/ROADMAP.md`, adapts the figures to its hardware
and its users, and the owner validates them. Figures here are starting points, not promises: a
project's own budgets, measured on its own hardware, are what count.

Tools that are not installed come from the project's Nix shell, or from `nix shell nixpkgs#<tool>`
for a one-off measurement.

Every project, whatever its kind:

- Nothing runs while there is nothing to do: no polling, no timer that wakes for nothing, no frame
  drawn at rest. Check it at rest: no CPU time in `top`, and no wake-ups of the program's own, counted
  with `pidstat -w -p <pid> 1` or by the change of `voluntary_ctxt_switches` in `/proc/<pid>/status`.
  Default budget: zero wake-ups per second of the program's own at rest.
- Start-up is measured cold and warm (`hyperfine` for programs that exit).
- Memory is measured at rest and under the heaviest realistic load (`heaptrack`, the resident size
  in `/proc/<pid>/status`).
- Power is measured where the program can draw it: the GPU's power on AMD through
  `/sys/class/drm/card*/device/hwmon/*/power1_average`, which needs no root. The CPU's, through RAPL
  or `powertop`, needs root: ask the owner to run it, or judge the CPU by its time and wake-ups.
- Each budget has a benchmark kept in the repository. A benchmark that can run in CI fails when it
  exceeds its budget by more than its noise.
- Hardware: the ROADMAP names a reference machine for each tier the project aims at. A tier, or a
  GPU maker, that was never measured is stated as unmeasured, never assumed.
- Iteration: a full build, the tests and each CI job have budgets too; a CI job stays under
  20 minutes.
- A crash leaves a report the user can attach to an issue; nothing leaves the machine without the
  user's consent.
- Bad input never crashes: parsers of untrusted data are fuzzed (`cargo fuzz`), `unsafe` is checked
  under Miri where it can be. Both need a nightly toolchain in the project's Nix shell.

## Games and real-time 3D

- References: the best AAA open worlds of the time, in image quality, streaming without hitches,
  animation and responsiveness. In a public repository, describe them by their qualities; never name
  the games.
- Frame time: 4.17 ms at 240 Hz on the high tier, at 4K; budgets per hardware tier for the others.
  Judge by the 99th percentile and the worst frames, not the average; no frame over twice the
  budget while playing (no stutter); frames paced evenly.
- Input to photon: measured, and kept within a few frames.
- Streaming and loading: no hitch when the world streams; load times measured and budgeted.
- Memory and video memory budgeted per tier.
- Power measured at a capped frame rate: a capped game uses no more than it needs.
- Image quality checked against reference images, compared in CI where the renderer can run there.
- Accessibility: remappable controls, subtitles, color-blind modes, and camera shake and motion blur
  that can be turned off.
- Text ready for translation: no sentence built by joining pieces, plurals by rule, layouts that
  hold longer text and right-to-left writing.
- Tools: the engine's own profiler and GPU timers, RenderDoc, Radeon GPU Profiler, MangoHud for
  frame times; PresentMon on Windows.

## Interfaces and desktop applications

- References: the most refined current interfaces, in motion (springs, shapes that morph,
  transitions between elements), materials (glass that blurs and bends what lies behind it), type
  and responsiveness.
- Every animation holds the display's rate, up to 240 Hz, without a dropped frame.
- At rest: no frame drawn, no CPU time, no wake-up of the program's own.
- Input to visible response within one frame where the work allows it.
- Start-up to first useful frame measured, cold and warm; default budget 150 ms warm. Memory and
  power at rest and while scrolling.
- Images: decoded off the interface's thread, in a cache bounded in memory that frees the GPU's.
- Rendering: gradients without bands (dithered), colors blended correctly, text crisp at every
  scale, pixel-aligned at fractional scales. Checked against reference images in CI, at scales 1
  and 2.
- Each animation's frame times recorded as a trace and judged at the 99th percentile.
- Accessibility: screen readers, full keyboard use, reduced motion and reduced transparency honored,
  contrast checked.
- The interface's thread never waits on a disk or the network.
- The look lives in one place: durations, springs, radii, blur and colors, shown by a gallery. The
  owner approves the look from captures and recordings made off screen.
- HDR, wide color gamut and variable refresh rates are supported, or stated as not supported.
- Text ready for translation, as for games.
- Tools: the framework's frame statistics, `perf`, `heaptrack`, the power readings above.

## Mobile applications

- References: the best apps of their kind on the platform.
- Cold start, frame times at the display's rate and battery use measured on a mid-range device
  (Macrobenchmark, Perfetto).
- No work in the background outside the system's schedulers.
- TalkBack and the system's font scale honored.

## Terminal programs (CLIs and TUIs)

- References: the best tools of their kind, in speed and polish.
- Start-up feels instant: measured with `hyperfine`; default budget 10 ms warm.
- A TUI redraws only what changed, without flicker (synchronized output where the terminal offers
  it), and uses no CPU while it waits for input.
- Correct with Unicode widths, terminal resizes, slow links (SSH) and terminals without color.
- Output for scripts is stable and documented; errors say what went wrong and what to do.

## Systems: drivers, audio, real-time

- References: the best open drivers and audio stacks of the platform.
- The real-time path (an audio callback, an interrupt handler) never allocates, never takes a lock
  that can block, never makes a system call that can block.
- Latency budgeted and measured; no underrun or overrun under load (`pw-top` for PipeWire). Default
  budget for audio: no xrun with 128-frame periods at 48 kHz.
- No busy waiting; wake-ups minimized (`pidstat -w`).
- Every `unsafe` and every hardware access documented; parsers of device data fuzzed.
- Tools: `perf`, `ftrace`, `pw-top`, `cargo fuzz`, Miri.

## Services and back ends

- Latency judged at the 99th percentile; throughput per core; memory per connection.
- Overload degrades gracefully: limits, back-pressure, timeouts.
- Logs and metrics enough to explain any failure, without personal data.

## Libraries

- An API that is hard to misuse, documented with examples that compile.
- No allocation or copy that the caller cannot avoid on its hot paths.
- Benchmarks for each operation that users call in loops.

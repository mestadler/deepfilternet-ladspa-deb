# DeepFilterNet LADSPA Plugin — Debian Packaging

Build system and guide for packaging [DeepFilterNet](https://github.com/Rikorose/DeepFilterNet)'s LADSPA noise-reduction plugin as a Debian `.deb` package, enabling neural-network voice denoising in **Easy Effects** on Debian Sid / Debian 13.
---

## Introduction

If you use your microphone on Linux — for video calls, podcasts, voice chat, or recordings — you've probably noticed background noise: keyboard clatter, fan hum, room echo, or people talking nearby. Traditional noise gates only cut audio below a volume threshold, and spectral subtraction struggles with complex, varying noise. The result is either still-noisy audio or that telltale robotic underwater sound.

DeepFilterNet takes a different approach. It uses a neural network trained on thousands of hours of audio to distinguish speech from background noise in real-time — removing keyboard typing, fan noise, and ambient chatter while preserving natural speech clarity. Integrated into Easy Effects via its LADSPA plugin, it gives you studio-grade noise reduction with a GUI slider, no command-line wrangling during a call.

**The problem**: Debian (and most other distributions) don't ship the DeepFilterNet LADSPA plugin with Easy Effects. The plugin lives in the DeepFilterNet source tree but isn't packaged separately — leaving a gap between installing Easy Effects and actually getting best-in-class noise reduction. This project closes that gap by building the plugin from source and packaging it as a `.deb` you can install in one command.

## Understanding the Components

- **Easy Effects** — the framework and UI for audio processing. It hosts LADSPA (Linux Audio Developer's Simple Plugin API) plugins, managing audio routing and providing a GUI for controlling effects.
- **DeepFilterNet** — the neural network engine that performs noise reduction. It processes audio in real-time, analyzing the frequency spectrum and using ML models to identify and suppress background noise while preserving speech.
- **LADSPA Plugin** — the bridge between Easy Effects and DeepFilterNet. Follows the LADSPA standard so Easy Effects can load and control DeepFilterNet as any other audio effect.

## Prerequisites

- **Easy Effects installed**: `sudo apt update && sudo apt install easyeffects`
- **Basic command-line knowledge**: comfortable with terminal commands and file operations
- **Sudo/root access**: required for system-level file operations
- **Internet connection**: to download or build the DeepFilterNet plugin

If building from source, also install Rust and Git:

```bash
sudo apt install rustc cargo git
```

## Installation

### Step 1: Identify Your System Architecture

```bash
uname -m
```

For most modern systems this returns `x86_64` (64-bit). The pre-built `.deb` targets `amd64`.

### Step 2: Obtain the DeepFilterNet .deb Package

**Option A: Build from source (recommended)**

Clone this repository and run the build script:

```bash
git clone --recurse-submodules <this-repo-url>
cd deepfilternet
./scripts/build-deb.sh
```

This compiles the Rust LADSPA crate from the pinned upstream submodule and produces `output/libdeep-filter-ladspa_0.5.7-1_amd64.deb`.

**Option B: Build manually without the packaging script**

```bash
git clone https://github.com/Rikorose/DeepFilterNet.git
cd DeepFilterNet
cargo build --release -p deep-filter-ladspa
```

The resulting `.so` will be at `target/release/libdeep_filter_ladspa.so`.

**Option C: Use a pre-built .deb**

If a pre-built `.deb` is available from this project's releases, download it directly.

### Step 3: Install the .deb Package

Using `apt` handles directory placement, file permissions, and package management:

```bash
sudo apt install ./libdeep-filter-ladspa_0.5.7-1_amd64.deb
```

This installs `libdeep_filter_ladspa.so` to `/usr/lib/ladspa/` with correct permissions (644) and registers the package for clean updates or removal.

### Step 4: Verify the Plugin Works

```bash
dpkg -L libdeep-filter-ladspa
```

This should list `/usr/lib/ladspa/libdeep_filter_ladspa.so`.

### Step 5: Configure Easy Effects

1. **Launch Easy Effects**: `easyeffects` or from your application menu
2. **Select Input Device**: Make sure you're working with the correct input device (your microphone)
3. **Add DeepFilterNet Plugin**:
   - Click "Add effect" or "+" in the input effects section
   - Look for "DeepFilterNet" in the list of available plugins
   - Select it to add to your effects chain
4. **Configure the Plugin**:
   - **Noise Reduction Level**: Start with a moderate setting (around 50–70%)
   - **Aggressiveness**: Higher settings remove more noise but may affect speech quality
   - **Voice Preservation**: Balance between noise removal and natural speech quality
5. **Test the Configuration**:
   - Speak into your microphone while playing background noise
   - Adjust settings in real-time to find the optimal balance
   - Use the bypass toggle to compare processed and unprocessed audio

## Configuration

### Route Audio Through Easy Effects

When Easy Effects is running, it creates a virtual input source that captures your raw microphone input, processes it through DeepFilterNet and any other configured effects, then outputs the filtered audio. In your desktop's sound settings, set the default input device to "Easy Effects Source" so all applications automatically use the filtered audio.  If you prefer you can select the source only for the application through the application itself by selecting the microphone to 'easy effects source'

**Verify it's working:**

1. Start Easy Effects with DeepFilterNet enabled
2. Open system sound settings or `pavucontrol`
3. Confirm you see both your physical microphone and "Easy Effects Source"
4. Configure your application to use "Easy Effects Source"
5. Test by recording audio or joining a call

# What the Controls Actually Do

DeepFilterNet processes audio in two stages: a coarse **ERB stage** that corrects the overall speech envelope, and a fine **DF (Deep Filtering) stage** that restores speech periodicity at low frequencies. The controls expose the thresholds that govern when each stage runs.

The model continuously estimates the local **signal-to-noise ratio (SNR)** on each 10ms frame. That SNR estimate drives all the threshold decisions below.

---

**Attenuation Limit (dB)** — range 0–100, default 100

A hard cap on how much the plugin is allowed to suppress noise. At 100 (maximum), the model applies its full estimated suppression. Lowering it — say to 6 dB — lets some background noise through intentionally, which can sound more natural and less like you're in a dead room. Useful if full suppression makes your voice sound hollow.

---

**Minimum Processing Threshold (dB)** — range -15 to 35, default -15

The SNR floor below which the plugin gives up entirely and outputs silence for that frame. If the estimated SNR drops below this value, both decoders are disabled and a silent spectrum is returned — the input is considered too noisy to be worth processing. Raising it (e.g. to -7 dB as in your screenshot) makes the plugin cut out sooner in very noisy conditions, which can reduce artefacts at the cost of occasionally clipping very quiet speech.

---

**Maximum ERB Processing Threshold (dB)** — range -15 to 35, default 35

The SNR ceiling above which the ERB (coarse envelope) decoder is disabled. Above this threshold the signal is already clean enough that correcting the envelope isn't necessary. Your value of 30 dB means the ERB stage is skipped once the signal is clearly clean — saves a little CPU and avoids unnecessary processing of already-good audio.

---

**Maximum DF Processing Threshold (dB)** — range -15 to 35, default 35

The SNR ceiling above which the DF (deep filtering, fine periodicity) decoder is disabled. The paper explicitly states that above 20 dB, the DF decoder is disabled since only low-noise conditions exist and enhancing periodicity is not necessary. Your setting of 20 dB matches exactly what the authors recommend. The DF stage is the more expensive of the two, so skipping it when SNR is high is the right trade-off.

---

**Minimum Processing Buffer (frames)** — range 0–10, default 0

How many frames of audio the plugin accumulates before starting to output processed audio. Zero means lowest possible latency (~20ms, one STFT window). Increasing it adds latency but can improve quality on hardware that struggles to keep up in real-time, by giving the model a small lookahead buffer. Leave at 0 for voice calls; you'd only raise it for recording where latency doesn't matter.

---

**Post Filter Beta** — range 0–0.05, default 0

Controls a post-processing step that applies a small amount of extra over-attenuation to residual noise. A value of 0 disables it. Small values (your 0.02) slightly increase aggressiveness on noise that slipped through the main model, at the risk of very faintly affecting speech quality. Think of it as a gentle "mop up" pass. The upstream `--pf` CLI flag enables this with a baked-in value; here you control the strength directly.

---


## Troubleshooting

### Plugin Not Appearing in Easy Effects

1. **Restart Easy Effects** — completely close and restart the application
2. **Check file permissions**: `ls -la /usr/lib/ladspa/libdeep_filter_ladspa.so` (should be 644)
3. **Verify LADSPA path** — some systems load from alternative locations:
   - `/usr/lib/ladspa/`
   - `/usr/local/lib/ladspa/`
   - `~/.ladspa/`

### Audio Quality Issues

1. **Reduce noise reduction intensity** — lower settings preserve more natural speech
2. **Check input levels** — ensure your microphone isn't clipping or too quiet
3. **Update audio drivers** — outdated drivers can cause compatibility issues

### Performance Issues

1. **Close other applications** — neural network processing is CPU-intensive
2. **Adjust buffer sizes** — in Easy Effects settings, increase the buffer size
3. **Monitor CPU usage** during processing to identify bottlenecks

## Advanced Configuration

### Multiple Microphone Setup

- Configure separate DeepFilterNet instances for each input
- Use different settings depending on the microphone's characteristics
- Create presets for different scenarios (podcasting, voice calls, recording)

### Integration with Other Effects

DeepFilterNet works well in combination with:

- **Compressor** — apply after noise reduction to even out volume levels
- **Equalizer** — fine-tune frequency response after noise processing
- **Limiter** — prevent audio clipping after processing

### Automation

- Use command-line tools to enable/disable the effect
- Create scripts that switch between noise reduction profiles
- Integrate with recording software for automatic noise reduction

## Performance Considerations

- **CPU Usage**: Neural network processing requires more CPU than traditional noise reduction. Modern systems handle this easily; older hardware may struggle.
- **Latency**: Minimal processing delay, slightly higher than simpler noise gates. Imperceptible for most use cases (voice calls, recording).
- **Memory**: Neural network models require some RAM to load, but the overhead is reasonable for the quality improvement.

## Alternative Solutions

| Method | Pros | Cons |
|---|---|---|
| **Traditional Noise Gates** | Simple, low resource usage | Less effective for complex noise |
| **Spectral Subtraction** | Good for constant background noise | Can create artifacts |
| **RNNoise** (LADSPA) | Another neural option, lighter | Less accurate than DeepFilterNet |

## Project Files

| Path | Purpose |
|---|---|
| `scripts/build-deb.sh` | Build script — compiles the Rust crate and packages the .deb |
| `.github/workflows/build.yml` | CI: automated .deb build on push, weekly schedule, and tag releases |
| `deepfilternet-src/` | Upstream DeepFilterNet source (git submodule, pinned at v0.5.6-89) |
| `output/` | Built `.deb` artifacts (gitignored) |
| `logs/` | Build logs (gitignored) |
| `TODO.md` | Planned improvements |



> **Attribution**: This guide started as a Debian adaptation of [Adam Gradzki's original solution for Arch Linux](https://adamgradzki.com/adding-deepfilternet-noise-reduction-to-easy-effects-on-arch-linux.html) (published November 2025).
> His work established the approach for integrating DeepFilterNet with Easy Effects; this project adapts it for Debian's package format and tooling.

## License

MIT — see [LICENSE](./LICENSE).

The upstream DeepFilterNet source ships under its own licenses (MIT / Apache-2.0 / GPL-3.0).

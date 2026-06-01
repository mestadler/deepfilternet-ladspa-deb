# DeepFilterNet LADSPA Plugin — Debian Packaging

Build system and guide for packaging [DeepFilterNet](https://github.com/Rikorose/DeepFilterNet)'s LADSPA noise-reduction plugin as a Debian `.deb` package, enabling neural-network voice denoising in **Easy Effects** on Debian Sid / Debian 13.

> **Attribution**: This guide is a Debian adaptation of [Adam Gradzki's original solution for Arch Linux](https://adamgradzki.com/adding-deepfilternet-noise-reduction-to-easy-effects-on-arch-linux.html) (published November 2025).
> His work established the approach for integrating DeepFilterNet with Easy Effects; this project adapts it for Debian's package format and tooling.

---

## Table of Contents

- [Introduction](#introduction)
- [Understanding the Components](#understanding-the-components)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Step 1: Identify Your System Architecture](#step-1-identify-your-system-architecture)
  - [Step 2: Obtain the DeepFilterNet .deb Package](#step-2-obtain-the-deepfilternet-deb-package)
  - [Step 3: Install the .deb Package](#step-3-install-the-deb-package)
  - [Step 4: Verify the Plugin Works](#step-4-verify-the-plugin-works)
  - [Step 5: Configure Easy Effects](#step-5-configure-easy-effects)
- [Important Configuration](#important-configuration)
  - [Launch Easy Effects on Startup](#launch-easy-effects-on-startup)
  - [Route Audio Through Easy Effects](#route-audio-through-easy-effects)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)
- [Performance Considerations](#performance-considerations)
- [Alternative Solutions](#alternative-solutions)
- [Project Files](#project-files)
- [License](#license)

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

## Important Configuration

### Launch Easy Effects on Startup

Easy Effects must be running to process audio through DeepFilterNet. Configure it to launch automatically:

**Option 1: Built-in setting (recommended)**

1. Open Easy Effects
2. Click the menu button (☰) → **Preferences**
3. In the **General** tab, enable **"Launch Easy Effects at startup"** / **"Start on login"**

**Option 2: System-level autostart**

For GNOME:

```bash
cp /usr/share/applications/com.github.wwmm.easyeffects.desktop ~/.config/autostart/
```

For KDE Plasma: **System Settings** → **Startup and Shutdown** → **Autostart** → **Add Application** → Easy Effects.

### Route Audio Through Easy Effects

> **Critical**: Applications must use the **"Easy Effects Source"** virtual input device, not your physical microphone directly.

When Easy Effects is running, it creates a virtual input source that captures your raw microphone input, processes it through DeepFilterNet and any other configured effects, then outputs the filtered audio.

**Per-application configuration:**

| Application | Setting |
|---|---|
| **Zoom** | Settings → Audio → Microphone: "Easy Effects Source" |
| **Discord** | Voice & Video → Input Device: "Easy Effects Source" |
| **Teams / Google Meet** | Application settings → Input: "Easy Effects Source" |
| **Audacity** | Recording Preferences → Input: "Easy Effects Source" |

**System-wide**: In your desktop's sound settings, set the default input device to "Easy Effects Source" so all applications automatically use the filtered audio.

**Verify it's working:**

1. Start Easy Effects with DeepFilterNet enabled
2. Open system sound settings or `pavucontrol`
3. Confirm you see both your physical microphone and "Easy Effects Source"
4. Configure your application to use "Easy Effects Source"
5. Test by recording audio or joining a call

> ⚠️ If applications use your standard microphone input instead of "Easy Effects Source," all audio processing is bypassed — DeepFilterNet noise reduction will not be applied.

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
| **Commercial Solutions** | Advanced noise reduction capabilities | Proprietary, often costly |
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

## License

MIT — see [LICENSE](./LICENSE).

The upstream DeepFilterNet source ships under its own licenses (MIT / Apache-2.0 / GPL-3.0).

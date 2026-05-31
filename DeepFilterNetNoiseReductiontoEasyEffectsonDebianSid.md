## Adding DeepFilterNet Noise Reduction to Easy Effects on Debian Sid / Debian 13

## Introduction

Easy Effects (formerly PulseEffects) is a powerful audio equalizer and effects system for Linux that provides studio-quality audio processing right from your desktop.
While the basic installation through most Linux distributions includes a comprehensive suite of audio effects, one crucial component is often missing: the neural network-based noise reduction plugin from DeepFilterNet.

DeepFilterNet is a state-of-the-art speech enhancement framework that uses deep learning to remove background noise from audio in real-time.
Unlike traditional noise gates or spectral subtraction methods, DeepFilterNet leverages advanced neural networks trained on thousands of hours of audio to distinguish between speech and background noise with remarkable accuracy.
This makes it particularly effective for removing complex, dynamic background sounds like keyboard typing, fan noise, or ambient chatter while preserving the clarity and natural quality of human speech.

Unfortunately, many Linux distributions, including Debian Sid, don't package the DeepFilterNet LADSPA plugin alongside Easy Effects due to licensing restrictions, file size considerations, or simply packaging oversights.
This leaves users with a powerful audio processing suite but missing one of its most impressive capabilities.

In this guide, we'll walk through the process of manually installing the DeepFilterNet plugin to complete your Easy Effects setup, enabling professional-grade noise reduction for podcasts, voice calls, recordings, and any other audio application where clean speech matters.

## Understanding the Components

Before diving into the installation process, it's helpful to understand what we're working with:

**Easy Effects** provides the framework and user interface for audio processing.
It acts as a host for various LADSPA (Linux Audio Developer's Simple Plugin API) plugins, managing the audio routing and providing an intuitive GUI for controlling the effects.

**DeepFilterNet** is the neural network engine that performs the actual noise reduction.
It processes audio in real-time, analyzing the frequency spectrum and using machine learning models to identify and suppress background noise while preserving speech components.

**LADSPA Plugin** serves as the bridge between Easy Effects and DeepFilterNet.
This plugin follows the LADSPA standard, allowing Easy Effects to load and control the DeepFilterNet processing engine as if it were any other audio effect.

## Prerequisites

Before proceeding with the installation, ensure you have:

- **Easy Effects installed**: Available through your distribution's
  package manager
- **Basic command-line knowledge**: Comfortable with terminal commands
  and file operations
- **Sudo/root access**: Required for system-level file operations
- **Internet connection**: To download the DeepFilterNet plugin

On Debian Sid / Debian 13, you can install Easy Effects and build dependencies using:

```bash
    sudo apt update && sudo apt install easyeffects
```

If building from source, also install Rust and Git:

```bash
    sudo apt install rustc cargo git
```

## The Installation Process

### Step 1: Identify Your System Architecture

First, determine whether you're running a 64-bit system (most common) or need a different architecture.
You can check this using:

```bash
    uname -m
```

For most modern systems, this will return `x86_64`, indicating a 64-bit architecture.

### Step 2: Obtain the DeepFilterNet .deb Package

The DeepFilterNet LADSPA plugin is packaged as a `.deb` for easy installation on Debian.
You can either build it from source or use a pre-built package.

**Option A: Build from source**

The project workspace includes a build script. Ensure Rust and Git are installed:

```bash
    sudo apt install rustc cargo git
```

Then build the package:

```bash
    git clone https://github.com/Rikorose/DeepFilterNet.git
    cd DeepFilterNet
    cargo build --release -p deep-filter-ladspa
    cd ..
    # Build scripts are available at:
    # scripts/build-deb.sh
```

This produces `output/libdeep-filter-ladspa_0.5.7-1_amd64.deb`.

**Option B: Use a pre-built .deb**

If a pre-built `.deb` is available, simply download or obtain the file. The package name is `libdeep-filter-ladspa`.

### Step 3: Install the .deb Package

Install the package using `apt`, which handles the LADSPA directory placement, file permissions, and package management automatically:

```bash
    sudo apt install ./libdeep-filter-ladspa_0.5.7-1_amd64.deb
```

This installs `libdeep_filter_ladspa.so` to `/usr/lib/ladspa/` with correct permissions, and registers the package so it can be updated or removed cleanly later.

To verify the installation:

```bash
    dpkg -L libdeep-filter-ladspa
```

This will list all files installed by the package, confirming the plugin is in the correct location.

### Step 4: Verify the Plugin Works

After installation, you can confirm the plugin is loadable by checking if Easy Effects can see it:

```bash
    dpkg -L libdeep-filter-ladspa
```

This should show `/usr/lib/ladspa/libdeep_filter_ladspa.so` with correct permissions (644).

### Step 5: Configure Easy Effects

Now that the plugin is installed, it's time to configure it in Easy Effects:

1.  **Launch Easy Effects**: Start the application from your application
    menu or using the command line: `easyeffects`

2.  **Select Input Device**: In the Easy Effects window, make sure
    you're working with the correct input device (your microphone).

3.  **Add DeepFilterNet Plugin**:
    - Click on the "Add effect" or "+" button in the input effects
      section
    - Look for "DeepFilterNet" in the list of available plugins
    - Select it to add to your effects chain

4.  **Configure the Plugin**:
    - **Noise Reduction Level**: Start with a moderate setting (around
      50-70%)
    - **Aggressiveness**: Higher settings remove more noise but may
      affect speech quality
    - **Voice Preservation**: Balance between noise removal and natural
      speech quality

5.  **Test the Configuration**:
    - Speak into your microphone while playing some background noise
    - Adjust the settings in real-time to find the optimal balance
    - Use the bypass toggle to compare the processed and unprocessed
      audio

## Important Configuration Steps

### Configure Easy Effects to Launch on Startup

To ensure your noise reduction settings are persistent and always active when you need them, you should configure Easy Effects to launch automatically when you log in:

**Option 1: Use Easy Effects Built-in Startup Setting (Recommended)**

1.  Open Easy Effects
2.  Click the menu button (☰) in the top-right corner
3.  Select **Preferences**
4.  In the **General** tab, look for **"Launch Easy Effects at
    startup"** or **"Start on login"**
5.  Enable this toggle option

**Option 2: System-level Startup Configuration**

If you prefer system-level configuration or the built-in option isn't available:

**For systems with GNOME Desktop:**

1.  Open **Settings** → **Applications** → **Startup Applications**
2.  Click **Add** and browse to Easy Effects
3.  Alternatively, run this command to add it to startup:

```bash
    cp /usr/share/applications/com.github.wwmm.easyeffects.desktop ~/.config/autostart/
```

**For systems with KDE Plasma:**

1.  Open **System Settings** → **Startup and Shutdown** → **Autostart**
2.  Click **Add Application** and select Easy Effects

**Why is this important?** Easy Effects needs to be running to process audio through the DeepFilterNet plugin.
Without it configured to launch on startup, you'll need to manually start the application each time you log in, and your noise reduction settings won't be automatically applied.

### Configure Applications to Use the Correct Audio Input

This is a crucial step that many users miss: **applications must use the "Easy Effects Source" virtual input device, not your standard microphone input.**

When Easy Effects is running, it creates a virtual input source called **"Easy Effects Source"** (or similar depending on your system configuration).
This virtual device captures your raw microphone input, processes it through DeepFilterNet and any other effects you've configured, and then outputs the filtered audio.

**How to configure your applications:**

**For audio recording software (Audacity, etc.):**

- Go to recording preferences
- Select "Easy Effects Source" or "Monitor of Easy Effects" as the
  input device
- Do NOT select your physical microphone directly

**For video conferencing applications:**

- **Zoom**: In Settings → Audio, select "Easy Effects Source" as the
  microphone
- **Discord**: In Voice & Video settings, select "Easy Effects Source"
  as the input device
- **Teams/Google Meet**: Check application settings to select the
  virtual input device

**For system-wide configuration:**

- In your desktop environment's sound settings, you can often set the
  default input device to "Easy Effects Source"
- This ensures all applications automatically use the filtered audio

**⚠️ Important Warning**: If applications use your standard microphone input instead of "Easy Effects Source," they will bypass all audio processing entirely.
This means DeepFilterNet noise reduction (and any other effects) will not be applied, and you'll wonder why the noise reduction isn't working despite everything being correctly configured in Easy Effects.

**To verify it's working:**

1.  Start Easy Effects with DeepFilterNet enabled
2.  Open your system sound settings or pavucontrol
3.  Look at the input devices - you should see both your physical
    microphone and "Easy Effects Source"
4.  Configure your recording/conferencing app to use "Easy Effects
    Source"
5.  Test by recording audio or joining a call - the noise reduction
    should now be active

## Troubleshooting Common Issues

### Plugin Not Appearing in Easy Effects

If DeepFilterNet doesn't appear in your list of available plugins:

1.  **Restart Easy Effects**: Completely close and restart the
    application
2.  **Check file permissions**: Ensure the plugin is readable by all
    users: `ls -la /usr/lib/ladspa/libdeep_filter_ladspa.so`
3.  **Verify LADSPA path**: Some systems may use different paths. Check
    if plugins are loaded from:
    - `/usr/lib/ladspa/`
    - `/usr/local/lib/ladspa/`
    - `~/.ladspa/`

### Audio Quality Issues

If you experience poor audio quality or distortion:

1.  **Reduce noise reduction intensity**: Lower the settings to preserve
    more natural speech
2.  **Check input levels**: Ensure your microphone isn't clipping or
    too quiet
3.  **Update audio drivers**: Outdated audio drivers can cause
    compatibility issues

### Performance Issues

If you experience high CPU usage or audio stuttering:

1.  **Close other applications**: Neural network processing can be
    CPU-intensive
2.  **Adjust buffer sizes**: In Easy Effects settings, increase the
    buffer size if available
3.  **Check system resources**: Monitor CPU usage during processing

## Advanced Configuration

For users wanting more control over the noise reduction process:

### Multiple Microphone Setup

If you use multiple microphones, you can:

- Configure separate instances of DeepFilterNet for each input
- Use different settings depending on the microphone's characteristics
  and use case
- Create preset configurations for different scenarios (podcasting,
  voice calls, recording)

### Integration with Other Effects

DeepFilterNet works well in combination with other audio effects:

- **Compressor**: Apply after noise reduction to even out volume levels
- **Equalizer**: Fine-tune the frequency response after noise processing
- **Limiter**: Prevent audio clipping after processing

### Automation and Scripts

For advanced users, you can automate the noise reduction setup:

- Use command-line tools to enable/disable the effect
- Create scripts that switch between different noise reduction profiles
- Integrate with recording software for automatic noise reduction

## Performance Considerations

DeepFilterNet represents a significant advancement in noise reduction technology, but it's important to understand its resource requirements:

- **CPU Usage**: The neural network processing requires more CPU power
  than traditional noise reduction methods. On modern systems, this is
  typically not an issue, but older hardware may struggle.
- **Latency**: There's minimal processing delay, but it's slightly
  higher than simpler noise gates. For most applications (voice calls,
  recording), this is imperceptible.
- **Memory Usage**: The neural network models require some RAM to load,
  but the overhead is reasonable for the quality improvement provided.

## Alternative Solutions

While DeepFilterNet is excellent, it's worth knowing about other noise reduction options:

- **Traditional Noise Gates**: Simpler, less resource-intensive but less
  effective for complex noise
- **Spectral Subtraction**: Good for constant background noise but can
  create artifacts
- **Commercial Solutions**: Professional audio software with advanced
  noise reduction capabilities

## Conclusion

Installing DeepFilterNet for Easy Effects transforms your Linux audio setup from good to professional-grade.
The neural network-based noise reduction can dramatically improve audio quality for voice recordings, podcasts, video calls, and any application where clear speech communication is essential.

While the manual installation process might seem intimidating at first, it's actually quite straightforward and provides access to one of the most advanced noise reduction technologies available in open-source audio processing.
The ability to remove complex background noise while preserving natural speech quality makes this setup particularly valuable for content creators, remote workers, and anyone who needs clear audio in less-than-ideal environments.

Take the time to experiment with different settings and find the configuration that works best for your specific use case and environment.
The results can be truly impressive, turning noisy, unusable audio into clear, professional-quality sound.

## Further Reading

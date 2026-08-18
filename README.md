<!--
SPDX-FileCopyrightText: 2026 Marcin Kaim
SPDX-License-Identifier: Apache-2.0
-->

# CV Make (`cv-make`)

> Automated, containerized CLI utility for compiling Markdown CVs into pixel-perfect, ATS-compliant PDF documents.

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![REUSE Compliance Status](https://api.reuse.software/badge/github.com/marcinkaim/cv-make)](https://api.reuse.software/info/github.com/marcinkaim/cv-make)
![GitHub Release](https://img.shields.io/github/v/release/marcinkaim/cv-make)
[![CI/CD](https://github.com/marcinkaim/cv-make/actions/workflows/release.yml/badge.svg)](https://github.com/marcinkaim/cv-make/actions)
[![Container Registry](https://img.shields.io/badge/GHCR-ghcr.io%2Fmarcinkaim%2Fcv--make-informational?logo=github)](https://github.com/marcinkaim/cv-make/pkgs/container/cv-make)

## 1. Overview

**`cv-make`** is an automated, containerized command-line utility engineered to compile plain-text Markdown CV documents (`CV.md`) into pixel-perfect, ATS-compliant PDF files. By treating resume authoring like code, it decouples raw content from visual presentation rules, enabling deterministic document compilation without polluting the host operating system with complex typesetting toolchains, Python runtimes, or system font packages.

### Core Design Principles

1. **Strict Execution Isolation & Reproducibility**: All compilation dependencies—including the Python 3 runtime, the WeasyPrint DTP layout engine, parsing libraries, and typography packages (IBM Plex fonts)—are completely encapsulated within an immutable Debian 13 container image. A document compiled today produces a byte-identical visual layout across any modern Linux host.
2. **ATS-First Engineering**: Output PDF documents maintain clean, un-rasterized Unicode vector text streams with natural reading order, active hyperlink annotations, and full text searchability, ensuring accurate parsing across automated recruitment platforms (e.g., Lever, Greenhouse, Workday).
3. **Decoupled Presentation (CSS Paged Media)**: Content is authored in clean, distraction-free Markdown, while visual styling, pagination rules, page numbering (`Page X of Y`), and typography are managed via standard CSS3 Paged Media rules.
4. **Zero-Overhead Host Integration**: A lightweight, rootless POSIX wrapper script interacts transparently with local container runtimes (Podman or Docker), operating entirely in user space without requiring administrative (`sudo`) privileges.

> 📖 **Architecture & Deep Dive:** For formal requirements, DOM preprocessor mechanics, algorithmic specifications, and container architecture, refer to the [CV Make Technical Specification](docs/cv-make-specification.md).

## 2. Key Architectural Features

* 🚀 **Zero Host Dependencies**: No Python runtime, WeasyPrint, Pango libraries, or system fonts needed on the host system.
* 🐳 **Universal Container Engine Support**: Automatically detects and seamlessly runs on **Podman** (preferred rootless engine) or **Docker** without requiring administrative (`sudo`) privileges.
* 🤖 **ATS & Searchability Guarantee**: Text is rendered as selectable Unicode streams rather than rasterized images or fragmented glyph paths, preserving metadata and structural readability.
* 📄 **CSS Paged Media Pagination**: Built-in A4 page layout with automatic orphan/widow protection (`break-inside: avoid`), page numbering (`Page X of Y`), and balanced page distribution.
* 🧩 **Smart Layout Helpers**:
    * **Universal Double-Pipe (`||`) Syntax**: Converts section subheadings (e.g., `### Role || Date`) into baseline-aligned, non-wrapping flex-lines without needing complex Markdown tables. Allows literal single pipes (`|`) to be freely used in contact details and descriptions without triggering layout splits.
    * **Dynamic 2-Column Header**: Supplying a photo via `-p` / `--photo` automatically activates a right-aligned portrait photo frame while maintaining full width if omitted.
    * **Native GDPR / RODO Footers**: Dedicated styling for data processing consent clauses that suppresses redundant headers and formats text into a compact, muted, page-anchored block.
* 🔒 **Immutable & Environment-Driven**: Execution is driven via `$CV_MAKE_CONTAINER_IMAGE`, allowing seamless switching between official production releases and local development images.

## 3. System Prerequisites

`cv-make` requires only a minimal POSIX-compatible host:

* **Operating System**: Modern Linux / POSIX-compliant environment (x86_64 / amd64).
* **Container Engine**: 
    * [Podman](https://podman.io/) (strongly recommended for rootless security and unprivileged user namespace UID/GID mapping), **or**
    * [Docker](https://www.docker.com/) (Engine 20.10+ / Docker Desktop).
* **Shell Environment**: Standard POSIX shell (`bash` or `zsh`).
* **Privileges**: **100% User-Space** — no `sudo` or `root` permissions required during installation or execution.

## 4. Installation & Getting Started

### 4.1 Production Installation (`install.sh`)

The automated production installer downloads the standalone runner script (`cv-make`), verifies directory paths, pulls the pre-built GHCR image (`ghcr.io/marcinkaim/cv-make:latest`), and configures your environment.

#### Automated One-Liner (curl / wget)

```bash
curl -fsSL [https://github.com/marcinkaim/cv-make/releases/latest/download/install.sh](https://github.com/marcinkaim/cv-make/releases/latest/download/install.sh) | bash
```

*Or using `wget`:*

```bash
wget -qO- [https://github.com/marcinkaim/cv-make/releases/latest/download/install.sh](https://github.com/marcinkaim/cv-make/releases/latest/download/install.sh) | bash
```

#### Safe Guard & Reinstallation

To prevent accidental overwrites, running `install.sh` when an existing installation is detected will halt execution. To update or repair an existing installation:

```bash
curl -fsSL [https://github.com/marcinkaim/cv-make/releases/latest/download/install.sh](https://github.com/marcinkaim/cv-make/releases/latest/download/install.sh) | bash -s -- --reinstall
```

### 4.2 Developer Installation (`install_dev.sh`)

If you are modifying the Python preprocessor, styling sheets (`src/styles/default.css`), or container build manifests:

1. Clone the repository:
    ```bash
    git clone [https://github.com/marcinkaim/cv-make.git](https://github.com/marcinkaim/cv-make.git)
    cd cv-make
    ```
2. Run the developer installation script:
    ```bash
    ./install_dev.sh
    ```

This will:

* Build a local development container image tagged as `cv-make:dev` directly from the local `Dockerfile`.
* Deploy the local `bin/cv-make` wrapper into `~/.local/bin/cv-make`.
* Set your environment to prioritize `CV_MAKE_CONTAINER_IMAGE=cv-make:dev`.

### 4.3 Shell & PATH Configuration

Both installation scripts automatically verify and configure your shell configuration file (`~/.bashrc`, `~/.zshrc`, or `~/.profile`):

1. Ensures `~/.local/bin` is present in your system `$PATH`.
2. Sets the default container image reference variable:
    ```bash
    export CV_MAKE_CONTAINER_IMAGE="ghcr.io/marcinkaim/cv-make:latest" # (or cv-make:dev)
    ```

To apply the changes immediately in your current terminal session:

```bash
source ~/.bashrc   # If using Bash
# or
source ~/.zshrc    # If using Zsh
```

Verify that the CLI is accessible:

```bash
cv-make --help
```

## 5. CLI Usage & Command Reference

`cv-make` provides a strict, deterministic command-line interface. To prevent ambiguous invocations, all file inputs and outputs must be passed via explicit named arguments.

### 5.1 Command Signature & Options Table

```bash
cv-make -i <input.md> -o <output.pdf> [OPTIONS]
cv-make [--update | --uninstall | --help]
```

| Option | Long Option | Description |
| --- | --- | --- |
| `-i <file>` | `--in <file>` | **Required.** Path to the source Markdown document (`.md`). |
| `-o <file>` | `--out <file>` | **Required.** Destination path for the generated PDF document (`.pdf`). |
| `-p <file>` | `--photo <file>` | **Optional.** Path to candidate portrait image (JPEG / PNG). Activates a 2-column header layout. |
| `-s <file>` | `--style <file>` | **Optional.** Path to custom CSS stylesheet. Can be repeated multiple times to cascade styles. |
| `-v` | `--verbose` | **Optional.** Enable debug logging (emits WeasyPrint layout, font matching, and preprocessor logs to `stderr`). |
| `-h` | `--help` | Display CLI usage summary and exit. |
|  | `--update` / `--upgrade` | Pull the latest container image from GitHub Container Registry (GHCR). |
|  | `--uninstall` | Perform a clean, rootless uninstallation of the host wrapper, profile exports, and container images. |

> ⚠️ **Strict CLI Parameter Model:**
> * Positional arguments and standard stream placeholders (`-` for STDIN/STDOUT) are strictly rejected.
> * Invoking `cv-make` with zero arguments displays the help screen cleanly without blocking or hanging the terminal.

### 5.2 Practical Examples

#### Basic Compilation

Compile a plain Markdown CV into a PDF document using the default typography and layout:

```bash
cv-make -i CV.md -o CV.pdf
```

#### Including a Profile Photo

Attach a candidate portrait. The header automatically adapts into a balanced two-column flex layout:

```bash
cv-make -i CV.md -o CV.pdf -p profile.jpg
```

#### Applying Custom Stylesheets

Apply one or more custom CSS sheets to customize typography, accent colors, or margins:

```bash
cv-make -i CV.md -o CV.pdf -s branding.css -s print-overrides.css
```

#### Running in Diagnostic / Verbose Mode

Inspect font-matching decisions, CSS cascade rules, and layout engine events:

```bash
cv-make -i CV.md -o CV.pdf -v
```

### 5.3 Maintenance & Lifecycle Commands

#### Updating the Engine

To pull the latest official container image from GitHub Container Registry:

```bash
cv-make --update
```

#### Clean Uninstallation

To completely remove `cv-make` from your system (removes `~/.local/bin/cv-make`, unsets environment variables in `~/.bashrc`/`~/.zshrc`, and prunes container images):

```bash
cv-make --uninstall
```

## 6. Markdown Authoring Guide

`cv-make` translates standard CommonMark into a structured, ATS-compliant HTML DOM optimized for print pagination.

> 💡 **Ready-to-Use Example:** See [`examples/office-manager-cv.md`](examples/office-manager-cv.md) for a complete template alongside its [sample photo](examples/office-manager-photo.jpg) and [compiled PDF](examples/office-manager-cv.pdf).

### Quick Syntax Reference

```markdown
# Jane Doe

Senior Systems Architect | jane.doe@example.com | +1 (555) 019-2834
San Francisco, CA | [linkedin.com/in/janedoe](https://linkedin.com/in/janedoe)

## Professional Summary

Results-driven architect with 10+ years of experience leading distributed cloud infrastructure...

## Work Experience

### CloudScale Technologies – *Principal Engineer* || 2021 – Present
- Architected multi-region Kubernetes clusters handling 50k+ req/sec.
- **Tech Stack:** `Go` `Kubernetes` `Terraform` `AWS`

### Apex Data Systems – *Senior DevOps Engineer* || 2017 – 2021
- Automated CI/CD release pipelines reducing deployment frequency from weeks to minutes.

## Education

### University of California, Berkeley || 2013 – 2017
*B.S. in Computer Science*

## GDPR Clause

I hereby give consent for my personal data to be processed for recruitment purposes under Regulation (EU) 2016/679 (GDPR).
```

### Key Formatting Conventions

* **Header & Contact Info**: Formatted as `# Name` followed immediately by contact links and metadata before the first `##`. When a portrait photo is passed via `-p`, the header automatically shifts into a balanced 2-column flex container.
* **Section Hierarchy**: Top-level sections use `##` (e.g., `## Work Experience`, `## Education`), creating `<section>` wrappers with automated slug IDs (e.g., `#work-experience`).
* **Universal Double-Pipe (`||`) Syntax**: The double-pipe operator (`||`) in headings or paragraphs splits content into a two-column `.flex-line` (left: title/organization, right: baseline-aligned, non-wrapping date range). Single pipe characters (`|`) remain literal text, allowing unconstrained use in contact details and skill descriptions.
* **Tags & Skills**: Text wrapped in backticks (``tag``) renders as rounded badges in **IBM Plex Mono**.
* **GDPR / Privacy Clause**: Sections titled `## GDPR Clause` or `## Privacy Clause` automatically hide the `<h2>` heading and style the text as a compact, unbroken legal footnote.

## 7. Styling & Customization

Visual presentation is completely decoupled from the Markdown source and handled via standard **CSS3 Paged Media**.

### 7.1 Default Visual Identity

* **Typography**: Powered by the **IBM Plex** family (`IBM Plex Sans` for body/headings and `IBM Plex Mono` for technical tags).
* **Page Layout**: Standard A4 portrait layout with automatic page numbering (`Page X of Y` via `@bottom-right`) and orphan/widow protection (`break-inside: avoid` on entries and list items).

### 7.2 Custom Stylesheet Cascade (`-s` / `--style`)

User stylesheets passed via `-s` / `--style` are applied sequentially **after** `default.css`. You can override fonts, accent colors, line heights, or margins using standard CSS cascade rules:

```bash
cv-make -i CV.md -o CV.pdf -s custom-theme.css
```

## 8. System Architecture & Under the Hood

> 📖 **Definitive Engineering Blueprint:** This section provides an executive summary of the system architecture. For complete mathematical models, DOM preprocessor rules, security boundaries, and algorithm formalisms, refer to the [CV Make Technical Specification](docs/cv-make-specification.md).

### 8.1 Host-Container Boundary & Streaming Model

`cv-make` is designed around strict execution sandboxing and zero host-system pollution. The host-side executable (`bin/cv-make`) is a lightweight POSIX shell wrapper that orchestrates container lifecycles without requiring Python or native rendering libraries on the host:

1. **Standard Stream Redirection**: The host wrapper opens the input Markdown file and streams it directly to the container's standard input (`stdin`), while capturing standard output (`stdout`) to write the compiled PDF.
2. **Diagnostic Separation**: Internal engine logs, font resolution traces, and errors are emitted strictly to standard error (`stderr`), keeping the output binary stream completely uncorrupted.
3. **Execution Sandbox**: All compilation runs inside an isolated, unprivileged container based on `debian:trixie-slim`.

### 8.2 Targeted Asset Mounting Strategy

To minimize security exposure, `cv-make` never mounts the host filesystem indiscriminately:
* The root filesystem and host working directories remain completely inaccessible to the container.
* Only explicitly provided assets (the portrait image passed via `-p` and custom stylesheets passed via `-s`) are selectively mounted as read-only volumes (`:ro,z`) into the container's isolated `/tmp/assets/` directory.

### 8.3 High-Level Compilation Pipeline

Inside the container sandbox, `src/cv_make.py` executes a deterministic 4-stage transformation pipeline:

```
[ Markdown Source (stdin) ]
│
▼
Stage 1: AST Parsing (markdown-it-py)
│
▼
Stage 2: Semantic DOM Transformation (BeautifulSoup4)
├─ Dynamic Header & Photo Flexbox Layout
├─ Structural Section Wrapping & Slugified IDs
└─ Universal Double-Pipe (||) Splitter into .flex-line
│
▼
Stage 3: HTML5 Assembly (Jinja2 Template Engine)
│
▼
Stage 4: DTP Layout & Typesetting (WeasyPrint)
│
▼
[ ATS-Compliant Vector PDF (stdout) ]
```

1. **AST Parsing (`markdown-it-py`)**: Parses CommonMark text into an intermediate HTML Abstract Syntax Tree.
2. **Semantic DOM Transformation (`BeautifulSoup4`)**: Restructures HTML nodes into a semantic, print-ready hierarchy (generating `<section>` containers with deterministic slug IDs, structuring the 2-column header, and splitting double-pipe-delimited (`||`) lines into baseline-aligned `.flex-line` elements).
3. **HTML5 Assembly (`Jinja2`)**: Embeds transformed markup into a standalone HTML5 template with linked stylesheets.
4. **Vector PDF Typesetting (`WeasyPrint`)**: Renders the document against CSS3 Paged Media rules, embedding IBM Plex fonts and producing an ATS-compliant Unicode vector PDF stream.

## 9. Development & Contributing Workflow

### 9.1 Local Development Setup

To contribute to `cv-make` or customize its core engine:

1. Clone the repository:
    ```bash
    git clone [https://github.com/marcinkaim/cv-make.git](https://github.com/marcinkaim/cv-make.git)
    cd cv-make
    ```
2. Initialize the local developer environment:
    ```bash
    ./install_dev.sh
    ```

This builds a local container image tagged as `cv-make:dev` and configures your shell environment.

### 9.2 Rapid Iteration Cycle (Hot Source Mounting)

You can test local modifications to `src/cv_make.py` or `src/styles/default.css` immediately without rebuilding the container image by mounting your local `src/` directory directly:

```bash
podman run -i --rm \
  -v "$(pwd)/src:/app:ro,z" \
  "$CV_MAKE_CONTAINER_IMAGE" -v < examples/office-manager-cv.md > test_output.pdf
```

To test against an ad-hoc container image override:

```bash
CV_MAKE_CONTAINER_IMAGE="cv-make:dev" cv-make -i examples/office-manager-cv.md -p examples/office-manager-photo.jpg -o test_output.pdf -v
```

### 9.3 Repository Directory Map

```
cv-make/
├── bin/
│   └── cv-make                 # Static POSIX Bash wrapper script
├── docs/
│   └── cv-make-specification.md # Definitive technical and architectural specification
├── examples/
│   ├── office-manager-cv.md    # Reference Markdown CV template
│   ├── office-manager-cv.pdf   # Pre-compiled reference PDF artifact
│   └── office-manager-photo.jpg # Sample profile photograph asset
├── src/
│   ├── cv_make.py              # Internal Python preprocessor & DTP engine
│   └── styles/
│       └── default.css         # Default CSS Paged Media stylesheet
├── .github/
│   └── workflows/
│       └── release.yml         # CI/CD GitHub Actions release pipeline
├── Dockerfile                  # Debian 13 (Trixie) container build manifest
├── install.sh                  # Standalone production installer (GitHub Releases)
├── install_dev.sh              # Local developer environment installer
├── LICENSE                     # Project license overview & summary
├── LICENSES/                   # REUSE-compliant license texts (Apache-2.0, CC0-1.0)
├── NOTICE                      # Legal attributions for bundled open-source components
└── REUSE.toml                  # REUSE Specification compliance configuration
```

## 10. CI/CD & Automated Distribution

`cv-make` leverages automated GitHub Actions workflows (`.github/workflows/release.yml`) triggered upon pushing release tags (`v*.*.*`):

* 📦 **Container Registry (GHCR)**: Automatically builds multi-stage container images and publishes them to the GitHub Container Registry under `ghcr.io/marcinkaim/cv-make:latest` and semantic version tags (`vX.Y.Z`).
* 🚀 **GitHub Releases Distribution**: Packages the standalone runner archive (`cv-make-linux-amd64.tar.gz`) containing `bin/cv-make`, license metadata, and attaches the canonical `install.sh` script to official GitHub Releases.

## 11. Licensing, REUSE & Attributions

### 11.1 Source Code License

The `cv-make` codebase is free and open-source software released under the **Apache License, Version 2.0** (`SPDX-License-Identifier: Apache-2.0`). See [LICENSE](LICENSE) and [LICENSES/Apache-2.0.txt](LICENSES/Apache-2.0.txt) for the full text.

### 11.2 REUSE Compliance

This repository is 100% compliant with the [REUSE Specification v3.3](https://reuse.software/). Every source file contains explicit SPDX licensing headers, and full license texts are preserved in the `LICENSES/` directory.

### 11.3 Third-Party Attributions

The container runtime environment incorporates open-source software and typography assets. Detailed legal notices and copyright attributions are maintained in the [`NOTICE`](NOTICE) file.

### 11.4 Generated Documents Copyright Guarantee

Embedding fonts and typesetting documents using `cv-make` places **no copyright claims or licensing restrictions on the generated PDF output**. The resulting CV documents remain 100% the exclusive intellectual property of the author.

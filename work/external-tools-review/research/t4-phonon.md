# T4 — Phonon-2 (offline speech-to-text)

Source video: Better Stack, "This 164MB Speech Model Might Replace Whisper..."
(https://youtu.be/eskgvQYchd0). Primary sources: model card
https://huggingface.co/FermionResearch/Phonon-2, repo
https://github.com/fermionresearch/phonon, docs
https://fermionresearch.com/docs/speech. Researched 2026-10-18.

## What it is

- An English-only speech-recognition model from Fermion Research. It is a
  compressed version of `nvidia/parakeet-tdt-0.6b-v3`: the encoder is about
  2.1 bits per weight, and the download is **164 MB** (the teacher is 2,508 MB).
  Source: model card.
- **Licence:** weights CC-BY-4.0, so commercial use is allowed with
  attribution. The CLI and repo code are Apache-2.0. Source: model card, repo.
- **Accuracy (vendor-reported):** 5.21% average WER across the seven English
  Open ASR Leaderboard sets. The teacher scores 4.96%. Its worst set is AMI
  meetings at 9.37%. Source: model card.
- **Independent accuracy:** the video says the Open ASR Leaderboard's own run
  gave Phonon-2 7.23%, the teacher 6.51% and Whisper Turbo 8.39%, with Whisper
  winning on noisy speech. **(unverified)**: only the video and a secondary
  blog (stork.ai) give these numbers, and I did not find the leaderboard row.
- **Speed (vendor-reported):** 174x real time on an M5 MacBook Air, so an hour
  of audio takes about 20 s. 143x on 16 Zen-5 vCPUs, 6,680x on an H100.
  Source: model card. The video's breakdown (exact decoding 109x, CPU-only
  40x) and its doubts about the "6x faster than Redux" comparison are
  **(unverified)**.
- **Platforms:** MLX on Apple silicon, Core ML in a separate repo, CPU on
  Linux (x86-64 and Arm), Windows and macOS, and CPU and CUDA Docker images.
  Needs Python 3.10 or newer; macOS still ships 3.9. Source: repo, docs.
- **Interfaces:**
  - `phonon transcribe <file>`, with `--json` for word timestamps.
  - `phonon listen` for live microphone transcription, Apple silicon only.
  - `--hotwords` to favour up to 25 terms you give it.
  - `phonon serve`, an OpenAI-compatible server on `127.0.0.1:8000`, with
    `POST /v1/audio/transcriptions` and a WebSocket at `/v1/audio/stream`.

  Source: repo, docs. There is no MCP server.
- **Maturity:** the repo shows 4 commits and about 254 stars. The video says
  the lab is about 6 weeks old and that the main real user is Fermion's own Mac
  dictation app **(unverified)**.

## What the template already has

- **youtube-transcript MCP:** `scripts/mcp/youtube_transcript_mcp.py`, launched
  by `scripts/mcp/youtube-transcript.sh`. It is loaded on demand through
  `mcp-fragments/youtube-transcript.json` and documented in `docs/mcp-setup.md`
  under "YouTube transcript server". It gets YouTube's own captions, including
  auto-captions, through `yt-dlp`. It does no speech recognition itself, so it
  fails on videos without captions and on any non-YouTube audio.
- **Voice input:** nothing. No doc covers voice input or dictation: a grep for
  `whisper|speech|dictat` finds nothing relevant, and
  `docs/for-non-engineers.md` only covers typed sessions. Non-engineers can
  already use OS dictation (macOS Dictation, Windows Voice Typing) in any agent
  chat box with no setup.
- **Audio or meeting-recording input:** no skill or script handles it.

## Gaps it would fill

1. **Recordings without captions:** a local fallback for meeting recordings,
   voice memos, non-YouTube videos, and YouTube videos with no captions. The
   output would go into `research` / `research-wave` inputs. This is the only
   real gap.
2. **Private transcription:** offline transcription for recordings that must
   not leave the machine.
3. **Dictation (weak):** better dictation than OS dictation for jargon, via
   hotwords. This is marginal for a template, and OS dictation already covers
   the non-engineer case.

## Cost / risk

- **Agent-agnosticism:** good. It is a CLI and a local HTTP API, so any runtime
  can shell out to it. Wiring it in as a fallback inside
  `youtube_transcript_mcp.py` (yt-dlp audio, then Phonon) would also stay
  runtime-neutral.
- **Licence:** fine for downloaders. CC-BY-4.0 requires attribution to NVIDIA
  and Fermion, and Apache-2.0 needs nothing extra.
- **Platform:** best on Apple silicon. CPU works on Linux and Windows but is
  slower. It needs Python 3.10 or newer, ffmpeg-type audio handling and about
  200 MB of weights, which is far heavier than the current `yt-dlp`-only
  dependency.
- **Maturity:** a 4-commit repo from a weeks-old lab, with accuracy numbers
  mostly reported by the vendor. Adding it as a template dependency now would
  carry churn risk. It is English only.
- **Substitutability:** whisper.cpp, Parakeet and Redux do the same job. If the
  template ever adds transcription, it should name a capability ("a local STT
  CLI") rather than lock in this model.

## Verdict: skip (revisit later as an optional fallback)

The template coordinates agent sessions and has no audio workflow today.
Typed and OS-dictated text already reach every runtime, and the
youtube-transcript MCP covers the one media-input path that exists. Phonon-2
is impressive for its size and its licence is clean. But it is English-only
and weeks old, and its accuracy claims are mostly the vendor's own. Adopting
it would add a heavy, platform-skewed dependency for a need no work item has
yet shown. The one real gap is transcribing recordings that have no captions.
If that need appears, fill it with an optional, model-neutral fallback, and
re-check Phonon's state then.

## Candidate recommendations

- **(low)** Add a "no captions?" note to `docs/mcp-setup.md` → "YouTube
  transcript server" pointing at local STT CLIs (whisper.cpp, Phonon-2) as a
  manual fallback. Doc only, no dependency.
- **(low, deferred)** If a work item needs meeting or audio inputs, spin out an
  item for an optional `--stt <cmd>` fallback in `youtube_transcript_mcp.py`
  or a `scripts/transcribe.sh` wrapper that works with any OpenAI-compatible
  local STT endpoint.
- **(trivial)** Add one line to `docs/for-non-engineers.md` saying OS dictation
  works in any agent chat box. This is free and needs no tooling.

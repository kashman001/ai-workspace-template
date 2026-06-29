#!/usr/bin/env python3
"""Minimal YouTube MCP server backed by yt-dlp.

The server intentionally avoids a Python MCP SDK dependency so it can run in
agent runtimes that only have Python plus yt-dlp available.
"""

from __future__ import annotations

import html
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any
from urllib.parse import urlparse


SERVER_NAME = "workspace-youtube"
SERVER_VERSION = "0.1.0"
PROTOCOL_VERSION = "2024-11-05"
DEFAULT_TIMEOUT = 90
DEFAULT_MAX_CHARS = 30000
YOUTUBE_HOSTS = {
    "youtube.com",
    "www.youtube.com",
    "m.youtube.com",
    "music.youtube.com",
    "youtu.be",
    "www.youtu.be",
    "youtube-nocookie.com",
    "www.youtube-nocookie.com",
}


def send(payload: dict[str, Any]) -> None:
    sys.stdout.write(json.dumps(payload, separators=(",", ":")) + "\n")
    sys.stdout.flush()


def response(request_id: Any, result: Any) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "result": result}


def error_response(request_id: Any, code: int, message: str) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}}


def require_youtube_url(url: str) -> str:
    parsed = urlparse(url)
    host = (parsed.netloc or "").lower()
    if not parsed.scheme.startswith("http") or host not in YOUTUBE_HOSTS:
        raise ValueError("Only YouTube URLs are supported")
    return url


def run_yt_dlp(args: list[str], timeout: int = DEFAULT_TIMEOUT, cwd: str | None = None) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + env.get("PATH", "")
    return subprocess.run(
        ["yt-dlp", *args],
        check=False,
        cwd=cwd,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
    )


def video_info(url: str) -> dict[str, Any]:
    result = run_yt_dlp(["--dump-json", "--skip-download", "--no-playlist", url])
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "yt-dlp failed to fetch video metadata")
    raw = json.loads(result.stdout)
    return {
        "id": raw.get("id"),
        "title": raw.get("title"),
        "channel": raw.get("channel") or raw.get("uploader"),
        "uploader": raw.get("uploader"),
        "duration_seconds": raw.get("duration"),
        "upload_date": raw.get("upload_date"),
        "webpage_url": raw.get("webpage_url"),
        "availability": raw.get("availability"),
        "live_status": raw.get("live_status"),
        "description": raw.get("description"),
        "subtitles": sorted((raw.get("subtitles") or {}).keys()),
        "automatic_captions": sorted((raw.get("automatic_captions") or {}).keys()),
    }


TIMESTAMP_RE = re.compile(r"^\d{2}:\d{2}:\d{2}\.\d{3}\s+-->\s+\d{2}:\d{2}:\d{2}\.\d{3}")
TAG_RE = re.compile(r"<[^>]+>")


def parse_vtt(path: Path) -> str:
    lines: list[str] = []
    previous = ""
    for raw_line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line == "WEBVTT" or line.startswith(("Kind:", "Language:", "NOTE", "STYLE", "REGION")):
            continue
        if TIMESTAMP_RE.match(line):
            continue
        if line.isdigit():
            continue
        line = TAG_RE.sub("", line)
        line = html.unescape(line).strip()
        if not line or line == previous:
            continue
        lines.append(line)
        previous = line
    return "\n".join(lines)


def get_transcript(args: dict[str, Any]) -> dict[str, Any]:
    url = require_youtube_url(str(args.get("url", "")))
    languages = args.get("languages") or ["en.*", "en"]
    if isinstance(languages, str):
        languages = [languages]
    language_arg = ",".join(str(item) for item in languages)
    include_auto = bool(args.get("include_auto", True))
    max_chars = int(args.get("max_chars", DEFAULT_MAX_CHARS))

    with tempfile.TemporaryDirectory(prefix="youtube-mcp-") as tmp:
        cmd = [
            "--skip-download",
            "--no-playlist",
            "--sub-langs",
            language_arg,
            "--sub-format",
            "vtt",
            "--output",
            "%(id)s.%(ext)s",
        ]
        if include_auto:
            cmd.append("--write-auto-subs")
        cmd.append("--write-subs")
        cmd.append(url)

        result = run_yt_dlp(cmd, cwd=tmp)
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "yt-dlp failed to fetch subtitles")

        vtt_files = sorted(Path(tmp).glob("*.vtt"))
        if not vtt_files:
            raise RuntimeError("No matching captions were downloaded for the requested languages")

        transcript = "\n\n".join(parse_vtt(path) for path in vtt_files).strip()
        truncated = False
        if len(transcript) > max_chars:
            transcript = transcript[:max_chars].rstrip()
            truncated = True

        info = video_info(url)
        return {
            "url": url,
            "title": info.get("title"),
            "channel": info.get("channel"),
            "caption_files": [path.name for path in vtt_files],
            "languages_requested": languages,
            "truncated": truncated,
            "transcript": transcript,
        }


def tool_result(data: Any, is_error: bool = False) -> dict[str, Any]:
    text = data if isinstance(data, str) else json.dumps(data, indent=2, ensure_ascii=False)
    return {"content": [{"type": "text", "text": text}], "isError": is_error}


TOOLS = [
    {
        "name": "youtube_get_video_info",
        "description": "Fetch public YouTube video metadata and available caption language keys using yt-dlp.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "url": {"type": "string", "description": "YouTube video URL."},
            },
            "required": ["url"],
            "additionalProperties": False,
        },
    },
    {
        "name": "youtube_get_transcript",
        "description": "Fetch public YouTube captions or auto-captions as plain text when available.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "url": {"type": "string", "description": "YouTube video URL."},
                "languages": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "Caption language selectors for yt-dlp, for example ['en.*', 'en'].",
                },
                "include_auto": {
                    "type": "boolean",
                    "description": "Include auto-generated captions when manual captions are unavailable.",
                    "default": True,
                },
                "max_chars": {
                    "type": "integer",
                    "description": "Maximum transcript characters to return.",
                    "default": DEFAULT_MAX_CHARS,
                },
            },
            "required": ["url"],
            "additionalProperties": False,
        },
    },
]


def handle_request(message: dict[str, Any]) -> dict[str, Any] | None:
    method = message.get("method")
    request_id = message.get("id")
    params = message.get("params") or {}

    if method == "initialize":
        return response(
            request_id,
            {
                "protocolVersion": PROTOCOL_VERSION,
                "capabilities": {"tools": {}},
                "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
            },
        )
    if method == "tools/list":
        return response(request_id, {"tools": TOOLS})
    if method == "tools/call":
        name = params.get("name")
        arguments = params.get("arguments") or {}
        try:
            if name == "youtube_get_video_info":
                return response(request_id, tool_result(video_info(require_youtube_url(str(arguments.get("url", ""))))))
            if name == "youtube_get_transcript":
                return response(request_id, tool_result(get_transcript(arguments)))
            return error_response(request_id, -32601, f"Unknown tool: {name}")
        except Exception as exc:  # MCP tool errors should be visible to the client.
            return response(request_id, tool_result(str(exc), is_error=True))
    if method == "ping":
        return response(request_id, {})
    if method and method.startswith("notifications/"):
        return None
    return error_response(request_id, -32601, f"Unknown method: {method}")


def main() -> int:
    for line in sys.stdin:
        if not line.strip():
            continue
        try:
            message = json.loads(line)
            result = handle_request(message)
            if result is not None and "id" in message:
                send(result)
        except json.JSONDecodeError as exc:
            send(error_response(None, -32700, f"Parse error: {exc}"))
        except Exception as exc:
            send(error_response(None, -32603, f"Internal error: {exc}"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

def llm_query(
    prompt: str,
    model: Optional[str] = None,
    timeout: int = 300,
    system: Optional[str] = DEFAULT_LEAF_SYSTEM,
) -> str:
    """A single sub-LM call -- the leaf of the recursion.

    Runs a headless Claude Code (`claude -p`) with TOOLS OFF, so it behaves as a
    plain LLM forward pass: it reads the (bounded) `prompt` in its own context
    window and returns a string. The root is responsible for chunking the context
    down to something a leaf can hold; the leaf does the *semantic* work
    (classify / extract / summarize / answer) while the root's Python does the
    *arithmetic* (count / aggregate / format).

    Returns the sub-LM's text. On failure returns a "[llm_query: ...]" marker
    string rather than raising, so a large loop is not aborted by one bad call.

    Usage accounting: if RLM_LEAF_USAGE_LOG is set, the call is made with
    `--output-format json` and its usage/cost is appended to that log; the text
    returned is identical to the un-instrumented path.
    """
    model = model or DEFAULT_SUB_MODEL
    usage_log = _leaf_usage_log_path()
    cmd = [_claude_exe(), "-p", "--model", model, "--allowedTools", ""]
    if usage_log:
        cmd += ["--output-format", "json"]
    if system:
        cmd += ["--append-system-prompt", system]
    try:
        res = subprocess.run(
            cmd,
            input=prompt,
            capture_output=True,
            text=True,
            timeout=timeout,
            encoding="utf-8",
            errors="replace",
        )
    except subprocess.TimeoutExpired:
        if usage_log:
            _record_leaf_usage(usage_log, model, None, ok=False, note=f"TIMEOUT/{timeout}s")
        return f"[llm_query: TIMEOUT after {timeout}s]"
    except Exception as e:  # pragma: no cover - environment dependent
        if usage_log:
            _record_leaf_usage(usage_log, model, None, ok=False, note=f"{type(e).__name__}")
        return f"[llm_query: ERROR {type(e).__name__}: {e}]"

    raw = (res.stdout or "").strip()
    if not usage_log:
        # Default path: byte-identical to the original (plain text, no JSON).
        if res.returncode != 0 and not raw:
            err = (res.stderr or "").strip()[:300]
            return f"[llm_query: ERROR rc={res.returncode}] {err}"
        return raw

    # Instrumented path: parse the JSON envelope, record usage, return result text.
    try:
        d = json.loads(raw)
    except Exception:
        _record_leaf_usage(usage_log, model, None, ok=False, note="jsonparse")
        if res.returncode != 0 and not raw:
            err = (res.stderr or "").strip()[:300]
            return f"[llm_query: ERROR rc={res.returncode}] {err}"
        return raw
    ok = not bool(d.get("is_error"))
    _record_leaf_usage(usage_log, model, d, ok=ok)
    out = (d.get("result") or "").strip()
    if not ok and not out:
        return f"[llm_query: ERROR is_error] {(d.get('result') or '')[:200]}"
    return out

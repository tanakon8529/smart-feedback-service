
### 7. High-Performance Optimizations
- **Task**: Switch to `uv` and `Granian`.
- **AI Contribution**:
    -   Replaced `pip` with `uv` in Dockerfile for ultra-fast dependency installation.
    -   Switched web server from `Uvicorn` to `Granian` (Rust-based) for higher throughput and lower latency.
    -   Updated `requirements.txt` and `Dockerfile` command accordingly.

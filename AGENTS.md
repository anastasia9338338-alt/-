# Verification before delivery

The user requires a code review and fixes before every delivered script revision.

- Run `python tools/verify.py --luau-dir /path/to/luau/tools` against the exact final `astral.lua` and `astral.zip` before committing or sharing a download.
- Review changed behavior and its callers, cancellation, respawn and unload paths. Run the relevant behavior harnesses as well as the repository regression checks.
- Inspect analyzer findings across executable modules and embedded gameplay. Roblox/executor globals and type-inference limits are not proof of runtime defects; investigate findings before changing behavior.
- Preserve existing features and names unless the user requests changes. Preserve notices.
- Do not claim that Roblox physics, server hits or successful kicks were tested when only CLI/mocked checks ran. Report the scope of verification honestly.
- Deliver the ready Lua in a ZIP with a verified commit-pinned download link. A raw Lua page opens as text in the user's client.

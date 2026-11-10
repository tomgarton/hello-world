# Design canvas sources

The live canvas is the claude.ai artifact "Family Baby Tracker Mockups":
https://claude.ai/artifact/7YuMrXnyazxos3Hnfr6uAd

This folder is a copy of what builds it, saved from the cloud session so the work is not lost.

- `project/` holds the boards as published: one `.dc.html` file per board, plus `canvas.json` (pages, positions, order).
- `gen/` holds the Python scripts that draw the boards as SVG and write them into `project/`.

## Running a generator

Each script takes the folder that contains `gen/` and `project/`:

```
cd design/canvas/gen
python3 scenes3.py ..        # rebuilds project/Scenes2.dc.html
```

Most scripts load earlier ones, so keep them together. The chain for the current work is:

`world.py`, `builder.py`, `platy.py` → `express.py` (Puggle's face, poses, small versions) → `lineup.py` (the cast) → `style.py` (activity icons) → `scenes.py`, `scenes2.py` → `night2.py` → `three.py` (app scenes) → `scenes3.py` (twelve scenes, kit) → `wallbooks.py`, `refs.py`. `puggle3.py` is the three proposed additions.

Things to know:

- Scripts written early in the project reset a board's position and page in `canvas.json` when they run. Copy `canvas.json` first and restore the entry afterwards.
- Each script also writes a plain `.html` preview into `gen/`; `shot39.js` (Playwright) shows how previews were screenshotted for checking.
- `iconsys3.py` needs the Lucide and Phosphor icon packages, which are not in this repo. It is superseded by `style.py`.
- After changing a board file, publish it to the artifact from a Claude session that has the artifacts tools.

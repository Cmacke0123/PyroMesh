
import sys
import glob
import argparse
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
from matplotlib.animation import FuncAnimation, PillowWriter


def load_fire(filename):
    data = np.loadtxt(filename)

    i = data[:, 0].astype(int)
    j = data[:, 1].astype(int)
    T = data[:, 2]
    fuel = data[:, 3]
    state = data[:, 4]

    nx = i.max()
    ny = j.max()

    temperature = np.zeros((nx, ny))
    fuel_grid = np.zeros((nx, ny))
    state_grid = np.zeros((nx, ny))

    # Vectorized scatter instead of a per-point Python loop.
    temperature[i - 1, j - 1] = T
    fuel_grid[i - 1, j - 1] = fuel
    state_grid[i - 1, j - 1] = state

    return temperature, fuel_grid, state_grid


def step_from_filename(path):
    stem = Path(path).stem  # "fire_0090"
    digits = "".join(ch for ch in stem if ch.isdigit())
    return int(digits) if digits else 0


def build_animation(files, out_path, fps=6, dpi=110):
    files = sorted(files, key=step_from_filename)
    if not files:
        raise SystemExit("No input files matched.")

    print(f"Loading {len(files)} timesteps...")
    frames = [load_fire(f) for f in files]
    steps = [step_from_filename(f) for f in files]

    T0, fuel0, state0 = frames[0]
    Tmax_global = max(T.max() for T, _, _ in frames)
    Tmin_global = min(T.min() for T, _, _ in frames)

    # State: 0=unburned, 1=burning, 2=burned -> discrete color map
    state_cmap = mcolors.ListedColormap(["#2e7d32", "#ff6f00", "#212121"])
    state_norm = mcolors.BoundaryNorm([-0.5, 0.5, 1.5, 2.5], state_cmap.N)

    fig, (ax_t, ax_s) = plt.subplots(1, 2, figsize=(12, 5.5))

    im_t = ax_t.imshow(
        T0.T, origin="lower", cmap="hot",
        vmin=Tmin_global, vmax=Tmax_global,
    )
    cb_t = plt.colorbar(im_t, ax=ax_t, label="Temperature (K)", fraction=0.046, pad=0.04)
    ax_t.set_xlabel("x cell")
    ax_t.set_ylabel("y cell")
    title_t = ax_t.set_title("")

    im_s = ax_s.imshow(
        state0.T, origin="lower", cmap=state_cmap, norm=state_norm,
    )
    cb_s = plt.colorbar(im_s, ax=ax_s, ticks=[0, 1, 2], fraction=0.046, pad=0.04)
    cb_s.ax.set_yticklabels(["unburned", "burning", "burned"])
    ax_s.set_xlabel("x cell")
    ax_s.set_ylabel("y cell")
    title_s = ax_s.set_title("")

    fig.suptitle("PyroMesh fire spread", fontsize=13)
    plt.tight_layout(rect=[0, 0, 1, 0.95])

    def update(frame_idx):
        T, fuel, state = frames[frame_idx]
        step = steps[frame_idx]

        im_t.set_data(T.T)
        title_t.set_text(f"Temperature — step {step}")

        im_s.set_data(state.T)
        title_s.set_text(f"State — step {step}")

        return im_t, im_s, title_t, title_s

    anim = FuncAnimation(fig, update, frames=len(frames), blit=False)

    out_path = Path(out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    print(f"Writing {out_path} ({len(frames)} frames @ {fps} fps)...")
    anim.save(out_path, writer=PillowWriter(fps=fps), dpi=dpi)
    plt.close(fig)
    print("Saved:", out_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="+", help="fire_NNNN.dat files (glob-expanded already or a pattern)")
    parser.add_argument("--out", default="plots/fire_animation.gif", help="output animation path (.gif)")
    parser.add_argument("--fps", type=int, default=6)
    parser.add_argument("--dpi", type=int, default=110)
    args = parser.parse_args()

    # allow passing a raw glob pattern too (in case shell didn't expand it)
    expanded = []
    for f in args.files:
        matches = glob.glob(f)
        expanded.extend(matches if matches else [f])

    build_animation(expanded, args.out, fps=args.fps, dpi=args.dpi)
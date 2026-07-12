import numpy as np
import matplotlib.pyplot as plt
import sys
import os


def load_fire(filename):

    data = np.loadtxt(filename)

    i = data[:,0].astype(int)
    j = data[:,1].astype(int)

    T = data[:,2]
    fuel = data[:,3]
    state = data[:,4]

    nx = i.max()
    ny = j.max()

    temperature = np.zeros((nx, ny))
    fuel_grid = np.zeros((nx, ny))
    state_grid = np.zeros((nx, ny))

    for k in range(len(i)):
        temperature[i[k]-1, j[k]-1] = T[k]
        fuel_grid[i[k]-1, j[k]-1] = fuel[k]
        state_grid[i[k]-1, j[k]-1] = state[k]

    return temperature, fuel_grid, state_grid


if __name__ == "__main__":

    if len(sys.argv) < 2:
        print("Usage: python plot_fire.py fire_0030.dat")
        sys.exit()

    filename = sys.argv[1]

    T, fuel, state = load_fire(filename)

    fig, ax = plt.subplots(figsize=(7,6))

    im = ax.imshow(
        T.T,
        origin="lower",
        cmap="hot"
    )

    plt.colorbar(im, ax=ax, label="Temperature (K)")

    ax.set_title(filename)
    ax.set_xlabel("x cell")
    ax.set_ylabel("y cell")

    plt.tight_layout()

    from pathlib import Path

    output_dir = Path("plots")
    output_dir.mkdir(exist_ok=True)

    output_file = output_dir / (Path(filename).stem + ".png")

    plt.savefig(output_file, dpi=300)

    print("Saved:", output_file)
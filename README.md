# RC Eccentric Section Capacity

MATLAB programs for ultimate capacity analysis of eccentrically loaded RC members (rectangular & circular-ring sections)

## Overview

`main.m` is a MATLAB script for estimating the ultimate load capacity of reinforced-concrete sections under combined axial load and bending.

In practical terms, it helps users study how much force and moment a section can carry before reaching its capacity limit. The script supports two section types:

- Rectangular sections
- Annular sections

The workflow is interactive. The script:

- prompts for material, geometry, and reinforcement inputs in the console
- computes section response using section discretization and numerical summation
- plots a `Nu-Mu Interaction Curve`
- writes computed results to text files in the current working directory

## Use

This repository is useful for:

- estimating the ultimate axial force-moment (`Nu-Mu`) response of selected reinforced-concrete sections
- comparing how section size, material grade, and reinforcement layout influence section capacity
- producing plots and text outputs that can support review, study, or checking against hand calculations

It is a focused analysis script rather than a complete design or code-checking tool.

## File Layout

- `main.m`: the only source file in the repository. It contains the top-level interactive script and three local functions:
  - `ConstiRelationConcrete`
  - `ConstiRelationSteel`
  - `FEAmn`

## Runtime Requirements

- The script is intended for MATLAB.
- It is likely compatible with GNU Octave, but that has not been validated in this environment.
- The script is interactive and expects terminal or console input.
- The script opens a figure window and writes output files into the current working directory.

## How To Run

Run from the repository root so the generated output files are written beside `main.m`.

MATLAB:

```bash
matlab -batch "run('main.m')"
```

GNU Octave:

```bash
octave main.m
```

Interactive prompts will appear during execution. You will need to enter the material, section, and reinforcement values manually.

## Inputs

### Material Inputs

| Prompt meaning | Variable | Expected input |
| --- | --- | --- |
| Concrete strength grade | `fcuk` | Enter as `C` grade number, for example `30` for `C30` |
| Reinforcing steel grade | `steel` | Enter as `335`, `400`, or `500` for `HRB335`, `HRB400`, or `HRB500` |

The script validates the concrete strength grade and reinforcing steel grade before proceeding.

### Section Type

| Choice | Meaning |
| --- | --- |
| `1` | Rectangular section |
| `2` | Annular section |

### Rectangular Section Inputs

If `shape = 1`, the script requests:

| Variable | Meaning | Unit |
| --- | --- | --- |
| `h` | Rectangular height | mm |
| `b` | Rectangular width | mm |
| `c` | Concrete cover thickness | mm |
| `d` | Bar diameter | mm |
| `NumS` | Number of reinforcing bars | count |
| `dv` | Stirrup diameter | mm |
| `number` | Number of strip divisions | count |

The reinforcement must satisfy the script's spacing/layout check before execution continues.

### Annular Section Inputs

If `shape = 2`, the script requests:

| Variable | Meaning | Unit |
| --- | --- | --- |
| `Rb` | Outer annulus radius | mm |
| `Ra` | Inner annulus radius | mm |
| `c` | Concrete cover thickness | mm |
| `d` | Bar diameter | mm |
| `dv` | Stirrup diameter | mm |
| `NumS` | Number of reinforcing bars | count |
| `number` | Number of strip divisions | count |

The script checks whether the reinforcement can be arranged within the annular wall thickness before execution continues.

## Outputs

During execution, the script produces:

- on-screen prompts and validation messages
- a plotted `Nu-Mu Interaction Curve`
- three text output files

Generated files:

- `result.txt`: all computed `(Mu, Nu)` pairs
- `resultA.txt`: the subset with `N < Nb`
- `resultB.txt`: the subset with `N > Nb`

These files are overwritten on each run.

## Calculation Flow

At a high level, `main.m` performs the following steps:

1. Reads the concrete strength grade `fcuk` and derives concrete design parameters such as `fck`, `fc`, and `Ec`.
2. Reads the reinforcing steel grade and maps it to the corresponding yield strength.
3. Prompts for section geometry and reinforcement data for either the rectangular or annular case.
4. Discretizes the concrete section into strips or elements and stores concrete and steel element locations and areas.
5. Evaluates two constitutive relationships:
   - one for concrete
   - one for reinforcing steel
6. Sweeps through strain states covering:
   - the case where steel reaches ultimate tensile strain first
   - the case where concrete reaches ultimate compressive strain
   - the full-section tension case
7. Calls `FEAmn` to assemble bending moment `Mu` and axial force `Nu` from the concrete and steel contributions.
8. Sorts the results and splits them around the limiting axial force `Nb`.
9. Plots the interaction curve and writes the result tables to text files.

The implementation is descriptive and procedural rather than packaged as a reusable analysis API.

## Local Functions

### `ConstiRelationConcrete(StrainCi)`

Returns the concrete stress based on the piecewise constitutive law implemented in the script. The function uses the current concrete strength grade and derived concrete parameters to determine the stress response over the supported strain range.

### `ConstiRelationSteel(StrainSi)`

Returns the steel stress from the input strain and applies yield capping in both tension and compression according to the selected reinforcing steel grade.

### `FEAmn(k)`

Computes the section axial force and bending moment by summing the concrete and steel element contributions for a given curvature `k`. The function converts the final results to `kN` and `kN*m`.

## Notes And Limitations

- The script is interactive and is not parameterized as a reusable function.
- The implementation relies on global variables shared between the main script and local functions.
- The reinforcement layouts are assumed to be symmetric according to the logic encoded in the script.
- No automated tests or sample input set are present in the repository.
- Octave compatibility is unverified.
- The repository name does not match the script's structural engineering purpose.

## Suggested Usage

- Start with a moderate strip count so the computation remains manageable while still giving a useful interaction curve.
- Verify that all dimensions are entered in millimeters and that strength grades match the prompt format.
- Inspect `result.txt`, `resultA.txt`, and `resultB.txt` after each run to confirm the generated values and split behavior.

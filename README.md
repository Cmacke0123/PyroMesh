# PyroMesh

## Author(s): Connor MacKenzie

#### Welcome to ***PyroMesh*** - a collaborative project set out to understand and predict wildfire behavior more accurately using physics and forestry informed algorithms. Inspiration for this project derives from a career in plasma physics were computational modelling is heavily used. Within this field, a industry standard for computer modelling of plasmas is known as Particle-in-Cell (PIC) simulations where space is discretized into a grid, and bunches of particles called "macro-particles" are pushed each time step based on the velocities of the macro-particles and the electromagnetic fields present. 


#### The research goal here is to develop a physics informed wildfire spread model capable of predicting fire arrival time and burn patterns using a hybrid Eulerian-Lagrangian (PIC-inspired) framework. 

#### Consider a potential 2D space-discretized grid where each cell has: 
```
Fuel
Moisture
Burn Fraction
Wind
Elevation (& Gradient)
```

#### Then introduce particle-like structures such as: 
```
Embers
Packets of heat
Burning debris
```

#### Each time-step

1. Solve temperature on the grid
2. Consume fuel
3. Release ember particles
4. Move embers based on wind, convection, etc
5. Deposit energy where embers land
6. Ignite cells if ignition criteria is met


#### Data Structures
```
fuel[x,y]
temp[x,y]
moist[x,y]
wind_x[x,y]
wind_y[x,y]
elevation[x,y]
gradient[x,y]
state[x,y]
```

#### Particle like structures store
```
x
y
vx
vy
mass
temp
lifetime
```

####  Physics involved
1. Heat transfer -> conduction, convection, radiation
2. Fuel -> density, species, combustion rate
3. Moisture -> burn delay
4. Wind -> flame tilt, increase convection, transports embers 
5. Terrain -> landscape gradients causing fire to transport faster uphill 


#### What has not been done yet in this space? 

A novel direction could be to developa physics informed particle wildfire model in which:
1. The landscape is represented on a Eulerian grid
2. Embers are treated as Lagrangian particles
3. heat and fuel remain grid-based
4. ignition is governed by thermodynamics criteria 
wind fields come from weather models or simplified flow models

### Algorithm
#### State Variables:
```
============================
| State Variables| Meaning |
|:---------------|:--------|
|      Fuel      | kg/m^2  |
|      Temp      |      K  |     
|  Moisture      |    0-1  |     
|  Burn Fraction |    0-1  |
|  Wind          |    u,v  |
|  State         |Unburned,burning,burned|
|   Elevation    |      m  | 
============================

```

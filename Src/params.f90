module params
    implicit none

    integer, parameter :: nx = 200
    integer, parameter :: ny = 200
    integer, parameter :: nt = 

    real(8), parameter :: dx = 5.0
    real(8), parameter :: dt = 0.01
    
    real(8), parameter :: alpha = 5.0
    real(8), parameter :: ignition_T = 600.0
    real(8), parameter :: fuel_rate  = 0.5
    real(8), parameter :: heat_release = 900.0
    real(8), parameter :: flame_heat = 500.0
    
    real(8), parameter :: ambient_temperature = 300.0
    real(8), parameter :: cooling_rate = 5.0

    ! Wind: uniform initial value the grid gets seeded with (grid.f90
    ! stores it as a full wind_x(:,:)/wind_y(:,:) field so it can be made
    ! spatially varying later, e.g. terrain channeling). Units are m/s,
    ! consistent with dx in m and dt in s.
    real(8), parameter :: wind_speed_x = 3.0
    real(8), parameter :: wind_speed_y = 0.0

    ! Flame tilt: how strongly deposit_heat leans the heat it gives
    ! neighboring cells toward the downwind side. 0 = symmetric (no wind
    ! effect on deposit), larger = more lopsided. Keep this well under
    ! 1/max(|wind_speed_x|,|wind_speed_y|) or the upwind-side deposit
    ! term below can go negative before being clamped.
    real(8), parameter :: flame_tilt = 0.15
    
end module params



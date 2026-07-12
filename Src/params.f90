module params
    implicit none

    integer, parameter :: nx = 200
    integer, parameter :: ny = 200
    integer, parameter :: nt = 500

    real(8), parameter :: dx = 5.0
    real(8), parameter :: dy = 0.1
    real(8), parameter :: dt = 0.01
    
    real(8), parameter :: alpha = 5.0
    real(8), parameter :: ignition_T = 600.0
    real(8), parameter :: fuel_rate  = 0.02
    real(8), parameter :: heat_release = 1.0
    real(8), parameter :: flame_heat = 50.0
    
end module params



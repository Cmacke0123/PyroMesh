
program wildfire

  use params
  use grid
  use physics
  use io

  implicit none

  integer :: timestep

  call init_grid()

  do timestep = 1, nt

    call step_temperature()
    call ignite_cells()
    call burn_cells()
    call deposit_heat()
    

    if (mod(timestep,10) == 0) then
      call write_output(timestep)
    end if

    if (mod(timestep,50)==0) then

    print *, "-----------------------------"
    print *, "Step:", timestep
    print *, "Cells above ignition:", count(temperature > ignition_T)
    print *, "Burning cells:", count(state == 1)
    print *, "Burned cells :", count(state == 2)
    print *, "Max T        :", maxval(temperature)
    print *, "Fuel         :", sum(fuel)

    end if

  end do

  

end program wildfire
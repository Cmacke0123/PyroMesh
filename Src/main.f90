
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
    call combustion()

    if (mod(timestep,10) == 0) then
      call write_output(timestep)
    end if

    if (mod(timestep,50)==0) then
    print *, "Step:", timestep, &
             " Max T:", maxval(temperature), &
             " Fuel:", sum(fuel)
    end if

  end do

  

end program wildfire